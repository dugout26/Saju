import UserNotifications
import UIKit

@MainActor
final class PushManager: NSObject {

    static let shared = PushManager()
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            return false
        }
    }

    var isAuthorized: Bool {
        get async {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Token Registration

    func handleDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        Task {
            // Send token to server for APNs push delivery
            // APIClient.shared.registerPushToken(token, userId: currentUserId)
            UserDefaults.standard.set(token, forKey: "apns_device_token")
        }
    }

    // MARK: - Local Notification (fallback / testing)

    func scheduleDailyFortunePush(at time: Date, nickname: String) async {
        await UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let cal = Calendar.current
        var comps = cal.dateComponents([.hour, .minute], from: time)
        comps.second = 0

        let content = UNMutableNotificationContent()
        content.title = "운세"
        content.body = "☀️ \(nickname)님, 오늘의 행운 색을 확인해보세요"
        content.sound = .default
        content.badge = 1

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-fortune",
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Deep-link to DailyFortuneView on tap
        await MainActor.run {
            NotificationCenter.default.post(
                name: .didTapPushNotification,
                object: nil
            )
        }
    }
}

extension Notification.Name {
    static let didTapPushNotification = Notification.Name("didTapPushNotification")
}
