import AppIntents
import WidgetKit

/// Toggles a today task done ↔ pending from the home-screen widget.
struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"
    static var description = IntentDescription("Checks or unchecks a Checkmate task from the widget.")

    @Parameter(title: "Task ID")
    var taskId: String

    init() {}
    init(taskId: String) {
        self.taskId = taskId
    }

    func perform() async throws -> some IntentResult {
        AppGroupStore.toggleTaskStatus(id: taskId)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
