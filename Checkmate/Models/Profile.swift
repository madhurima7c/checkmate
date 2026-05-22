import Foundation

struct Profile: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var email: String?
    var apnsToken: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case apnsToken = "apns_token"
    }
}

struct UpsertProfile: Encodable {
    let id: UUID
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, name
    }
}
