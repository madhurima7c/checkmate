import Foundation
import Supabase

extension TaskStore {
    func fetchFromSupabase() async throws {
        guard let userId = AuthService.shared.currentUserId else { return }

        let rows: [CheckmateTask] = try await SupabaseClient.shared
            .from("tasks")
            .select()
            .or("sender_id.eq.\(userId.uuidString),receiver_id.eq.\(userId.uuidString)")
            .order("created_at", ascending: false)
            .execute()
            .value

        tasks = rows.filter { $0.status == .pending }
        recentlyCompleted = rows.filter { $0.status == .done }
    }

    func createOnSupabase(
        text: String,
        color: StickyColor,
        dueDate: Date,
        allDay: Bool,
        dueAt: Date?,
        assignee: TaskAssignee
    ) async throws -> CheckmateTask {
        guard let senderId = AuthService.shared.currentUserId else {
            throw TaskStoreError.notAuthenticated
        }

        let payload = buildInsertPayload(
            text: text,
            color: color,
            dueDate: dueDate,
            allDay: allDay,
            dueAt: dueAt,
            assignee: assignee,
            senderId: senderId
        )

        let rows: [CheckmateTask] = try await SupabaseClient.shared
            .from("tasks")
            .insert(payload)
            .select()
            .execute()
            .value

        guard let task = rows.first else { throw TaskStoreError.notFound }
        tasks.insert(task, at: 0)
        registerNewBadge(for: task.id)

        if case .person(let link) = assignee, !link.isOnCheckmate {
            try await InviteService.shared.recordInvite(for: link)
        }

        return task
    }

    func updateOnSupabase(
        id: UUID,
        text: String,
        color: StickyColor,
        dueDate: Date,
        allDay: Bool,
        dueAt: Date?,
        assignee: TaskAssignee
    ) async throws -> (task: CheckmateTask, movedToFriends: Bool, movedToMyTodo: Bool) {
        guard let senderId = AuthService.shared.currentUserId else {
            throw TaskStoreError.notAuthenticated
        }

        let wasFriend = findTask(id: id)?.isAssignedToFriend ?? false
        let payload = buildUpdatePayload(
            text: text,
            color: color,
            dueDate: dueDate,
            allDay: allDay,
            dueAt: dueAt,
            assignee: assignee,
            senderId: senderId
        )

        let rows: [CheckmateTask] = try await SupabaseClient.shared
            .from("tasks")
            .update(payload)
            .eq("id", value: id.uuidString)
            .select()
            .execute()
            .value

        guard let task = rows.first else { throw TaskStoreError.notFound }
        _ = removeTask(id: id)
        insertTask(task)

        if case .person(let link) = assignee, !link.isOnCheckmate {
            try await InviteService.shared.recordInvite(for: link)
        }

        return (
            task,
            movedToFriends: !wasFriend && !assignee.isMyself,
            movedToMyTodo: wasFriend && assignee.isMyself
        )
    }

    func deleteOnSupabase(id: UUID) async throws {
        try await SupabaseClient.shared
            .from("tasks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Payload builders

    private func buildInsertPayload(
        text: String,
        color: StickyColor,
        dueDate: Date,
        allDay: Bool,
        dueAt: Date?,
        assignee: TaskAssignee,
        senderId: UUID
    ) -> TaskInsertPayload {
        let assignment = resolveAssignment(assignee: assignee, senderId: senderId)
        return TaskInsertPayload(
            text: text,
            sender_id: senderId,
            receiver_id: assignment.receiverId,
            due_date: dueDate,
            color: color,
            all_day: allDay,
            due_at: dueAt,
            assignee_name: assignment.assigneeName,
            invite_contact: assignment.inviteContact
        )
    }

    private func buildUpdatePayload(
        text: String,
        color: StickyColor,
        dueDate: Date,
        allDay: Bool,
        dueAt: Date?,
        assignee: TaskAssignee,
        senderId: UUID
    ) -> TaskUpdatePayload {
        let assignment = resolveAssignment(assignee: assignee, senderId: senderId)
        return TaskUpdatePayload(
            text: text,
            receiver_id: assignment.receiverId,
            due_date: dueDate,
            color: color,
            all_day: allDay,
            due_at: dueAt,
            assignee_name: assignment.assigneeName,
            invite_contact: assignment.inviteContact
        )
    }

    private func resolveAssignment(assignee: TaskAssignee, senderId: UUID) -> (receiverId: UUID?, assigneeName: String?, inviteContact: String?) {
        switch assignee {
        case .myself:
            return (senderId, "Myself", nil)
        case .person(let link):
            if let profileId = link.profileId {
                return (profileId, link.name, nil)
            }
            return (nil, link.name, link.contact)
        }
    }
}

private struct TaskInsertPayload: Encodable {
    let text: String
    let sender_id: UUID
    let receiver_id: UUID?
    let due_date: Date
    let color: StickyColor
    let all_day: Bool
    let due_at: Date?
    let assignee_name: String?
    let invite_contact: String?
}

private struct TaskUpdatePayload: Encodable {
    let text: String
    let receiver_id: UUID?
    let due_date: Date
    let color: StickyColor
    let all_day: Bool
    let due_at: Date?
    let assignee_name: String?
    let invite_contact: String?
}

