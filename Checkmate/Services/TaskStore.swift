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

        let wasFriend = findTask(id: id)?.isOutgoingToFriend ?? false
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
        ContactUserId.placeholder(from: contact)
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

    /// Pushes today's home-screen tasks (My Todo + Friends) into the App Group for the widget.
    func syncWidgetSnapshot() {
        let today = Date.today
        let pending = myTodoPending(on: today) + friendsPending(on: today)
        let completed = myTodoCompleted(on: today) + friendsCompleted(on: today)
        let snapshot = (pending + completed).map { taskWithWidgetAvatar($0) }
        AppGroupStore.saveTodayWidgetTasks(snapshot)
        AppGroupStore.setDoneCount(completed.count)
        AppGroupStore.saveNewTaskIds(newTaskIds)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func taskWithWidgetAvatar(_ task: CheckmateTask) -> CheckmateTask {
        var copy = task
        let avatar = widgetAvatarFields(for: task)
        copy.widgetAvatarName = avatar.name
        copy.widgetAvatarImageData = avatar.imageData
        return copy
    }

    private func widgetAvatarFields(for task: CheckmateTask) -> (name: String?, imageData: Data?) {
        if task.isIncomingFromOther {
            let name = FriendsStore.shared.displayName(forUserId: task.senderId) ?? "Friend"
            let data = FriendsStore.shared.friendLink(forUserId: task.senderId)?.avatarData
            return (name, data)
        }
        if task.isOutgoingToFriend {
            if let contact = task.inviteContact,
               let link = FriendsStore.shared.recent.first(where: { $0.contact == contact }) {
                return (task.assigneeName ?? link.name, link.avatarData)
            }
            if let receiverId = task.receiverId,
               let link = FriendsStore.shared.friendLink(forUserId: receiverId) {
                return (task.assigneeName ?? link.name, link.avatarData)
            }
            if let name = task.assigneeName, !name.isEmpty {
                return (name, nil)
            }
        }
        return (nil, nil)
    }

    /// Applies checkbox changes made on the widget while the app was closed.
    func applyWidgetSnapshotIfNeeded() {
        let snapshot = AppGroupStore.loadTodayWidgetTasks()
        guard !snapshot.isEmpty else { return }

        for task in snapshot where task.dueDate.startOfDay() <= Date.today {
            let isPendingLocally = tasks.contains { $0.id == task.id }
            let isDoneLocally = recentlyCompleted.contains { $0.id == task.id }

            switch task.status {
            case .done where isPendingLocally:
                markDoneLocally(taskId: task.id)
            case .pending where isDoneLocally:
                undoPendingLocally(taskId: task.id)
            default:
                break
            }
        }
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
        tasks(on: day).filter { !$0.isOutgoingToFriend }
    }

    func myTodoCompleted(on day: Date) -> [CheckmateTask] {
        completedTasks(on: day).filter { !$0.isOutgoingToFriend }
    }

    func friendsPending(on day: Date) -> [CheckmateTask] {
        tasks(on: day).filter(\.isOutgoingToFriend)
    }

    func friendsCompleted(on day: Date) -> [CheckmateTask] {
        completedTasks(on: day).filter(\.isOutgoingToFriend)
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
