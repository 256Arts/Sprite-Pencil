# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Sprite Pencil is a native iOS/iPadOS/macCatalyst pixel-art editor written in Swift/SwiftUI. The Xcode project (`Sprite Pencil.xcodeproj`) builds three targets:

- **Sprite Pencil** (`com.jaydenirwin.spritepencil`) — the main document-based app (`iOS/`).
- **Sprite Pencil Messages** (`com.jaydenirwin.spritepencil.messages`) — an iMessage app extension (`Messages/`).
- **SpriteWidgetExtension** (`com.jaydenirwin.spritepencil.SpriteWidget`) — a WidgetKit widget (`Widget/`).

The three targets share the app group `group.com.jaydenirwin.spritepencil` (see `SpritePencilApp.spritePencilAppGroupID`), which is how sprites are handed between the app, the Messages extension, and external apps (via the `Import.png` / `importSpriteName` keys in the group's `UserDefaults`).

## Building

Open `Sprite Pencil.xcodeproj` in Xcode and build/run via the **Sprite Pencil** scheme (or **Sprite Pencil Messages** for the iMessage extension). There is no command-line build script, package manifest, or test suite in this repo — building is Xcode-only.

Swift Package dependencies are resolved automatically by Xcode (`Sprite Pencil.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`). If resolution gets stuck, use File ▸ Packages ▸ Reset Package Caches in Xcode.

## Architecture

### SpritePencilKit is the engine; this repo is the UI

The entire drawing engine lives in an **external Swift package, `SpritePencilKit`** (`https://github.com/256Arts/SpritePencilKit`). This repo contains only the app shells, SwiftUI UI, and app-specific models. Almost every core type is imported from the kit, including:

- `DocumentController` — the central object that owns the `CGContext` being drawn into, the current tool, color, symmetry settings, and undo. All editing operations (`flip`, `rotate`, `outline`, `getColorComponents(at:)`, etc.) go through it.
- `CanvasUIView` / `ZoomableUIView` — the UIKit drawing surface and its zoom wrapper.
- `ZoomableCanvasView` — the SwiftUI wrapper around the canvas (its `configure:` closure is where the app wires `DocumentController` to the views and seeds the drawing context).
- Tools: `PencilTool`, `EraserTool`, `FillTool`, `HighlightTool`, `ShadowTool`, plus move/eyedropper tools (held as properties on `DocumentController`).
- Primitives: `Palette`, `ColorComponents`, `PixelPoint`, `PixelSize`, `ContextDataManager`.

When something looks undefined in this repo, it almost certainly comes from `SpritePencilKit`. Changes to drawing behavior may require changes upstream in that package, not here.

**We own `SpritePencilKit` too** (`github.com/256Arts/SpritePencilKit`) — don't hesitate to edit it when the right fix lives there rather than working around it app-side. Xcode resolves it as a remote SwiftPM dependency, so to make changes locally either point the project at a local checkout (drag the package folder into the project / `File ▸ Add Package Dependencies ▸ Add Local…`) or edit and push the package and bump the pin in `Package.resolved`.

### Editor data flow (`iOS/Editor/EditorView.swift`)

`EditorView` is the heart of the main app and the best file to read first. The pattern:

1. The document is a SwiftUI `FileDocument` (`SpriteImageDocument`) holding raw PNG `Data` — there is no custom file format; sprites are plain PNG/JPEG files managed by `DocumentGroup` / the system document browser.
2. On appear, `EditorView` decodes `document.data` into a `CGContext` and hands that context to `documentController`.
3. The user draws via the kit's `CanvasUIView`, mutating the context in place.
4. On `.drawingDidChange` / `.didEndUsingTool` events, `refreshDocumentDataFromContext()` re-encodes the context to PNG and writes it back to `document.data` (inside a `Task` to avoid mutating during a view update).

Tool selection, brush width, dither (checkered) mode, symmetry, and palette/color are all driven from SwiftUI state and pushed imperatively onto `documentController` / `canvasRef`. The bottom bar (`ToolSelectionBar`, `ToolOptionsView`) and the trailing `inspector` (`PaletteCollectionView`) are the main controls.

### Palettes

`Palette` is a kit type extended app-side in `iOS/Models/Palette.swift`. Palettes come from three sources, combined in `Palette.allPalettes`:

- **User palettes** — PNG files in `Documents/Palettes/`, loaded at launch.
- **Handpicked palettes** — bundled image assets (PICO-8, Endesga 32, etc.) loaded in `SpritePencilApp.loadAppPalettes()`, which also seasonally injects extra palettes by calendar date.
- **Built-in special palettes** — `Palette.sp16`, `.rrggbb`, etc., defined in the kit.

A palette image encodes one color per pixel. Lospec palettes can be imported via the `lospec-palette://` URL scheme (`AppCoordinator.openLospecURL`).

### App entry & URL handling

`iOS/SpritePencilApp.swift` defines the `@main` `App`, two `DocumentGroup` scenes (one with a launch/template-picker scene for non-macOS, one plain), and `AppCoordinator`, which handles incoming URLs and `NSUserActivity`: custom `spritepencil://` schemes, App Store events, app-group sprite imports, and Lospec palette imports.

### Shared code

`Shared/` holds code compiled into multiple targets — notably `Shared/Editor/PaletteCollectionView.swift` (the SwiftUI palette grid + its `PaletteCollectionController`), used by both the main app's inspector and the Messages extension.

## Conventions

- **Swift 5, SwiftUI-first.** Newer code uses the Observation framework (`@Observable`) rather than `ObservableObject`. UIKit is used only where the kit requires it (the canvas).
- **`@AppStorage` + `UserDefaults.Key`** — user settings are string keys centralized in `iOS/Models/UserDefaults.swift`; read them via the `UserDefaults.Key.*` constants rather than raw strings.
- **Commented-out code is intentional history.** Several files (e.g. `AppCoordinator.importSpriteFromAppGroup`, the `eventPublisher` wiring in `EditorView.init`) carry commented blocks from an in-progress refactor away from the old `UIDocument`/`CanvasUIView`-owns-everything design toward the SwiftUI `DocumentGroup` + `ZoomableCanvasView` architecture. Don't assume they're dead; check the surrounding refactor intent before deleting.

## Backlog

If `REMINDERS.md` exists in the repo root, it is a personal backlog exported from the developer's Apple Reminders list — a source of candidate work, **not** a spec. It is gitignored and absent on fresh checkouts. Each `- [ ]` line is one task; indented lines are its notes. Many entries are terse shorthand meaningful only to the developer, so confirm intent before acting on a cryptic item.
