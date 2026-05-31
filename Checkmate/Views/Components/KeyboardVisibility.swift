import SwiftUI
import Combine
import UIKit

/// Tracks software keyboard visibility for add-todo chrome.
struct KeyboardVisibilityModifier: ViewModifier {
    @Binding var isVisible: Bool

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(Theme.snappy) { isVisible = true }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(Theme.snappy) { isVisible = false }
            }
    }
}

extension View {
    func tracksKeyboardVisibility(_ isVisible: Binding<Bool>) -> some View {
        modifier(KeyboardVisibilityModifier(isVisible: isVisible))
    }
}

enum KeyboardDismiss {
    static func resign() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Tap outside to dismiss keyboard

/// Window-level tap that resigns first responder without stealing button hits.
private struct KeyboardDismissOnTap: UIViewRepresentable {
    var onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> HostView {
        let view = HostView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: HostView, context: Context) {
        context.coordinator.onTap = onTap
        uiView.coordinator = context.coordinator
        uiView.attachIfNeeded()
    }

    static func dismantleUIView(_ uiView: HostView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class HostView: UIView {
        weak var coordinator: Coordinator?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            attachIfNeeded()
        }

        func attachIfNeeded() {
            guard let window, let coordinator else { return }
            coordinator.installIfNeeded(on: window)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTap: () -> Void
        private weak var tapRecognizer: UITapGestureRecognizer?

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        func installIfNeeded(on window: UIWindow) {
            guard tapRecognizer == nil else { return }
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            tapRecognizer = tap
        }

        func detach() {
            if let tapRecognizer, let view = tapRecognizer.view {
                view.removeGestureRecognizer(tapRecognizer)
            }
            tapRecognizer = nil
        }

        @objc private func handleTap() {
            onTap()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let view = touch.view else { return false }
            if view is UITextView || view is UITextField { return false }
            if view.closest(UITextView.self) != nil || view.closest(UITextField.self) != nil { return false }
            return true
        }
    }
}

private extension UIView {
    func closest<T: UIView>(_ type: T.Type) -> T? {
        var node: UIView? = self
        while let current = node {
            if let match = current as? T { return match }
            node = current.superview
        }
        return nil
    }
}

extension View {
    func dismissKeyboardOnTap(_ action: @escaping () -> Void) -> some View {
        background(KeyboardDismissOnTap(onTap: action))
    }
}
