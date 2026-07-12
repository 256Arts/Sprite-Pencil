# Architecture & Modernization Proposal

_Audit date: 2026-07-07. Covers this repo (~2.7k lines, 31 files) and SpritePencilKit 1.6.1 (~2.2k lines, 14 files, local checkout at `/Volumes/Kingston/GitHub/SpritePencilKit`, clean and matching the pin)._

## Summary

The codebase is small, actively maintained, and mid-way through two good migrations: UIDocument → `DocumentGroup` (app) and UIKit-owns-everything → SwiftUI-hosted canvas (kit). The audit's headline findings:

1. **The kit has real memory-safety bugs today** — out-of-bounds heap reads in `outline`/`highlight`/`shadow`, and a broken `Hashable` contract on `ColorComponents` (UB in every `Set`/`Dictionary` that holds one).
2. **Several shipped features are silently broken**: vertical flip is a no-op, `posterize()` draws into no context, app-group sprite import discards the data, Settings/Help are unreachable, image export is commented out, and Mac Catalyst cannot compile.
3. **The core architectural debt is one thing**: `DocumentController` and the UIKit views hold references into each other. Breaking that cycle unlocks testability, Swift 6, and any future renderer.
4. **Zero tests in either repo**, yet the riskiest code (flood fill, flip/rotate, trim, outline, hex parsing) is pure math — the cheapest possible test targets. Recent history (rotate clipping, trimCanvas OOB, redo guard) is exactly the regression class tests catch.

Proposed order: fix correctness (P1) → restore broken features (P2) → kit architecture (P3) → app architecture (P4) → tests/CI (P5) → Swift 6 + iOS 27 modernization (P6) → hygiene sweep (P7). P1+P2 are small diffs with immediate user value; P3 is the one structural investment; everything after rides on it.

---

## P1 — Correctness fixes (kit) · ship as SpritePencilKit 1.6.2

Small, surgical, no API changes.

1. **Out-of-bounds reads in `outline()`** — `DocumentController.swift:384-400` calls `getColorComponents(at:)` for each neighbor *before* the bounds check (`y+1`, `x+1` read past the buffer on the last row/column; `y-1`/`x-1` compute negative offsets at row/column 0). Hoist the bounds checks before the reads.
2. **Out-of-bounds reads in `highlight`/`shadow`** — `DocumentController.swift:260,272` read every cell of the brush footprint unguarded; brushing along the canvas edge reads outside the buffer (writes are guarded, reads are not). Clamp the loop ranges.
3. **`ColorComponents` Hashable contract violation** — `ColorComponents.swift:80-90`: `==` treats any two opacity-0 values as equal, but `hash(into:)` hashes the full RGB `id` string → equal values with unequal hashes = UB in `Set`/`Dictionary` (used by `currentOperationPixelPoints`, recent colors, palettes). Hash a canonical form (`opacity == 0 ? 0 : packed RGBA UInt32`) and derive `id` from that integer — also kills the per-pixel `String` allocation on the hot path.
4. **`ContextDataManager` capacity is wrong** — `ContextDataManager.swift:22` binds `width * height` but the buffer is `height * bytesPerRow` bytes (~4× larger + row padding). Fix the capacity; while there, add a debug-mode bounds assertion so this whole bug class (items 1–2, and the trimCanvas bug you already fixed in 1.5.x) becomes structurally impossible.
5. **`fatalError()` on `@unknown default` gesture state** — `CanvasUIView.swift:523-524` would crash shipping apps on a future UIKit gesture state. Use `break`.
6. **Context recreated without byte order** — `rotate`/`trimCanvas` (`DocumentController.swift:351,495`) pass `bitmapInfo: image.alphaInfo.rawValue`, dropping `byteOrder32Little`; if that ever diverges from the app-side format, every subsequent paint channel-swaps red/blue. Centralize context creation in one factory (the app's `SpriteDrawingContext.swift` shows the shape — consider moving it into the kit as the single source of truth) and build from the *live* context's `bitmapInfo | alphaInfo`.

## P2 — Restore broken features (app + kit)

Each of these is a user-visible gap; most are stranded ends of the DocumentGroup refactor and are small diffs because the SwiftUI replacements already exist.

1. **Mac Catalyst can't compile** — `DitherToggle.swift:18` and `RoundBrushToggle.swift:20` call `BottomToolbarView.largeSymbol(...)` (type no longer exists); `TemplatePickerBottomBar.swift:53,56` posts `TemplatePickerView.doneNotificationName` (no longer declared). All inside `#if targetEnvironment(macCatalyst)`, so iOS builds pass but `SUPPORTS_MACCATALYST = YES` is a lie. Replace the `largeSymbol` branches with `Image(systemName:).imageScale(.large)`, delete the notification buttons (the toolbar versions exist), delete `MacToolbarDelegate.swift` (protocol has zero conformers). Kit-side, the Catalyst branch at `CanvasUIView.swift:166` references a nonexistent `checkerboardView` — same disease, fix or delete.
2. **App-group sprite import is a no-op** — `SpritePencilApp.swift:37-66` computes the destination URL then hits the commented-out `UIDocument` save; the data is discarded while `spritepencil://importfromapp` and the universal link still advertise the feature. Complete the refactor: coordinated `imageData.write(to:)` with filename uniquification.
3. **Settings/Help unreachable** — nothing presents `SettingsView` (only reference is its own `#Preview`). Add a gear toolbar item in `EditorView` presenting it in a sheet; the dead `editorVC.…` calls (SettingsView.swift:89,97) are obsolete since `@AppStorage(canvasBackgroundColor)` now reacts automatically.
4. **Export/share commented out** — `ShareOptionsView.swift:20-44`. Root cause is `ShareLink` inside a `Menu` (a presentation within a presentation). Move export to a Share toolbar button → popover with the scale picker + `ShareLink`. Note `NSPhotoLibraryAddUsageDescription` currently describes a flow that no longer exists.
5. **Vertical flip is a no-op** — `DocumentController.swift:308-341`: the transform only concatenates `if !vertically`, so the vertical path redraws the image unchanged; the horizontal path carries a redundant identity "FIX (2/2)" redraw. Rewrite as two explicit scale+translate cases, delete both FIX passes.
6. **`posterize()` silently does nothing** — `DocumentController.swift:436` calls `newImage.draw(at:)` with no current UIKit graphics context (same bug class as the `move()` fix in cec50b2), and its undo handler shares the bug. Render the CIFilter output via `CIContext` into `self.context`, or gate the feature off.
7. **Palette changes never reach the engine** — `PaletteCollectionView.swift:140-142` updates only `PaletteCollectionController`; `documentController.palette` is seeded once in `EditorView.init:57` and never again, so Highlight/Shadow shade against the launch palette forever. Likely the root cause of the "Palette button in bottom toolbar doesn't update always" backlog item. Propagate on select.
8. **`fillDrawnPath()` is acknowledged-broken** — `DocumentController.swift:193-201`: unordered dictionary keys build the path ("ISSUE: points are not in order" in-code), and the undo closure strongly captures `self` alongside `target` (controller retained by its own undo stack). Keep an ordered `[PixelPoint]` alongside the dictionary, or gate the feature off until P3 lands.

## P3 — Kit architecture · ship as SpritePencilKit 2.0

The one structural investment. Everything in P5–P6 gets cheaper after this.

1. **Break the controller ↔ view cycle.** `DocumentController.swift:77-78` holds `weak ... ZoomableUIView!` / `CanvasUIView!` and mutates them directly (`refresh()` at :83-89, `move()` reads `canvasView.spriteCopy` at :222, `replaceContext` calls `zoomToFit()` at :506-519). Invert it: the controller exposes `@Observable` output (`renderedImage: CGImage`, canvas-size-changed events) and the views observe. This is what makes the controller unit-testable and unlocks a future Metal/SwiftUI-`Canvas` renderer. It's also the fix for the IUO-crash surface: `ZoomableCanvasView.makeUIView` builds fresh views each time, so any event against the stale weak IUO refs traps.
2. **Move stroke commit into the controller.** `CanvasUIView.swift:454-486` has three near-identical blocks where the *view* copies `currentOperationPixelPoints`, registers undo against the controller, and clears the dictionary. Replace with `documentController.commitCurrentOperation()` / `cancelCurrentOperation()`; make the stroke state `private` + `@ObservationIgnored` (it's currently `@Observable`-tracked and mutated once per painted pixel — pure observation overhead).
3. **One event bus.** `DocumentController.eventPublisher` + `CanvasUIView.events` + `@Observable` = three notification mechanisms the app must juggle. Route everything through one surface on the controller; delete `CanvasViewEvent`.
4. **One undo currency.** Today: pixel-diff replay + image-snapshot closures (two of which are broken, see P2.6/P2.8) + whole-context swap, with `CanvasUIView.doUndo/doRedo` manually poking `groupingLevel`. Converge on a `PixelDiff` value plus a `CanvasReplacement` value, registered in exactly one controller method; set `levelsOfUndo` (old multi-megapixel contexts are currently retained forever).
5. **Tools own their behavior.** Tool dispatch is `is`/`as` type-checks in three places (`CanvasUIView.swift:407-417, 435-487, 552-586`) while `Tool` structs are anemic markers. Continue the `SizableTool` direction: either behavior on the protocol (`apply(at:controller:)`, `commit`) or a single exhaustive `enum Tool` switch inside the controller. Delete the leftover per-type size switch at `CanvasUIView.swift:203-220` (`tool.size` already exists).
6. **Intentional API surface.** Nearly everything is `public var`, including `context: CGContext!` (settable), `contextDataManager`, stroke state, and both view back-refs. Move to `public private(set)` / internal + `loadContext(_:)`; make `ContextDataManager.dataPointer` private behind a bounds-checked subscript. Hoist `CanvasUIView.FingerAction` to a top-level `enum FingerAction: String, Codable, Sendable` so the app's settings model stops importing a UIKit view type.
7. **Kill the timing hacks.** `ZoomableUIView.swift:82-84,107-110,187-190` use 0.1 s sleeps to sequence layout/gestures. Drive initial fit from `layoutSubviews`/`bounds.didSet`, clear flags in scroll-delegate end callbacks. (Likely related to the "pinch-zoom max size shrinks" backlog item.)
8. **Honest platforms.** `Package.swift:9` declares `.macOS(.v13)` but four files import UIKit unguarded — native macOS can't build. Drop the platform (Catalyst doesn't need it) or guard the imports.

## P4 — App architecture

1. **`@MainActor @Observable PaletteStore`.** Kills three problems at once: `Palette.userPalettes/handpickedPalettes` global mutable statics (Swift 6 blockers, `iOS/Models/Palette.swift:14-16`), the non-observable static array behind `PalettePickerView`'s `userPaletteCount` refresh hack, and palette name collisions (two "My Palette" imports collide as `ForEach` IDs *and* overwrite each other's PNG). Uniquify filenames on save.
2. **Delete the `PalettePickerView` stub hack.** `PaletteCollectionView.swift:138-144` hard-references `PalettePickerView`, forcing `Messages/PalettePickerView.swift` ("DO NOT USE") to exist as a type shadow. Inject the chooser as a generic `Chooser: View` closure, or move the chooser sheet up into `EditorView`.
3. **Shared app-group constants.** Group ID re-hardcoded in `SpriteWidget.swift:47`; keys `"sprite"`, `"backgroundColor"`, `"importSpriteName"`, `"ownsSpritePencil"` are raw strings, violating this repo's own `UserDefaults.Key` convention. One `Shared/AppGroup.swift` in all three targets.
4. **Move `ColorComponents` serialization upstream.** Parsing (`init(hex:)`) is kit-side; formatting (`.hex`) and `Color`→components are app-side while the inverse is kit-side. You own the kit — reunite them there and delete `iOS/Models/ColorComponents.swift` (fix `%02lX` → `%02X` in passing). Same for `Palette.addPalette` (`iOS/Models/Palette.swift:25-42`): it still uses deprecated *device-RGB* `UIGraphicsBeginImageContext` — the exact mismatch `SpriteDrawingContext` fixed for the canvas, so saved palettes can round-trip with shifted colors. A kit-side `Palette.pngData()` built on the shared context factory removes the raw-pointer reach-in entirely.
5. **Harden the glue in `EditorView`:**
   - A. Template-picker continuation leaks on swipe-dismiss (`SpritePencilApp.swift:134-165`) — `.interactiveDismissDisabled()` or resume-with-cancel in `onDismiss`.
   - B. Undo wiring: assign `documentController.undoManager` on `.onChange(of: undoManager)` too (env manager can be nil/replaced under DocumentGroup); handle the `.refreshUndo` event so the Undo/Redo buttons' `canUndo` reads are deterministic instead of riding incidental re-renders (EditorView.swift:137-139, 226, 232-244).
   - C. Route all universal links through `handleIncoming(url:)` — `handleBrowsingWeb` currently sends everything to import, so App Store event links via user activity are dropped; switch on host in `handleCustomURL` instead of falling through to Lospec. Convert `openLospecURL` to async/await while there.
   - D. Collapse `pendingPalette` + `isSavePalettePresented` (EditorView.swift:41-42) into one `.popover(item:)` — two sources of truth for one presentation.
   - E. Isolate `hoverPoint` reads into a tiny `HoverReadout` child view — today every pointer/Pencil hover sample re-evaluates the entire `EditorView` body (EditorView.swift:280).
   - F. `MessagesView.swift:14-27` creates `DocumentController`/`PaletteCollectionController` as plain `let`s in `init` — make them `@State` so re-init can't silently reset the canvas.

## P5 — Tests + CI (both repos)

Highest leverage-per-hour in the whole proposal, and P1/P2 fixes should land with these as regression coverage.

1. **Kit: `SpritePencilKitTests` (Swift Testing), CGContext fixtures.** In value order: `BrushShape.includes` mask snapshots; flood fill / outline / trim pixel asserts (run under ASan — would have caught P1.1 mechanically); flip/rotate marked-corner-pixel asserts on square and non-square canvases (catches P2.5, and the 1.6.1 rotate bug was this exact class); `ColorComponents` hex round-trip + Equatable/Hashable contract; `Palette.highlight/shadow` ramp math.
2. **App: small Swift Testing target** for `CanvasBackground`/`FingerAction` raw-value stability (the exact risk NEEDS-QA.md is hand-verifying right now), Lospec JSON decoding, `SpriteSize`, `PaletteCollectionController.usedColor` ordering.
3. **CI:** one GitHub Actions workflow per repo running `xcodebuild test` on an iOS simulator destination — the simulator compile-check flow is already documented, so this is one step further.

## P6 — Modernization

1. **Swift 6, staged.** All targets are `SWIFT_VERSION = 5.0`. After P3/P4.1 (which remove the real blockers: view cycle, global statics), set `SWIFT_STRICT_CONCURRENCY = targeted`, fix stragglers (`SpriteSize.maxSize` → `let`, `SpriteWidgetConfiguration` statics → `let`, `@retroactive` on—or better, upstream—the `Palette: Identifiable` conformance), then flip to Swift 6 mode. The kit's `@MainActor @Observable DocumentController` already does the heavy lifting.
2. **iOS 27: `ReadableDocument`/`WritableDocument`.** The single biggest app-side simplification available: background reading/writing via `DocumentReader`/`DocumentWriter` replaces the hand-rolled main-actor PNG encode-coalescing (`EditorView.swift:46-51, 321-344`) — snapshot the context, encode off-main. One caution on the same SDK bump: `@State` becomes a macro in SDK 27, and `EditorView.init` (:53-62) reads `@State`/`@AppStorage` after assigning — exactly the flagged pattern. The right fix (per the migration guidance, not init reordering) is moving that seeding into `configure:`/`.onAppear`, which is better init hygiene anyway.
3. **iOS 27 UI wins:** `toolbarMinimizeBehavior` to shrink chrome while drawing; `visibilityPriority` so Flip/Rotate/Outline overflow gracefully in compact widths; `swipeActions` in the `PalettePickerView` LazyVStack for proper swipe-to-delete; `.reorderable()` for palettes/recent colors.
4. **String Catalogs.** en/ru/zh-Hans/en-GB `.strings` are missing every recent key ("Trim Canvas", "Set Widget Sprite", "Finger Action", "Canvas Background", "Round Brush", …); Messages and Widget targets ship no strings at all; `SpriteWidget.swift:71` does `Text("No Sprite Set".uppercased())` (breaks key lookup *and* localizes wrong — use `.textCase(.uppercase)`). Migrating to `.xcstrings` surfaces every gap automatically.
5. **Soft-deprecated API sweep** (~18 mechanical sites): `.foregroundColor`→`.foregroundStyle`, `.cornerRadius`→`.clipShape(.rect(cornerRadius:))`, `.edgesIgnoringSafeArea`→`.ignoresSafeArea`, `.navigationBarHidden`→`.toolbar(.hidden, for:)`, `.accentColor`→`.tint`, `Alert`→`.alert(isPresented:)`, `PreviewProvider`→`#Preview`.
6. **Accessibility pass:** `ColorCell` (shape + `.onTapGesture`) is invisible to VoiceOver — wrap in `Button` with the hex value as label; same for template-size cells and palette rows; `LabeledStepper` needs `.accessibilityAdjustableAction`.
7. **Widget target:** raise to match the app, `#Preview(as:)`, and capture the sprite data in the timeline `SpriteEntry` instead of reading app-group defaults at render time.

## P7 — Hygiene sweep (one cleanup PR)

1. Stale CocoaPods framework references in project.pbxproj (`Pods_Today.framework` et al. — no Podfile exists).
2. Project-level `IPHONEOS_DEPLOYMENT_TARGET = 17.0` vs target-level 26.0; `CLANG_CXX_LANGUAGE_STANDARD = gnu++14`.
3. Info.plist: empty `UTImportedTypeDeclarations`, `UIRequiredDeviceCapabilities: armv7`, stale `NSUserActivityTypes: ConfigurationIntent`.
4. Dead `UserDefaults.Key`s: `showPermanentEditWarning`, `showPalette` (never read); `autosave` in Settings.bundle (read nowhere); comment `createdDocumentsCountText` as Settings.bundle-display-only if that's its purpose.
5. Empty `Base.lproj` directories; kit-side commented template code (`Palette.swift:37-44,77-84`, `ZoomableUIView.swift:123-131`, Package.swift boilerplate).
6. Fold the double `onDisappear` (EditorView.swift:248 increments, SpritePencilApp.swift:187-191 reads — unspecified order) into one.
7. Kit perf niceties once P3 lands: diff the config in `ZoomableCanvasView.updateUIView` (currently rebuilds the checkerboard with a *fresh `CIContext`* on every SwiftUI update); batch `highlight`/`shadow` events (currently 2 Combine events per pixel); extract the 4× copy-pasted symmetry block in `brushPaint`.

---

## Backlog cross-references

Audit findings that likely explain open REMINDERS.md items:

- A. "Palette button in bottom toolbar doesn't update always" → P2.7 (palette never propagates to the engine) + P4.1 (non-observable static palette arrays).
- B. "Pinch-zoom max size no longer fits" → P3.7 (timing-hack zoom state machine).
- C. "Color palette stops working in split screen … multiple UIGraphicsGetCurrentContext()'s" → P2.6/P1.6 territory (implicit-current-context drawing; the fix is the same: draw into explicit contexts only).
- D. "Add option to confirm edits on closing document" and "prompt rename upon exiting new sprite" → become natural once P6.2's document API migration lands.

## Sequencing & versioning

- P1 → kit 1.6.2 (patch, bump the pin here).
- P2 → kit 1.6.3 + app changes landing together.
- P3 → kit 2.0 (breaking API surface) + the app-side adoption PR.
- P5 kit tests should land *with* P1/P2 fixes, not after.
- P6.2's iOS 27 bump is independent of the kit work and can proceed in parallel once Xcode 27 is the baseline.
