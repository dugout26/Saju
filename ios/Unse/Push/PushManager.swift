@preconcurrency import UserNotifications
import UIKit
@preconcurrency import Supabase
import FirebaseCore
import FirebaseMessaging
import FirebaseCrashlytics

@MainActor
final class PushManager: NSObject {

    static let shared = PushManager()
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
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
            Crashlytics.crashlytics().record(error: error)
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

    /// APNs token을 받으면 Firebase Messaging에 등록.
    /// Firebase가 APNs token → FCM token 변환 후 messaging(_:didReceiveRegistrationToken:)으로 전달.
    func handleDeviceToken(_ tokenData: Data) {
        Messaging.messaging().apnsToken = tokenData
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
        // FCM payload는 userInfo에 들어옴.
        // type == "open_store"면 App Store 또는 Play Store 열기 (강제 업데이트 알림 등)
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String, type == "open_store",
           let urlStr = userInfo["url"] as? String,
           let url = URL(string: urlStr) {
            await MainActor.run { UIApplication.shared.open(url) }
            return
        }

        // 기본: 매일 운세 화면으로 deeplink
        await MainActor.run {
            NotificationCenter.default.post(name: .didTapPushNotification, object: nil)
        }
    }
}

// MARK: - MessagingDelegate (FCM token 수신)

extension PushManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        UserDefaults.standard.set(fcmToken, forKey: "fcm_token")
        Task { @MainActor in
            guard let userId = try? await SupabaseManager.shared.auth.session.user.id else { return }
            struct Update: Encodable { let push_token: String }
            _ = try? await SupabaseManager.shared
                .from("users")
                .update(Update(push_token: fcmToken))
                .eq("id", value: userId)
                .execute()
        }
    }
}

extension Notification.Name {
    static let didTapPushNotification = Notification.Name("didTapPushNotification")
}
