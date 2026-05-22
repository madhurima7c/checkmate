import Foundation

/// Who a todo is assigned to at create/edit time.
enum TaskAssignee: Equatable, Identifiable {
    case myself
    case person(FriendLink)

    var id: String {
        switch self {
        case .myself: return "myself"
        case .person(let link): return link.id.uuidString
        }
    }

    var isMyself: Bool {
        if case .myself = self { return true }
        return false
    }

    var displayName: String {
        switch self {
        case .myself: return "Myself"
        case .person(let link): return link.name
        }
    }

    var friendLink: FriendLink? {
        if case .person(let link) = self { return link }
        return nil
    }

    /// Placeholder friends for UI preview in prototype mode.
    static var demoFriends: [FriendLink] {
        [
            FriendLink(name: "Harshit", contact: "harshit@example.com"),
            FriendLink(name: "Sam", contact: "sam@example.com"),
            FriendLink(name: "Priya", contact: "priya@example.com")
        ]
    }

    static func from(task: CheckmateTask) -> TaskAssignee {
        guard task.isAssignedToFriend else { return .myself }
        if let contact = task.inviteContact {
            return .person(FriendLink(name: task.assigneeName ?? "Friend", contact: contact, profileId: task.receiverId))
        }
        return .person(FriendLink(name: task.assigneeName ?? "Friend", contact: task.assigneeName ?? "", profileId: task.receiverId))
    }
}
