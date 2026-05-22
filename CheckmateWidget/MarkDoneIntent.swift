import AppIntents
import WidgetKit

struct MarkDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Task Done"
    static var description = IntentDescription("Marks a Checkmate task as done from the widget.")

    @Parameter(title: "Task ID")
    var taskId: String

    init() {}
    init(taskId: String) {
        self.taskId = taskId
    }

    func perform() async throws -> some IntentResult {
        AppGroupStore.removeTask(id: taskId)
        AppGroupStore.incrementDoneCount()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
