import SwiftUI
import UIKit

/// An invisible view that reports device shakes.
///
/// Shake-to-undo is a responder-chain feature: `motionEnded` is delivered to
/// the first responder, and UIKit's own shake alert only offers to undo what
/// the chain's undo manager knows about. While Autosave is off the editor
/// deliberately keeps the drawing's history in a private undo manager that the
/// chain can't see (that's what stops the file being written), so UIKit has
/// nothing to offer and a shake does nothing. Placing this view in the editor
/// claims first responder — nothing else in the editor wants it, the canvas
/// draws from touches — and hands the shake back to the app.
struct ShakeDetector: UIViewRepresentable {

    let onShake: () -> Void

    func makeUIView(context: Context) -> ShakeDetectingView {
        let view = ShakeDetectingView()
        view.onShake = onShake
        return view
    }

    func updateUIView(_ uiView: ShakeDetectingView, context: Context) {
        uiView.onShake = onShake
    }

    final class ShakeDetectingView: UIView {

        var onShake: (() -> Void)?

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            // Only claimed once, on insertion: anything the person actually
            // focuses later (a text field in a sheet) must be able to take it
            // away and keep it.
            if window != nil {
                becomeFirstResponder()
            }
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            guard motion == .motionShake else {
                super.motionEnded(motion, with: event)
                return
            }
            onShake?()
        }
    }
}
