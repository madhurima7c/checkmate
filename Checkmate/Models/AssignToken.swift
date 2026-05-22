import Foundation

// Represents a single chip in the AddTodo "Assign to" row.
// Carries enough info to resolve into a Profile id at submit time, or to
// create a pending invite when the contact isn't on Checkmate yet.
enum AssignToken: Identifiable, Hashable {
    case me
    case friend(Profile)
    case invite(name: String, contact: String) // contact = phone or email

    var id: String {
        switch self {
        case .me: return "me"
        case .friend(let p): return "friend:\(p.id.uuidString)"
        case .invite(_, let c): return "invite:\(c)"
        }
    }

    var displayName: String {
        switch self {
        case .me: return "Myself"
        case .friend(let p): return p.name
        case .invite(let name, _): return name
        }
    }

    @MainActor
    var profileId: UUID? {
        switch self {
        case .me: return AuthService.shared.currentUserId
        case .friend(let p): return p.id
        case .invite: return nil
        }
    }
}
