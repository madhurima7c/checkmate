import Foundation

/// A person you can assign todos to — from Contacts, Checkmate, or a pending invite.
struct FriendLink: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    /// Normalized email or E.164 phone used for invites + matching accounts.
    var contact: String
    /// Set when this contact already has a Checkmate profile.
    var profileId: UUID?
    /// Photo bytes from Apple Contacts, when available.
    var avatarData: Data?

    var isOnCheckmate: Bool { profileId != nil }

    /// Chip label — prefer name; fall back to truncated contact.
    var chipLabel: String {
        if !name.isEmpty, !ContactNormalizer.isEmail(name) { return name }
        return ContactNormalizer.displayContact(contact)
    }

    init(id: UUID = UUID(), name: String, contact: String, profileId: UUID? = nil, avatarData: Data? = nil) {
        self.id = id
        self.name = name
        self.contact = ContactNormalizer.normalize(contact)
        self.profileId = profileId
        self.avatarData = avatarData
    }
}

enum ContactNormalizer {
    static func normalize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("@") {
            return trimmed.lowercased()
        }
        let digits = trimmed.filter(\.isNumber)
        return digits.isEmpty ? trimmed : "+\(digits)"
    }

    static func isEmail(_ value: String) -> Bool {
        value.contains("@")
    }

    static func displayContact(_ value: String) -> String {
        if isEmail(value) {
            let local = value.split(separator: "@").first.map(String.init) ?? value
            if local.count <= 10 { return local }
            return String(local.prefix(8)) + "..."
        }
        if value.count <= 12 { return value }
        return String(value.prefix(10)) + "..."
    }
}
