import WidgetKit
import SwiftUI

struct TaskTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        context.family == .systemLarge ? .largePlaceholder : .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        let entry = makeEntry()
        if context.isPreview, entry.totalCount == 0 {
            completion(context.family == .systemLarge ? .largePlaceholder : .placeholder)
        } else {
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = makeEntry()
        let midnight = Calendar.current.date(
            byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date().addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry() -> TaskEntry {
        let todayTasks = AppGroupStore.loadTodayWidgetTasks()
        let doneCount = todayTasks.filter { $0.status == .done }.count
        let totalCount = todayTasks.count
        let display = Self.orderedForWidget(todayTasks, limit: 5)

        return TaskEntry(
            date: Date(),
            tasks: display,
            doneCount: doneCount,
            totalCount: totalCount
        )
    }

    /// Pending first, completed last — matches home grid + Figma 684:3486.
    private static func orderedForWidget(_ tasks: [CheckmateTask], limit: Int) -> [CheckmateTask] {
        let pending = tasks.filter { $0.status == .pending }
        let done = tasks.filter { $0.status == .done }
        return Array((pending + done).prefix(limit))
    }
}

struct CheckmateWidget: Widget {
    let kind = "CheckmateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskTimelineProvider()) { entry in
            TaskWidgetView(entry: entry)
                .containerBackground(Color(hex: 0xF7F7F7), for: .widget)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Checkmate")
        .description("Today's todos at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct CheckmateWidgetBundle: WidgetBundle {
    var body: some Widget {
        CheckmateWidget()
    }
}
