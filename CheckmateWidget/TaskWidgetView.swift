import SwiftUI
import WidgetKit

// Figma 684:3356 / 684:3486 — medium widget; 681:3165 — large.

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

private enum WidgetRowStyle {
    case medium
    case large

    var rowHeight: CGFloat {
        switch self {
        case .medium: 40
        case .large: 50
        }
    }

    var rowSpacing: CGFloat {
        switch self {
        case .medium: 6
        case .large: 10
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .medium: 13
        case .large: 15
        }
    }

    var doneFontSize: CGFloat {
        switch self {
        case .medium: 13
        case .large: 16
        }
    }

    var checkboxSize: CGFloat {
        switch self {
        case .medium: 16
        case .large: 20
        }
    }

    var checkboxRadius: CGFloat {
        switch self {
        case .medium: 4.8
        case .large: 6
        }
    }

    var checkboxStrokeWidth: CGFloat {
        switch self {
        case .medium: 1.6
        case .large: 2
        }
    }

    var checkmarkSize: CGFloat {
        switch self {
        case .medium: 9
        case .large: 11
        }
    }

    var avatarSize: CGFloat {
        switch self {
        case .medium: 18
        case .large: 20
        }
    }

    var avatarRadius: CGFloat {
        switch self {
        case .medium: 9
        case .large: 10
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .medium: 10
        case .large: 12
        }
    }

    var progressLabelSize: CGFloat {
        switch self {
        case .medium: 15
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

private enum MediumWidgetMetrics {
    static let horizontalPadding: CGFloat = 18
    static let topPadding: CGFloat = 14
    static let leftColumnWidth: CGFloat = 131
    static let progressDialSize: CGFloat = 20.14
    static let progressDialStroke: CGFloat = 2.25
    static let titleSize: CGFloat = 26
    static let titleTopInset: CGFloat = 15.5
    static let progressBottomInset: CGFloat = 12
}

struct TaskWidgetView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) private var family

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
                    size: 20,
                    lineWidth: 2.25
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
                    WidgetTaskRow(task: task, style: .large)
                }
            }
        }
    }

    // MARK: - Medium (Figma 684:3356 / 684:3486)

    private var mediumWidget: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Today")
                    .font(.system(size: MediumWidgetMetrics.titleSize, weight: .semibold))
                    .foregroundStyle(WidgetPalette.ink)
                    .padding(.top, MediumWidgetMetrics.titleTopInset)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 6) {
                    WidgetProgressDial(
                        fraction: progressFraction,
                        size: MediumWidgetMetrics.progressDialSize,
                        lineWidth: MediumWidgetMetrics.progressDialStroke
                    )
                    Text(progressLabel)
                        .font(.system(size: WidgetRowStyle.medium.progressLabelSize, weight: .semibold))
                        .foregroundStyle(WidgetPalette.dim)
                }
                .padding(.bottom, MediumWidgetMetrics.progressBottomInset)
            }
            .frame(width: MediumWidgetMetrics.leftColumnWidth, alignment: .leading)

            mediumTaskList
        }
        .padding(.horizontal, MediumWidgetMetrics.horizontalPadding)
        .padding(.top, MediumWidgetMetrics.topPadding)
    }

    private var mediumTaskList: some View {
        VStack(spacing: WidgetRowStyle.medium.rowSpacing) {
            if entry.totalCount == 0 {
                Text("Tap + in Checkmate\nto add a todo")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetPalette.dim)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ForEach(Array(entry.tasks.prefix(3))) { task in
                    WidgetTaskRow(task: task, style: .medium)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Small (placeholder until designed)

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(WidgetPalette.ink)
            if let task = entry.tasks.first {
                WidgetTaskRow(task: task, style: .medium)
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

    private var isDone: Bool { task.status == .done }

    private var showsAssigneeAvatar: Bool {
        guard let name = task.widgetAvatarName else { return false }
        return !name.isEmpty
    }

    private var showsNewBadge: Bool {
        style.showsNewBadge && AppGroupStore.isNewTask(task.id)
    }

    var body: some View {
        HStack(spacing: 6) {
            Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
                WidgetCheckbox(isDone: isDone, style: style)
            }
            .buttonStyle(.plain)

            Text(task.text)
                .font(.system(
                    size: isDone ? style.doneFontSize : style.fontSize,
                    weight: isDone ? .regular : .medium
                ))
                .foregroundStyle(isDone ? WidgetPalette.strike : WidgetPalette.body)
                .strikethrough(isDone, color: WidgetPalette.strike)
                .lineLimit(1)
                .truncationMode(.tail)

            if showsNewBadge {
                WidgetNewBadge()
            }

            Spacer(minLength: 0)

            if showsAssigneeAvatar {
                WidgetAssigneeAvatar(task: task, style: style)
            }
        }
        .padding(.horizontal, style.horizontalPadding)
        .frame(maxWidth: .infinity)
        .frame(height: style.rowHeight)
        .background(task.color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white, lineWidth: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.03), lineWidth: 1)
        )
        .widgetURL(URL(string: "checkmate://today"))
    }
}

private struct WidgetCheckbox: View {
    let isDone: Bool
    let style: WidgetRowStyle

    var body: some View {
        Group {
            if isDone {
                ZStack {
                    RoundedRectangle(cornerRadius: style.checkboxRadius, style: .continuous)
                        .fill(WidgetPalette.selectionBlue)
                    Image(systemName: "checkmark")
                        .font(.system(size: style.checkmarkSize, weight: .bold))
                        .foregroundStyle(.white)
                }
            } else {
                RoundedRectangle(cornerRadius: style.checkboxRadius, style: .continuous)
                    .strokeBorder(WidgetPalette.checkboxStroke, lineWidth: style.checkboxStrokeWidth)
            }
        }
        .frame(width: style.checkboxSize, height: style.checkboxSize)
    }
}

private struct WidgetAssigneeAvatar: View {
    let task: CheckmateTask
    let style: WidgetRowStyle

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
                        .font(.system(size: style.avatarSize * 0.45, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x2F2F2F))
                }
            }
        }
        .frame(width: style.avatarSize, height: style.avatarSize)
        .clipShape(RoundedRectangle(cornerRadius: style.avatarRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: style.avatarRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.91), lineWidth: 0.9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: style.avatarRadius, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.9)
        )
    }
}

/// Figma 683:3273 — hand-drawn NEW oval (large widget only).
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

private struct WidgetProgressDial: View {
    let fraction: Double
    var size: CGFloat = 20
    var lineWidth: CGFloat = 2.25

    var body: some View {
        let ring = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        ZStack {
            Circle()
                .stroke(WidgetPalette.selectionBlue.opacity(0.22), style: ring)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(WidgetPalette.selectionBlue, style: ring)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
