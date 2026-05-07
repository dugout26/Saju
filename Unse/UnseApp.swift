import SwiftUI
import SwiftData
import KakaoSDKCommon

@main
struct UnseApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            UserProfile.self,
            SajuProfile.self,
            DailyFortune.self,
            ChatMessage.self,
            SajuReading.self,
        ])
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Kakao SDK 초기화 (Info.plist의 KAKAO_APP_KEY 사용)
        let kakaoKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String ?? ""
        KakaoSDK.initSDK(appKey: kakaoKey)
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushManager.shared.handleDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[Push] registration failed: \(error.localizedDescription)")
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        return false
    }
}

// MARK: - RootView

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserProfile]

    var body: some View {
        if let user = users.first {
            MainTabView(user: user)
        } else {
            OnboardingView()
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    let user: UserProfile

    var body: some View {
        TabView {
            DailyFortuneView(user: user)
                .tabItem {
                    Label("오늘", systemImage: "sun.max")
                }

            SajuResultView(user: user)
                .tabItem {
                    Label("사주", systemImage: "square.grid.2x2")
                }

            TimelineView(user: user)
                .tabItem {
                    Label("평생운", systemImage: "chart.line.uptrend.xyaxis")
                }

            ChatView(user: user)
                .tabItem {
                    Label("챗봇", systemImage: "bubble.left.and.bubble.right")
                }

            SettingsView(user: user)
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
        }
        .tint(.lavenderDeep)
    }
}
