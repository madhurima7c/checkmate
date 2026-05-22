import Foundation
import Supabase

@MainActor
enum FriendLookupService {
    /// Resolve a contact email to an existing Checkmate profile (when signed in + cloud).
    static func profile(for contact: String) async -> Profile? {
        guard TaskStore.shared.usesCloud,
              ContactNormalizer.isEmail(contact)
        else { return nil }

        let normalized = ContactNormalizer.normalize(contact)
        let profiles: [Profile] = (try? await SupabaseClient.shared
            .from("profiles")
            .select()
            .eq("email", value: normalized)
            .limit(1)
            .execute()
            .value) ?? []
        return profiles.first
    }

    static func enrich(_ link: FriendLink) async -> FriendLink {
        guard let profile = await profile(for: link.contact) else { return link }
        var updated = link
        updated.profileId = profile.id
        updated.name = profile.name
        return updated
    }
}
