// TODO: Final widget design pending. This is the MVP placeholder tile.
// It renders the top todo for today as a sticky-note card with a checkbox
// (wired to MarkDoneIntent) plus a "+N more" footer. Real visuals will land
// once Figma includes widget designs.

import SwiftUI
import WidgetKit

struct TaskWidgetView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) private var family

    private var topTask: CheckmateTask? { entry.tasks.first }
    private var extra: Int { max(0, entry.tasks.count - 1) }

    var body: some View {
        if let task = topTask {
            stickyContent(task: task)
        } else {
            emptyContent
        }
    }

    private func stickyContent(task: CheckmateTask) -> some View {
        ZStack {
            (sharedColor(task.color) ?? Color(hex: 0xFFEEAE))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white, lineWidth: 3)
                )

            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Button(intent: MarkDoneIntent(taskId: task.id.uuidString)) {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.4), lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    if extra > 0 {
                        Text("+\(extra)")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.white.opacity(0.6), in: Capsule())
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }
                Spacer()
                Text(task.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: 0x2F2F2F))
                    .lineLimit(3)
            }
            .padding(12)
        }
    }

    private var emptyContent: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: 0x4A8FFF))
            Text("All clear")
                .font(.system(size: 13, weight: .semibold))
            Text("Today is yours.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sharedColor(_ c: StickyColor) -> Color? { c.paper }
}
