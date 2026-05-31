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
        var list = recent
        var changed = false
        for index in list.indices where list[index].avatarData == nil {
            if let data = ContactsService.avatarData(matching: list[index].contact) {
                list[index].avatarData = data
                changed = true
            }
        }
        guard changed else { return }
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

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FriendLink].self, from: data)
        else { return }
        recent = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(recent) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
