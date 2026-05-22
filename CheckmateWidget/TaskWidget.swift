import WidgetKit
import SwiftUI

struct TaskTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh at midnight so overdue tasks surface automatically
        let midnight = Calendar.current.date(
            byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date().addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry() -> TaskEntry {
        let allTasks = AppGroupStore.loadTasks()
        let todayTasks = allTasks.filter {
            $0.status == .pending && $0.dueDate <= Date.today
        }.sorted { !$0.isSeen && $1.isSeen }

        let doneCount = AppGroupStore.loadDoneCount()
        let totalCount = todayTasks.count + doneCount

        return TaskEntry(
            date: Date(),
            tasks: todayTasks,
            doneCount: doneCount,
            totalCount: totalCount
        )
    }
}

struct CheckmateWidget: Widget {
    let kind = "CheckmateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskTimelineProvider()) { entry in
            TaskWidgetView(entry: entry)
                .containerBackground(Color(hex: 0xF6F6F6), for: .widget)
        }
        .configurationDisplayName("Checkmate")
        .description("Your tasks for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CheckmateWidgetBundle: WidgetBundle {
    var body: some Widget {
        CheckmateWidget()
    }
}
