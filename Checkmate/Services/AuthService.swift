import Foundation
import AuthenticationServices
import Supabase

@MainActor
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUserId: UUID?
    @Published var currentProfile: Profile?

    private override init() {
        super.init()
        Task { await checkSession() }
    }

    private func checkSession() async {
        do {
            let session = try await SupabaseClient.shared.auth.session
            isAuthenticated = true
            currentUserId = UUID(uuidString: session.user.id.uuidString)
            await loadProfile()
        } catch {
            isAuthenticated = false
        }
    }

    // MARK: - Sign in with Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.missingToken
        }
        let session = try await SupabaseClient.shared.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: token,
                nonce: nil
            )
        )
        isAuthenticated = true
        currentUserId = UUID(uuidString: session.user.id.uuidString)
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }.joined(separator: " ")
        if !name.isEmpty {
            try await upsertProfile(name: name)
        }
        await loadProfile()
    }

    // MARK: - Email auth

    func signUp(email: String, password: String, name: String) async throws {
        let session = try await SupabaseClient.shared.auth.signUp(
            email: email, password: password
        )
        isAuthenticated = true
        currentUserId = UUID(uuidString: session.user.id.uuidString)
        try await upsertProfile(name: name)
        await loadProfile()
    }

    func signIn(email: String, password: String) async throws {
        let session = try await SupabaseClient.shared.auth.signIn(
            email: email, password: password
        )
        isAuthenticated = true
        currentUserId = UUID(uuidString: session.user.id.uuidString)
        await loadProfile()
    }

    func signOut() async throws {
        try await SupabaseClient.shared.auth.signOut()
        isAuthenticated = false
        currentUserId = nil
        currentProfile = nil
    }

    // MARK: - Profile

    private func upsertProfile(name: String) async throws {
        guard let userId = currentUserId else { return }
        try await SupabaseClient.shared
            .from("profiles")
            .upsert(UpsertProfile(id: userId, name: name))
            .execute()
    }

    private func loadProfile() async {
        guard let userId = currentUserId else { return }
        let profiles: [Profile] = (try? await SupabaseClient.shared
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value) ?? []
        currentProfile = profiles.first
    }
}

enum AuthError: Error {
    case missingToken
}
