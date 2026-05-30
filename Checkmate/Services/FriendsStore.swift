import Foundation

/// Recent assignees + device contacts cache (local until cloud friends graph ships).
@MainActor
final class FriendsStore: ObservableObject {
    static let shared = FriendsStore()

    @Published private(set) var recent: [FriendLink] = []

    private let storageKey = "friend_links_recent"

    private init() {
        load()
    }

    func remember(_ link: FriendLink) {
        var list = recent.filter { $0.contact != link.contact }
        list.insert(link, at: 0)
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
