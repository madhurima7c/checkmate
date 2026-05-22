import Foundation

// Shared data bridge between main app and widget extension via App Groups.
// App Group ID must match the one registered in Xcode capabilities.
enum AppGroupStore {
    static let appGroupID = "group.com.madhurima.checkmate"

    private static var suite: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private static let tasksKey = "pendingTasks"
    private static let doneCountKey = "todayDoneCount"
    private static let doneDateKey = "todayDoneDate"

    static func saveTasks(_ tasks: [CheckmateTask]) {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        suite.set(data, forKey: tasksKey)
    }

    static func loadTasks() -> [CheckmateTask] {
        guard let data = suite.data(forKey: tasksKey) else { return [] }
        return (try? JSONDecoder().decode([CheckmateTask].self, from: data)) ?? []
    }

    static func removeTask(id: String) {
        var tasks = loadTasks()
        tasks.removeAll { $0.id.uuidString == id }
        saveTasks(tasks)
    }

    static func incrementDoneCount() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = suite.object(forKey: doneDateKey) as? Date ?? .distantPast
        var count = Calendar.current.isDate(today, inSameDayAs: savedDate)
            ? suite.integer(forKey: doneCountKey)
            : 0
        count += 1
        suite.set(count, forKey: doneCountKey)
        suite.set(today, forKey: doneDateKey)
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
