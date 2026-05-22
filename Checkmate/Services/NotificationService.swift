import UIKit
import UserNotifications
import Supabase

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async {
        guard CheckmateConfig.pushEnabled else {
            print("Push disabled until paid Apple Developer account (CheckmateConfig.pushEnabled).")
            return
        }
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func uploadToken(_ tokenData: Data) async {
        guard let userId = await AuthService.shared.currentUserId else { return }
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        do {
            try await SupabaseClient.shared
                .from("profiles")
                .update(["apns_token": token])
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            print("APNs token upload error: \(error)")
        }
    }
}
