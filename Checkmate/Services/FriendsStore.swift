import Foundation

/// Recent assignees + device contacts cache (local until cloud friends graph ships).
@MainActor
final class FriendsStore: ObservableObject {
    static let shared = FriendsStore()

    @Published private(set) var recent: [FriendLink] = []

    private let storageKey = "friend_links_recent"
    private let addTodoCleanupKey = "friend_links_add_todo_cleanup_v1"

    private init() {
        load()
    }

    func cleanAddTodoAssigneesOnce() {
        guard !UserDefaults.standard.bool(forKey: addTodoCleanupKey) else { return }
        recent = []
        save()
        UserDefaults.standard.set(true, forKey: addTodoCleanupKey)
    }

    func remember(_ link: FriendLink) {
        let stored = ContactsService.linkWithContactPhoto(link)
        var list = recent.filter { $0.contact != stored.contact }
        list.insert(stored, at: 0)
        recent = Array(list.prefix(24))
        save()
    }

    func assignablePeople(includeDemos: Bool) -> [FriendLink] {
        var list = recent
        if includeDemos {
            for demo in TaskAssignee.demoFriends where !list.contains(where: { $0.contact == demo.contact }) {
                list.append(demo)
            }
        }
        return list
    }

    /// Pulls contact-card photos for recent assignees when Contacts access is granted.
    func refreshContactPhotos() async {
        guard ContactsService.canReadContacts else { return }
        let snapshot = recent
        let updates = await Task.detached(priority: .utility) {
            snapshot.enumerated().compactMap { index, link -> (Int, Data)? in
                guard link.avatarData == nil,
                      let data = ContactsService.avatarData(matching: link.contact)
                else { return nil }
                return (index, data)
            }
        }.value
        guard !updates.isEmpty else { return }
        var list = snapshot
        for (index, data) in updates {
            list[index].avatarData = data
        }
        recent = list
        save()
    }

    func displayName(forUserId userId: UUID) -> String? {
        for link in assignablePeople(includeDemos: CheckmateConfig.isPrototype) {
            let resolved = link.profileId ?? ContactUserId.placeholder(from: link.contact)
            if resolved == userId { return link.name }
        }
        return nil
    }

    func friendLink(forUserId userId: UUID) -> FriendLink? {
        assignablePeople(includeDemos: CheckmateConfig.isPrototype).first {
            ($0.profileId ?? ContactUserId.placeholder(from: $0.contact)) == userId
        }
    }

    /// Contact photos are re-fetched from the address book; persisting them bloats launch memory.
    private static let maxPersistedStoreBytes = 256_000

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if data.count > Self.maxPersistedStoreBytes {
            UserDefaults.standard.removeObject(forKey: storageKey)
            return
        }
        guard let decoded = try? JSONDecoder().decode([FriendLink].self, from: data) else { return }
        recent = decoded.map(stripAvatarDataForPersistence)
    }

    private func save() {
        let payload = recent.map(stripAvatarDataForPersistence)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func stripAvatarDataForPersistence(_ link: FriendLink) -> FriendLink {
        var copy = link
        copy.avatarData = nil
        return copy
    }
}
