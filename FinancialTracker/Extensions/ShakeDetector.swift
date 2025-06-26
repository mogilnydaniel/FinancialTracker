import SwiftUI
import UIKit

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

struct ShakeDetector: UIViewRepresentable {
    typealias UIViewType = UIView
    func makeUIView(context: Context) -> UIView {
        ShakeView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
    
    private class ShakeView: UIView {
        override var canBecomeFirstResponder: Bool { true }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            DispatchQueue.main.async {
                self.becomeFirstResponder()
            }
            NotificationCenter.default.addObserver(self, selector: #selector(self.resetResponder), name: UIResponder.keyboardDidHideNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.resetResponder), name: UIResponder.keyboardWillHideNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.resetResponder), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                NotificationCenter.default.post(name: .deviceDidShake, object: nil)
                DispatchQueue.main.async {
                    self.becomeFirstResponder()
                }
            }
            super.motionEnded(motion, with: event)
        }

        @objc private func resetResponder() {
            DispatchQueue.main.async {
                self.becomeFirstResponder()
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
} 