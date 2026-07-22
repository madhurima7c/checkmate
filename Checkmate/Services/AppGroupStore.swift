import Foundation

// Shared data bridge between main app and widget extension via App Groups.
enum AppGroupStore {
    static let appGroupID = "group.com.madhurima.checkmate"

    private static var suite: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private static let todayTasksKey = "todayWidgetTasks"
    private static let newTaskIdsKey = "newTaskIds"
    private static let legacyTasksKey = "pendingTasks"
    private static let doneCountKey = "todayDoneCount"
    private static let doneDateKey = "todayDoneDate"

    // MARK: - Today widget snapshot

    static func saveTodayWidgetTasks(_ tasks: [CheckmateTask]) {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        suite.set(data, forKey: todayTasksKey)
    }

    static func saveNewTaskIds(_ ids: Set<UUID>) {
        suite.set(ids.map(\.uuidString), forKey: newTaskIdsKey)
    }

    static func loadNewTaskIds() -> Set<UUID> {
        guard let raw = suite.array(forKey: newTaskIdsKey) as? [String] else { return [] }
        return Set(raw.compactMap { UUID(uuidString: $0) })
    }

    static func isNewTask(_ id: UUID) -> Bool {
        loadNewTaskIds().contains(id)
    }

    /// Drop corrupt or legacy multi‑MB widget snapshots that can jetsam the app on launch.
    private static let maxWidgetSnapshotBytes = 512_000

    static func loadTodayWidgetTasks() -> [CheckmateTask] {
        if let data = suite.data(forKey: todayTasksKey) {
            if data.count > maxWidgetSnapshotBytes {
                suite.removeObject(forKey: todayTasksKey)
                return []
            }
            if let decoded = try? JSONDecoder().decode([CheckmateTask].self, from: data) {
                return decoded.map { task in
                    var copy = task
                    copy.widgetAvatarImageData = nil
                    return copy
                }
            }
        }
        // Legacy: pending-only list.
        return loadLegacyPendingTasks()
    }

    static func toggleTaskStatus(id: String) {
        var tasks = loadTodayWidgetTasks()
        guard let index = tasks.firstIndex(where: { $0.id.uuidString == id }) else { return }
        tasks[index].status = tasks[index].status == .done ? .pending : .done
        tasks = widgetDisplayOrder(tasks)
        saveTodayWidgetTasks(tasks)
        setDoneCount(tasks.filter { $0.status == .done }.count)
    }

    /// Keeps pending rows above done rows after widget toggles.
    private static func widgetDisplayOrder(_ tasks: [CheckmateTask]) -> [CheckmateTask] {
        tasks.filter { $0.status == .pending } + tasks.filter { $0.status == .done }
    }

    // MARK: - Legacy pending list (kept for older widget builds)

    static func saveTasks(_ tasks: [CheckmateTask]) {
        saveTodayWidgetTasks(tasks)
    }

    static func loadTasks() -> [CheckmateTask] {
        loadTodayWidgetTasks().filter { $0.status == .pending }
    }

    static func removeTask(id: String) {
        toggleTaskStatus(id: id)
    }

    private static func loadLegacyPendingTasks() -> [CheckmateTask] {
        guard let data = suite.data(forKey: legacyTasksKey) else { return [] }
        if data.count > maxWidgetSnapshotBytes {
            suite.removeObject(forKey: legacyTasksKey)
            return []
        }
        guard let decoded = try? JSONDecoder().decode([CheckmateTask].self, from: data) else { return [] }
        return decoded.map { task in
            var copy = task
            copy.widgetAvatarImageData = nil
            return copy
        }
    }

    // MARK: - Done count

    static func incrementDoneCount() {
        setDoneCount(loadDoneCount() + 1)
    }

    static func loadDoneCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = suite.object(forKey: doneDateKey) as? Date ?? .distantPast
        guard Calendar.current.isDate(today, inSameDayAs: savedDate) else { return 0 }
        return suite.integer(forKey: doneCountKey)
    }

    static func setDoneCount(_ count: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        suite.set(count, forKey: doneCountKey)
        suite.set(today, forKey: doneDateKey)
    }
}
