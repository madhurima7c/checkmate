import Foundation

struct CheckmateTask: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    let senderId: UUID
    var receiverId: UUID?
    var dueDate: Date
    var status: TaskStatus
    var isSeen: Bool
    var color: StickyColor
    var allDay: Bool
    var dueAt: Date?
    let createdAt: Date
    /// Display name for assignee ("Myself", friend name, etc.).
    var assigneeName: String?
    /// Normalized email/phone when assigned before they have an account.
    var inviteContact: String?
    /// Populated in App Group snapshot for widget avatars (not synced to cloud).
    var widgetAvatarName: String?
    var widgetAvatarImageData: Data?

    var isPersonal: Bool { receiverId == nil || receiverId == senderId }

    var isOverdue: Bool { dueDate < Calendar.current.startOfDay(for: Date()) }

    func wasAssignedToMe(currentUserId: UUID?) -> Bool {
        guard let currentUserId, let receiverId else { return false }
        return receiverId == currentUserId && senderId != currentUserId
    }

    func isOutgoingToFriend(currentUserId: UUID) -> Bool {
        guard senderId == currentUserId else { return false }
        if inviteContact != nil { return true }
        guard let receiverId else { return false }
        return receiverId != currentUserId
    }

    func isIncomingFromOther(currentUserId: UUID) -> Bool {
        guard receiverId == currentUserId else { return false }
        return senderId != currentUserId
    }

    /// Legacy helper — prefer `isOutgoingToFriend(currentUserId:)`.
    func isAssignedToFriend(currentUserId: UUID) -> Bool {
        isOutgoingToFriend(currentUserId: currentUserId)
    }

    func isNew(currentUserId: UUID) -> Bool {
        !isSeen && isIncomingFromOther(currentUserId: currentUserId)
    }

    enum CodingKeys: String, CodingKey {
        case id, text, status, color
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case dueDate = "due_date"
        case isSeen = "is_seen"
        case allDay = "all_day"
        case dueAt = "due_at"
        case createdAt = "created_at"
        case assigneeName = "assignee_name"
        case inviteContact = "invite_contact"
        case widgetAvatarName = "widget_avatar_name"
        case widgetAvatarImageData = "widget_avatar_image_data"
    }
}

enum TaskStatus: String, Codable {
    case pending, done
}

struct NewTask: Encodable {
    let text: String
    let senderId: UUID
    let receiverId: UUID?
    let dueDate: Date
    let color: StickyColor
    let allDay: Bool
    let dueAt: Date?

    enum CodingKeys: String, CodingKey {
        case text, color
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case dueDate = "due_date"
        case allDay = "all_day"
        case dueAt = "due_at"
    }
}

extension Date {
    static var today: Date { Calendar.current.startOfDay(for: Date()) }

    func startOfDay() -> Date { Calendar.current.startOfDay(for: self) }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
