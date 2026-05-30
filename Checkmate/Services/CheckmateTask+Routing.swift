import Foundation

@MainActor
extension CheckmateTask {
    static var localUserId: UUID {
        AuthService.shared.currentUserId ?? CheckmateConfig.prototypeUserId
    }

    var isOutgoingToFriend: Bool {
        isOutgoingToFriend(currentUserId: Self.localUserId)
    }

    var isIncomingFromOther: Bool {
        isIncomingFromOther(currentUserId: Self.localUserId)
    }

    var isAssignedToFriend: Bool { isOutgoingToFriend }

    var isNew: Bool { isNew(currentUserId: Self.localUserId) }
}
