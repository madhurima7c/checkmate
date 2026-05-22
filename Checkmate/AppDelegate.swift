import UIKit

/// Push token hooks — active once `CheckmateConfig.pushEnabled` is true (paid Apple account).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        guard CheckmateConfig.pushEnabled else { return }
        Task { await NotificationService.shared.uploadToken(deviceToken) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Expected on Simulator and free Personal Team accounts.
        print("APNs registration unavailable: \(error.localizedDescription)")
    }
}
