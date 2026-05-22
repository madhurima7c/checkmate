import SwiftUI
import UIKit

/// Text input anchored to the bottom-left of a sticky note (Figma add-todo editor).
struct BottomAnchoredTextEditor: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var placeholder: String = "Tap to write"

    private let horizontalPadding: CGFloat = 14
    private let verticalPadding: CGFloat = 14

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if text.isEmpty && !isFocused.wrappedValue {
                Button {
                    isFocused.wrappedValue = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                        Text(placeholder)
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(Theme.Palette.strike)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, verticalPadding)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }

            BottomAnchoredTextViewRepresentable(
                text: $text,
                isFocused: isFocused,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding
            )
            .opacity(text.isEmpty && !isFocused.wrappedValue ? 0.02 : 1)
        }
    }
}

private struct BottomAnchoredTextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.font = .systemFont(ofSize: 16, weight: .medium)
        view.textColor = UIColor(Theme.Palette.body)
        view.textAlignment = .left
        view.isScrollEnabled = true
        view.textContainer.lineFragmentPadding = 0
        view.textContainerInset = .zero
        view.delegate = context.coordinator
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
            context.coordinator.applyBottomInset(to: uiView)
        }

        if isFocused.wrappedValue, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused.wrappedValue, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: BottomAnchoredTextViewRepresentable

        init(_ parent: BottomAnchoredTextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            applyBottomInset(to: textView)
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused.wrappedValue = true
            applyBottomInset(to: textView)
            // Place caret at end (bottom of sticky-note flow).
            let end = textView.text.count
            textView.selectedRange = NSRange(location: end, length: 0)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused.wrappedValue = false
        }

        func applyBottomInset(to textView: UITextView) {
            guard textView.bounds.width > 1, textView.bounds.height > 1 else { return }
            let usableWidth = textView.bounds.width
                - parent.horizontalPadding * 2
                - textView.textContainer.lineFragmentPadding * 2
            let size = textView.sizeThatFits(
                CGSize(width: max(usableWidth, 1), height: .greatestFiniteMagnitude)
            )
            let contentHeight = max(size.height, textView.font?.lineHeight ?? 20)
            let topInset = max(
                parent.verticalPadding,
                textView.bounds.height - contentHeight - parent.verticalPadding
            )
            textView.textContainerInset = UIEdgeInsets(
                top: topInset,
                left: parent.horizontalPadding,
                bottom: parent.verticalPadding,
                right: parent.horizontalPadding
            )
        }
    }
}
