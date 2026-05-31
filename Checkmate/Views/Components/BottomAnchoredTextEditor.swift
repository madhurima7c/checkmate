import SwiftUI
import UIKit

/// Text input anchored to the bottom-left of a sticky note (Figma add-todo editor).
struct BottomAnchoredTextEditor: View {
    @Binding var text: String
    var placeholder: String = "Tap to write"
    var placeholderIcon: String? = nil
    var resetToken: Int = 0
    var dismissToken: Int = 0
    var onWritingActiveChanged: ((Bool) -> Void)?

    @State private var isActive = false
    @State private var focusRequest = 0

    /// Matches `StickyNoteCardView` text inset, lifted slightly from the bottom.
    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 22

    private var showPlaceholder: Bool {
        text.isEmpty && !isActive
    }

    var body: some View {
        ZStack {
            BottomAnchoredTextViewRepresentable(
                text: $text,
                focusRequest: focusRequest,
                resetToken: resetToken,
                dismissToken: dismissToken,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                onWritingActiveChanged: { active in
                    isActive = active
                    onWritingActiveChanged?(active)
                }
            )

            if showPlaceholder {
                placeholderButton
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: resetToken) { _, _ in
            isActive = false
            focusRequest = 0
            onWritingActiveChanged?(false)
        }
        .onChange(of: dismissToken) { _, _ in
            isActive = text.isEmpty ? false : true
            onWritingActiveChanged?(false)
        }
    }

    private var placeholderButton: some View {
        Button(action: startWriting) {
            HStack(spacing: 4) {
                if let placeholderIcon {
                    FigmaIcon(name: placeholderIcon, size: 15)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                }
                Text(placeholder)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(Theme.Palette.strike)
        }
        .buttonStyle(.plain)
    }

    private func startWriting() {
        isActive = true
        focusRequest += 1
        onWritingActiveChanged?(true)
    }
}

private struct BottomAnchoredTextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    let focusRequest: Int
    let resetToken: Int
    let dismissToken: Int
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    var onWritingActiveChanged: (Bool) -> Void

    func makeUIView(context: Context) -> BottomAnchoredTextView {
        let view = BottomAnchoredTextView()
        view.backgroundColor = .clear
        view.font = .systemFont(ofSize: 15, weight: .medium)
        view.textColor = UIColor(Theme.Palette.body)
        view.textAlignment = .left
        view.isScrollEnabled = true
        view.isEditable = true
        view.isSelectable = true
        view.keyboardDismissMode = .interactive
        view.textContainer.lineFragmentPadding = 0
        view.textContainerInset = .zero
        view.textContainer.widthTracksTextView = true
        view.delegate = context.coordinator
        context.coordinator.textView = view
        DispatchQueue.main.async {
            context.coordinator.applyBottomAnchor(to: view)
        }
        return view
    }

    func updateUIView(_ uiView: BottomAnchoredTextView, context: Context) {
        context.coordinator.textBinding = $text
        context.coordinator.horizontalPadding = horizontalPadding
        context.coordinator.verticalPadding = verticalPadding
        context.coordinator.onWritingActiveChanged = onWritingActiveChanged

        if context.coordinator.handledResetToken != resetToken {
            context.coordinator.handledResetToken = resetToken
            context.coordinator.handledDismissToken = dismissToken
            context.coordinator.handledFocusRequest = focusRequest
            uiView.text = text
            uiView.resignFirstResponder()
            onWritingActiveChanged(false)
            context.coordinator.applyBottomAnchor(to: uiView)
            return
        }

        if context.coordinator.handledDismissToken != dismissToken {
            context.coordinator.handledDismissToken = dismissToken
            uiView.resignFirstResponder()
            onWritingActiveChanged(false)
            context.coordinator.applyBottomAnchor(to: uiView)
        }

        if !uiView.isFirstResponder, uiView.text != text {
            uiView.text = text
            context.coordinator.applyBottomAnchor(to: uiView)
        }

        if focusRequest > 0, context.coordinator.handledFocusRequest != focusRequest {
            context.coordinator.handledFocusRequest = focusRequest
            context.coordinator.focusTextView(uiView)
        }

        context.coordinator.applyBottomAnchor(to: uiView)
    }

    static func dismantleUIView(_ uiView: BottomAnchoredTextView, coordinator: Coordinator) {
        uiView.resignFirstResponder()
        coordinator.textView = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var textBinding: Binding<String>?
        var horizontalPadding: CGFloat = 14
        var verticalPadding: CGFloat = 14
        var onWritingActiveChanged: ((Bool) -> Void)?
        weak var textView: BottomAnchoredTextView?
        var handledFocusRequest = 0
        var handledResetToken = -1
        var handledDismissToken = -1
        private var isApplyingAnchor = false
        private var lastAppliedInsets = UIEdgeInsets(top: -1, left: -1, bottom: -1, right: -1)

        func applyBottomAnchor(to textView: UITextView) {
            guard !isApplyingAnchor else { return }
            guard textView.bounds.width > 1, textView.bounds.height > 1 else { return }
            isApplyingAnchor = true
            defer { isApplyingAnchor = false }

            let lineHeight = textView.font?.lineHeight ?? 20
            let usableWidth = textView.bounds.width
                - horizontalPadding * 2
                - textView.textContainer.lineFragmentPadding * 2

            let contentHeight: CGFloat
            if textView.text.isEmpty {
                contentHeight = lineHeight
            } else {
                let measured = textView.layoutManager.usedRect(for: textView.textContainer).height
                contentHeight = max(ceil(measured), lineHeight)
            }

            let anchoredHeight = min(contentHeight, lineHeight * 2)
            let topInset = max(
                verticalPadding,
                textView.bounds.height - anchoredHeight - verticalPadding
            )
            let newInsets = UIEdgeInsets(
                top: topInset,
                left: horizontalPadding,
                bottom: verticalPadding,
                right: horizontalPadding
            )
            if !insetsAreEqual(lastAppliedInsets, newInsets) {
                textView.textContainerInset = newInsets
                lastAppliedInsets = newInsets
            }

            if !textView.text.isEmpty {
                let targetY = max(
                    0,
                    textView.contentSize.height - textView.bounds.height + textView.adjustedContentInset.bottom
                )
                if abs(textView.contentOffset.y - targetY) > 0.5 {
                    textView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
                }
            } else if textView.contentOffset != .zero {
                textView.setContentOffset(.zero, animated: false)
            }
        }

        private func insetsAreEqual(_ lhs: UIEdgeInsets, _ rhs: UIEdgeInsets) -> Bool {
            abs(lhs.top - rhs.top) < 0.5
                && abs(lhs.left - rhs.left) < 0.5
                && abs(lhs.bottom - rhs.bottom) < 0.5
                && abs(lhs.right - rhs.right) < 0.5
        }

        func focusTextView(_ textView: UITextView) {
            applyBottomAnchor(to: textView)
            if !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }
            placeCaretForTyping(in: textView)
        }

        func placeCaretForTyping(in textView: UITextView) {
            applyBottomAnchor(to: textView)
            let end = (textView.text as NSString).length
            textView.selectedRange = NSRange(location: end, length: 0)
            if textView.text.isEmpty {
                textView.setContentOffset(.zero, animated: false)
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            textBinding?.wrappedValue = textView.text
            applyBottomAnchor(to: textView)
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            onWritingActiveChanged?(true)
            placeCaretForTyping(in: textView)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            onWritingActiveChanged?(!textView.text.isEmpty)
            applyBottomAnchor(to: textView)
        }
    }
}

private final class BottomAnchoredTextView: UITextView {
    override var canBecomeFirstResponder: Bool { true }
}
