import Foundation

enum CheckmateConfig {
    /// Local-only mode when Supabase isn't configured. Flip automatically once Secrets.plist is filled in.
    static var isPrototype: Bool {
        if UserDefaults.standard.object(forKey: "ForcePrototypeMode") != nil {
            return UserDefaults.standard.bool(forKey: "ForcePrototypeMode")
        }
        return !hasValidSupabaseConfig
    }

    static var hasValidSupabaseConfig: Bool {
        guard let url = supabaseURL, let key = supabaseAnonKey else { return false }
        return !url.absoluteString.contains("YOUR_PROJECT_ID") && !key.hasPrefix("YOUR_")
    }

    static var supabaseURL: URL? {
        Secrets.value(for: "SUPABASE_URL").flatMap(URL.init(string:))
    }

    static var supabaseAnonKey: String? {
        Secrets.value(for: "SUPABASE_ANON_KEY")
    }

    /// Requires paid Apple Developer + Push capability. Code is wired; flip when enrolled.
    static let pushEnabled = false

    static var inviteLinkRoot: URL {
        URL(string: Secrets.value(for: "INVITE_LINK_ROOT") ?? "https://checkmate.app/invite")!
    }

    static let prototypeUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    /// UserDefaults — Settings → DialKit sandbox toggles.
    enum DialKit {
        static let cardFocusKey = "dialkit.cardFocus.enabled"
        static let homePageKey = "dialkit.homePage.enabled"
        static let todoSheetKey = "dialkit.todoSheet.enabled"
        static let onboardingKey = "dialkit.onboarding.enabled"
    }

    /// UserDefaults — onboarding flow. Cleared via Settings → Onboarding → Restart.
    enum Onboarding {
        static let completedKey = "onboarding.completed"
    }
}

enum Secrets {
    static func value(for key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = dict[key] as? String,
              !value.isEmpty
        else { return nil }
        return value
    }
}
