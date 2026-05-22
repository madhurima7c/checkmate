import Foundation
import Supabase
import WidgetKit

@MainActor
class TaskStore: ObservableObject {
    static let shared = TaskStore()

    @Published var tasks: [CheckmateTask] = []
    @Published var isLoading = false
    @Published var recentlyCompleted: [CheckmateTask] = []
    @Published private(set) var newTaskIds: Set<UUID> = []

    private let pendingKey = "prototype_pending_tasks"
    private let completedKey = "prototype_completed_tasks"
    private let newIdsKey = "prototype_new_task_ids"
    private let newExposureKey = "prototype_new_exposure_counts"

    /// How many app opens have counted toward clearing the NEW badge (clears at 2).
    private var newExposureCounts: [UUID: Int] = [:]

    var usesCloud: Bool {
        !CheckmateConfig.isPrototype && AuthService.shared.isAuthenticated
    }

    private init() {
        if let ids = UserDefaults.standard.array(forKey: newIdsKey) as? [String] {
            newTaskIds = Set(ids.compactMap { UUID(uuidString: $0) })
        }
        if let data = UserDefaults.standard.data(forKey: newExposureKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            newExposureCounts = Dictionary(
                uniqueKeysWithValues: decoded.compactMap { key, value in
                    guard let id = UUID(uuidString: key) else { return nil }
                    return (id, value)
                }
            )
        }
    }

    func isNew(_ task: CheckmateTask) -> Bool {
        newTaskIds.contains(task.id)
    }

    /// Call once per app launch. First open keeps NEW; second open clears it.
    func recordLaunchWatch() {
        var changed = false
        for id in Array(newTaskIds) {
            let count = (newExposureCounts[id] ?? 0) + 1
            newExposureCounts[id] = count
            if count >= 2 {
                newTaskIds.remove(id)
                changed = true
            }
        }
        if changed {
            persistNewIds()
        }
        persistNewExposure()
    }

    // MARK: - Fetch

    func fetchTasks() async {
        isLoading = true
        defer { isLoading = false }
        if usesCloud {
            do {
                try await fetchFromSupabase()
                syncWidgetSnapshot()
                await RealtimeService.shared.startIfNeeded()
            } catch {
                print("Supabase fetch failed, using local cache: \(error)")
                loadLocal()
                syncWidgetSnapshot()
            }
        } else {
            loadLocal()
            syncWidgetSnapshot()
        }
    }

    // MARK: - Create

    func createTask(
        text: String,
        color: StickyColor,
        dueDate: Date,
        allDay: Bool,
        dueAt: Date?,
        assignee: TaskAssignee
    ) async throws -> CheckmateTask {
        if let link = assignee.friendLink {
            FriendsStore.shared.remember(link)
        }

        if usesCloud {
            return try await createOnSupabase(
                text: text, color: color, dueDate: dueDate,
                allDay: allDay, dueAt: dueAt, assignee: assignee
            )
        }

        let assignment = localAssignment(for: assignee)
        let task = CheckmateTask(
            id: UUID(),
            text: text,
            senderId: CheckmateConfig.prototypeUserId,
            receiverId: assignment.receiverId,
            dueDate: dueDate.startOfDay(),
            status: .pending,
            isSeen: true,
            color: color,
            allDay: allDay,
            dueAt: dueAt,
            createdAt: Date(),
            assigneeName: assignment.assigneeName,
            inviteContact: assignment.inviteContact
        )
        tasks.insert(task, at: 0)
        registerNewBadge(for: task.id)
        saveLocal()
        return task
    }

    // MARK: - Update / delete

    func updateTask(
        id: UUID,
        text: String,
        color: StickyColor,
        dueDate: Date,
        allDay: Bool,
        dueAt: Date?,
        assignee: TaskAssignee
    ) async throws -> (task: CheckmateTask, movedToFriends: Bool, movedToMyTodo: Bool) {
        if let link = assignee.friendLink {
            FriendsStore.shared.remember(link)
        }

        if usesCloud {
            let result = try await updateOnSupabase(
                id: id, text: text, color: color, dueDate: dueDate,
                allDay: allDay, dueAt: dueAt, assignee: assignee
            )
            saveLocal()
            WidgetCenter.shared.reloadAllTimelines()
            return result
        }

        let wasFriend = findTask(id: id)?.isAssignedToFriend ?? false
        let assignment = localAssignment(for: assignee)

        guard var task = removeTask(id: id) else {
            throw TaskStoreError.notFound
        }

        task.text = text
        task.color = color
        task.dueDate = dueDate.startOfDay()
        task.allDay = allDay
        task.dueAt = dueAt
        task.assigneeName = assignment.assigneeName
        task.inviteContact = assignment.inviteContact
        task.receiverId = assignment.receiverId

        insertTask(task)
        saveLocal()
        WidgetCenter.shared.reloadAllTimelines()

        return (
            task,
            movedToFriends: !wasFriend && !assignee.isMyself,
            movedToMyTodo: wasFriend && assignee.isMyself
        )
    }

    func deleteTask(id: UUID) async {
        if usesCloud {
            try? await deleteOnSupabase(id: id)
        }
        _ = removeTask(id: id)
        newTaskIds.remove(id)
        newExposureCounts.removeValue(forKey: id)
        persistNewIds()
        persistNewExposure()
        saveLocal()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Toggle done

    /// Immediate UI update — cloud sync runs in the background.
    func markDoneLocally(taskId: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        var task = tasks.remove(at: idx)
        task.status = .done
        recentlyCompleted.insert(task, at: 0)
        saveLocal()
        if usesCloud {
            Task {
                try? await SupabaseClient.shared
                    .from("tasks")
                    .update(TaskStatusUpdate(status: .done, completed_at: Date()))
                    .eq("id", value: taskId.uuidString)
                    .execute()
            }
        }
    }

    func undoPendingLocally(taskId: UUID) {
        guard let idx = recentlyCompleted.firstIndex(where: { $0.id == taskId }) else { return }
        var task = recentlyCompleted.remove(at: idx)
        task.status = .pending
        tasks.insert(task, at: 0)
        saveLocal()
        if usesCloud {
            Task {
                try? await SupabaseClient.shared
                    .from("tasks")
                    .update(TaskStatusUpdate(status: .pending, completed_at: nil))
                    .eq("id", value: taskId.uuidString)
                    .execute()
            }
        }
    }

    func markDone(taskId: UUID) async {
        markDoneLocally(taskId: taskId)
    }

    func undoPending(taskId: UUID) async {
        undoPendingLocally(taskId: taskId)
    }

    private func localAssignment(for assignee: TaskAssignee) -> (receiverId: UUID?, assigneeName: String?, inviteContact: String?) {
        switch assignee {
        case .myself:
            return (CheckmateConfig.prototypeUserId, "Myself", nil)
        case .person(let link):
            return (link.profileId ?? placeholderId(for: link.contact), link.name, link.contact)
        }
    }

    private func placeholderId(for contact: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        for (index, byte) in contact.utf8.enumerated() {
            bytes[index % 16] ^= byte
        }
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    // MARK: - Persistence

    private func loadLocal() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: pendingKey),
           let decoded = try? decoder.decode([CheckmateTask].self, from: data) {
            tasks = decoded
        }
        if let data = UserDefaults.standard.data(forKey: completedKey),
           let decoded = try? decoder.decode([CheckmateTask].self, from: data) {
            recentlyCompleted = decoded
        }
    }

    private func saveLocal() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(tasks) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
        if let data = try? encoder.encode(recentlyCompleted) {
            UserDefaults.standard.set(data, forKey: completedKey)
        }
        syncWidgetSnapshot()
    }

    /// Pushes today's My-todo tasks into the App Group for the home-screen widget.
    func syncWidgetSnapshot() {
        let today = Date.today
        let pending = tasks.filter {
            $0.status == .pending
                && $0.dueDate.startOfDay() <= today
                && !$0.isAssignedToFriend
        }
        let doneToday = recentlyCompleted.filter {
            $0.dueDate.startOfDay() == today && !$0.isAssignedToFriend
        }.count
        AppGroupStore.saveTasks(pending)
        AppGroupStore.setDoneCount(doneToday)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func registerNewBadge(for id: UUID) {
        newTaskIds.insert(id)
        // Creation counts as the first watch; badge clears on the next app launch.
        newExposureCounts[id] = 1
        persistNewIds()
        persistNewExposure()
    }

    private func persistNewIds() {
        UserDefaults.standard.set(newTaskIds.map(\.uuidString), forKey: newIdsKey)
    }

    private func persistNewExposure() {
        let encoded = Dictionary(uniqueKeysWithValues: newExposureCounts.map { ($0.key.uuidString, $0.value) })
        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: newExposureKey)
        }
    }

    @discardableResult
    func removeTask(id: UUID) -> CheckmateTask? {
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            return tasks.remove(at: idx)
        }
        if let idx = recentlyCompleted.firstIndex(where: { $0.id == id }) {
            return recentlyCompleted.remove(at: idx)
        }
        return nil
    }

    func insertTask(_ task: CheckmateTask) {
        if task.status == .done {
            recentlyCompleted.append(task)
        } else {
            tasks.insert(task, at: 0)
        }
    }

    func findTask(id: UUID) -> CheckmateTask? {
        tasks.first(where: { $0.id == id }) ?? recentlyCompleted.first(where: { $0.id == id })
    }

    // MARK: - Derived

    func myTodoPending(on day: Date) -> [CheckmateTask] {
        tasks(on: day).filter { !$0.isAssignedToFriend }
    }

    func myTodoCompleted(on day: Date) -> [CheckmateTask] {
        completedTasks(on: day).filter { !$0.isAssignedToFriend }
    }

    func friendsPending(on day: Date) -> [CheckmateTask] {
        tasks(on: day).filter(\.isAssignedToFriend)
    }

    func friendsCompleted(on day: Date) -> [CheckmateTask] {
        completedTasks(on: day).filter(\.isAssignedToFriend)
    }

    func tasks(on day: Date) -> [CheckmateTask] {
        let target = day.startOfDay()
        return tasks.filter { $0.dueDate.startOfDay() == target }
    }

    func completedTasks(on day: Date) -> [CheckmateTask] {
        let target = day.startOfDay()
        return recentlyCompleted.filter { $0.dueDate.startOfDay() == target }
    }

    func progress(on day: Date, tab: AppTab) -> (done: Int, total: Int) {
        let pending: Int
        let done: Int
        switch tab {
        case .myTodo:
            pending = myTodoPending(on: day).count
            done = myTodoCompleted(on: day).count
        case .friends:
            pending = friendsPending(on: day).count
            done = friendsCompleted(on: day).count
        }
        return (done, done + pending)
    }
}

private struct TaskStatusUpdate: Encodable {
    let status: TaskStatus
    let completed_at: Date?
}

enum TaskStoreError: LocalizedError {
    case notFound
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notFound: return "Task not found."
        case .notAuthenticated: return "Sign in to sync tasks."
        }
    }
}
