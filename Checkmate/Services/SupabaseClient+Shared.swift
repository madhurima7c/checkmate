import Foundation
import Supabase

extension SupabaseClient {
    static let shared: SupabaseClient = {
        let url = CheckmateConfig.supabaseURL ?? URL(string: "https://placeholder.supabase.co")!
        let key = CheckmateConfig.supabaseAnonKey ?? "placeholder"
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }()
}
