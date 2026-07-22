import SwiftUI
import WidgetKit
import UIKit

// Figma 684:3486 / 684:3356 — medium widget; 681:3165 — large.

private enum WidgetPalette {
    static let canvas = Color(hex: 0xF7F7F7)
    static let ink = Color(hex: 0x0E0E0E)
    static let body = Color(hex: 0x2F2F2F)
    static let dim = Color(hex: 0xA9A9A9)
    static let strike = Color(white: 0, opacity: 0.38)
    static let selectionBlue = Color(hex: 0x0088FF)
    static let newRed = Color(hex: 0xF83A00)
    static let checkboxStroke = Color(white: 0, opacity: 0.39)
}

/// Figma 684:3486 artboard (338×158).
private enum FigmaMediumWidget {
    static let designSize = CGSize(width: 338, height: 158)
    static let padding: CGFloat = 16
    static let titleFontSize: CGFloat = 26
    static let titleLineHeight: CGFloat = 31
    static let leftColumnWidth: CGFloat = 118
    static let taskColumnWidth: CGFloat = 188
    static let rowHeight: CGFloat = 38
    static let rowSpacing: CGFloat = 6
    static let rowCornerRadius: CGFloat = 12
    static let rowBorderWidth: CGFloat = 2
    static let rowLeading: CGFloat = 9
    static let rowTrailing: CGFloat = 8
    static let rowGap: CGFloat = 6
    static let checkboxSize: CGFloat = 16
    static let checkboxRadius: CGFloat = 4.8
    static let checkboxStrokeWidth: CGFloat = 1.6
    static let checkmarkSize: CGFloat = 9
    static let taskFontSize: CGFloat = 13
    static let avatarSize: CGFloat = 18
    static let avatarRadius: CGFloat = 9
    /// Figma 684:3386 — Group 33; large widget / default ring frame.
    static let dialSize: CGFloat = 19.813
    /// Medium widget — slightly smaller ring, same stroke weight.
    static let mediumDialSize: CGFloat = 17
    /// Thick ring on a compact dial — same 5pt as home `Theme.Stroke.progressRing`.
    static let dialStrokeWidth: CGFloat = 5
    static let progressLabelSize: CGFloat = 15
    static let progressStackSpacing: CGFloat = 6
    static let progressBlockHeight: CGFloat = 41.813
}

private struct WidgetScale {
    let horizontal: CGFloat
    let vertical: CGFloat
    let uniform: CGFloat

    init(in size: CGSize) {
        horizontal = size.width / FigmaMediumWidget.designSize.width
        vertical = size.height / FigmaMediumWidget.designSize.height
        uniform = min(horizontal, vertical)
    }

    func u(_ value: CGFloat) -> CGFloat { value * uniform }
    func x(_ value: CGFloat) -> CGFloat { value * horizontal }
    func y(_ value: CGFloat) -> CGFloat { value * vertical }
}

private enum WidgetRowStyle {
    case medium
    case large

    var rowHeight: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.rowHeight
        case .large: 50
        }
    }

    var rowSpacing: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.rowSpacing
        case .large: 10
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.taskFontSize
        case .large: 15
        }
    }

    var doneFontSize: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.taskFontSize
        case .large: 16
        }
    }

    var checkboxSize: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.checkboxSize
        case .large: 20
        }
    }

    var checkboxRadius: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.checkboxRadius
        case .large: 6
        }
    }

    var checkboxStrokeWidth: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.checkboxStrokeWidth
        case .large: 2
        }
    }

    var checkmarkSize: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.checkmarkSize
        case .large: 11
        }
    }

    var avatarSize: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.avatarSize
        case .large: 20
        }
    }

    var avatarRadius: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.avatarRadius
        case .large: 10
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.rowLeading
        case .large: 12
        }
    }

    var trailingPadding: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.rowTrailing
        case .large: 12
        }
    }

    var progressLabelSize: CGFloat {
        switch self {
        case .medium: FigmaMediumWidget.progressLabelSize
        case .large: 20
        }
    }

    var showsNewBadge: Bool {
        switch self {
        case .medium: false
        case .large: true
        }
    }
}

struct TaskWidgetView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) private var family

    /// Pending first, done last — matches Figma 684:3486 row order.
    private var mediumTasks: [CheckmateTask] {
        let pending = entry.tasks.filter { $0.status == .pending }
        let done = entry.tasks.filter { $0.status == .done }
        return Array((pending + done).prefix(3))
    }

    var body: some View {
        switch family {
        case .systemLarge:
            largeWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var progressFraction: Double {
        entry.totalCount == 0 ? 0 : Double(entry.doneCount) / Double(entry.totalCount)
    }

    private var progressLabel: String {
        guard entry.totalCount > 0 else { return "0 of 0 done" }
        return "\(entry.doneCount) of \(entry.totalCount) done"
    }

    // MARK: - Large (Figma 681:3165)

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text("Today")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(WidgetPalette.ink)
                Spacer(minLength: 0)
                WidgetProgressDial(
                    fraction: progressFraction,
                    size: FigmaMediumWidget.dialSize
                )
                Text(progressLabel)
                    .font(.system(size: WidgetRowStyle.large.progressLabelSize, weight: .semibold))
                    .foregroundStyle(WidgetPalette.dim)
            }

            Spacer(minLength: 12)

            largeTaskList
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    private var largeTaskList: some View {
        VStack(spacing: WidgetRowStyle.large.rowSpacing) {
            if entry.totalCount == 0 {
                Text("Tap + in Checkmate to add a todo")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(WidgetPalette.dim)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                ForEach(Array(entry.tasks.prefix(5))) { task in
                    WidgetTaskRow(task: task, style: .large, scale: nil)
                }
            }
        }
    }

    // MARK: - Medium (Figma 684:3486)

    private var mediumWidget: some View {
        GeometryReader { geo in
            let scale = WidgetScale(in: geo.size)
            let pad = scale.u(FigmaMediumWidget.padding)

            HStack(alignment: .top, spacing: 0) {
                mediumTodayColumn(scale: scale)
                    .frame(width: scale.x(FigmaMediumWidget.leftColumnWidth), alignment: .leading)

                mediumTaskColumn(scale: scale)
                    .frame(width: scale.x(FigmaMediumWidget.taskColumnWidth), alignment: .leading)
            }
            .padding(pad)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }

    private func mediumTodayColumn(scale: WidgetScale) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Today")
                .font(.system(size: scale.u(FigmaMediumWidget.titleFontSize), weight: .semibold))
                .foregroundStyle(WidgetPalette.ink)
                .frame(height: scale.y(FigmaMediumWidget.titleLineHeight), alignment: .topLeading)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: scale.y(FigmaMediumWidget.progressStackSpacing)) {
                WidgetProgressDial(
                    fraction: progressFraction,
                    size: scale.u(FigmaMediumWidget.mediumDialSize),
                    strokeWidth: scale.u(FigmaMediumWidget.dialStrokeWidth)
                )
                Text(progressLabel)
                    .font(.system(size: scale.u(FigmaMediumWidget.progressLabelSize), weight: .semibold))
                    .foregroundStyle(WidgetPalette.dim)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(height: scale.y(FigmaMediumWidget.progressBlockHeight), alignment: .topLeading)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func mediumTaskColumn(scale: WidgetScale) -> some View {
        VStack(spacing: scale.y(FigmaMediumWidget.rowSpacing)) {
            if entry.totalCount == 0 {
                Text("Tap + in Checkmate\nto add a todo")
                    .font(.system(size: scale.u(13), weight: .medium))
                    .foregroundStyle(WidgetPalette.dim)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ForEach(mediumTasks) { task in
                    WidgetTaskRow(task: task, style: .medium, scale: scale)
                        .frame(height: scale.y(FigmaMediumWidget.rowHeight))
                }
            }
        }
    }

    // MARK: - Small

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(WidgetPalette.ink)
            if let task = entry.tasks.first {
                WidgetTaskRow(task: task, style: .medium, scale: nil)
            } else {
                Text("All clear")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetPalette.dim)
            }
        }
        .padding(14)
    }
}

// MARK: - Task row

private struct WidgetTaskRow: View {
    let task: CheckmateTask
    let style: WidgetRowStyle
    var scale: WidgetScale?

    private var isDone: Bool { task.status == .done }

    private var showsAssigneeAvatar: Bool {
        guard let name = task.widgetAvatarName else { return false }
        return !name.isEmpty
    }

    private var showsNewBadge: Bool {
        style.showsNewBadge && AppGroupStore.isNewTask(task.id)
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        scale?.u(value) ?? value
    }

    var body: some View {
        HStack(spacing: scaled(FigmaMediumWidget.rowGap)) {
            Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
                WidgetCheckbox(isDone: isDone, style: style, scale: scale)
            }
            .buttonStyle(.plain)

            WidgetTaskLabel(text: task.text, isDone: isDone, style: style, scale: scale)

            if showsNewBadge {
                WidgetNewBadge()
            }

            Spacer(minLength: 0)

            if showsAssigneeAvatar {
                WidgetAssigneeAvatar(task: task, style: style, scale: scale)
            }
        }
        .padding(.leading, scaled(style.horizontalPadding))
        .padding(.trailing, scaled(style.trailingPadding))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(task.color.paper)
        .clipShape(RoundedRectangle(cornerRadius: scaled(FigmaMediumWidget.rowCornerRadius), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: scaled(FigmaMediumWidget.rowCornerRadius), style: .continuous)
                .strokeBorder(.white, lineWidth: scaled(FigmaMediumWidget.rowBorderWidth))
        )
        .overlay(
            RoundedRectangle(cornerRadius: scaled(FigmaMediumWidget.rowCornerRadius), style: .continuous)
                .stroke(Color.black.opacity(0.03), lineWidth: 1)
        )
        .widgetURL(URL(string: "checkmate://today"))
    }
}

private struct WidgetTaskLabel: View {
    let text: String
    let isDone: Bool
    let style: WidgetRowStyle
    var scale: WidgetScale?

    var body: some View {
        Text(attributed)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var attributed: AttributedString {
        let size = (scale?.u(style.fontSize)) ?? style.fontSize
        var value = AttributedString(text)
        let weight: UIFont.Weight = isDone ? .regular : .medium
        value.font = UIFont.systemFont(ofSize: size, weight: weight)
        if isDone {
            value.foregroundColor = UIColor(white: 0, alpha: 0.38)
            value.strikethroughStyle = .single
        } else {
            value.foregroundColor = UIColor(red: 47 / 255, green: 47 / 255, blue: 47 / 255, alpha: 1)
        }
        return value
    }
}

private struct WidgetCheckbox: View {
    let isDone: Bool
    let style: WidgetRowStyle
    var scale: WidgetScale?

    private func scaled(_ value: CGFloat) -> CGFloat {
        scale?.u(value) ?? value
    }

    var body: some View {
        Group {
            if isDone {
                ZStack {
                    RoundedRectangle(cornerRadius: scaled(style.checkboxRadius), style: .continuous)
                        .fill(WidgetPalette.selectionBlue)
                    Image(systemName: "checkmark")
                        .font(.system(size: scaled(style.checkmarkSize), weight: .bold))
                        .foregroundStyle(.white)
                }
            } else {
                RoundedRectangle(cornerRadius: scaled(style.checkboxRadius), style: .continuous)
                    .strokeBorder(WidgetPalette.checkboxStroke, lineWidth: scaled(style.checkboxStrokeWidth))
            }
        }
        .frame(width: scaled(style.checkboxSize), height: scaled(style.checkboxSize))
    }
}

private struct WidgetAssigneeAvatar: View {
    let task: CheckmateTask
    let style: WidgetRowStyle
    var scale: WidgetScale?

    private func scaled(_ value: CGFloat) -> CGFloat {
        scale?.u(value) ?? value
    }

    var body: some View {
        Group {
            if let data = task.widgetAvatarImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                let name = task.widgetAvatarName ?? "?"
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xFFC7EC))
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: scaled(style.avatarSize) * 0.45, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x2F2F2F))
                }
            }
        }
        .frame(width: scaled(style.avatarSize), height: scaled(style.avatarSize))
        .clipShape(RoundedRectangle(cornerRadius: scaled(style.avatarRadius), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: scaled(style.avatarRadius), style: .continuous)
                .strokeBorder(Color.white.opacity(0.91), lineWidth: scaled(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: scaled(style.avatarRadius), style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: scaled(0.9))
        )
    }
}

private struct WidgetNewBadge: View {
    var body: some View {
        Text("NEW")
            .font(.system(size: 15, weight: .regular))
            .tracking(-3.3)
            .foregroundStyle(WidgetPalette.newRed)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .strokeBorder(WidgetPalette.newRed, lineWidth: 1.2)
            )
            .fixedSize()
    }
}

// MARK: - Progress dial

/// Progress ring — Figma 684:3386 (same colors/caps as home; widget-sized stroke).
private struct WidgetProgressDial: View {
    let fraction: Double
    var size: CGFloat = FigmaMediumWidget.dialSize
    var strokeWidth: CGFloat = FigmaMediumWidget.dialStrokeWidth

    var body: some View {
        let clamped = max(0, min(1, fraction))
        let ring = StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
        ZStack {
            Circle()
                .stroke(WidgetPalette.selectionBlue.opacity(0.22), style: ring)
            Circle()
                .trim(from: 0, to: clamped > 0 ? clamped : 0.001)
                .stroke(WidgetPalette.selectionBlue, style: ring)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

#if DEBUG
#Preview("Medium — Figma 684:3486", as: .systemMedium) {
    CheckmateWidget()
} timeline: {
    TaskEntry.placeholder
}
#endif
