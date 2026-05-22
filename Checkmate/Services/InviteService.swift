import SwiftUI
import UIKit
import Supabase

@MainActor
final class InviteService {
    static let shared = InviteService()
    private init() {}

    /// Persist invite row keyed by email/phone so we can attach tasks when they sign up.
    func recordInvite(for link: FriendLink) async throws {
        guard let inviter = AuthService.shared.currentUserId else { return }

        struct NewInvite: Encodable {
            let inviter_id: UUID
            let contact: String
            let name: String
        }
        let body = NewInvite(inviter_id: inviter, contact: link.contact, name: link.name)

        _ = try? await SupabaseClient.shared
            .from("invites")
            .insert(body)
            .execute()
    }

    /// Share sheet after assigning to someone not on Checkmate yet.
    func presentAssignInvite(for link: FriendLink, taskText: String) async {
        var token = UUID().uuidString
        if TaskStore.shared.usesCloud, let inviter = AuthService.shared.currentUserId {
            struct NewInvite: Encodable {
                let inviter_id: UUID
                let contact: String
                let name: String
            }
            struct Inserted: Decodable { let id: UUID }
            let body = NewInvite(inviter_id: inviter, contact: link.contact, name: link.name)
            if let rows: [Inserted] = try? await SupabaseClient.shared
                .from("invites")
                .insert(body)
                .select()
                .execute()
                .value,
               let first = rows.first {
                token = first.id.uuidString
            }
        }

        let linkURL = CheckmateConfig.inviteLinkRoot.appendingPathComponent(token)
        let message = """
        \(AuthService.shared.currentProfile?.name ?? "Someone") assigned you a todo on Checkmate:
        “\(taskText)”
        """
        present(items: [message, linkURL])
    }

    func presentInviteShareSheet() async {
        guard AuthService.shared.currentUserId != nil else { return }
        await presentAssignInvite(
            for: FriendLink(name: "Friend", contact: "friend@example.com"),
            taskText: "Join me on Checkmate"
        )
    }

    private func present(items: [Any]) {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first?.rootViewController
        else { return }

        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(vc, animated: true)
    }
}
