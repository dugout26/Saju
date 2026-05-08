import SwiftUI
import SwiftData
import KakaoSDKCommon
import KakaoSDKAuth
import FirebaseCore
import FirebaseCrashlytics
import AppTrackingTransparency

@main
struct UnseApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var subscription = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            rootContent
                .environment(subscription)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
        .modelContainer(AppModelContainer.shared)
    }

    @ViewBuilder
    private var rootContent: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-preview-saju") {
                let input = BirthInput(year: 1990, month: 3, day: 15, hour: 12, minute: 0, gender: .male, nickname: "테스트")
                let result = Manse.calculate(year: input.year, month: input.month, day: input.day, hour: input.hour, gender: input.gender)
                let profile = SajuProfile(input: input, saju: result.saju, daeWoon: result.daeWoon)
                if let restored = profile.computed {
                    NavigationStack {
                        SajuResultView(saju: restored, daeWoon: profile.daeWoon, nickname: input.nickname)
                    }
                } else {
                    Text("Reconstruction 실패")
                }
        } else {
            RootView()
        }
        #else
        RootView()
        #endif
    }

    #if DEBUG
    @MainActor
    private static func makePreviewUser() -> UserProfile {
        let input = BirthInput(year: 1990, month: 3, day: 15, hour: 12, minute: 0, gender: .male, nickname: "테스트")
        let result = Manse.calculate(year: input.year, month: input.month, day: input.day, hour: input.hour, gender: input.gender)
        let user = UserProfile(nickname: input.nickname, authProvider: "apple")
        user.sajuProfile = SajuProfile(input: input, saju: result.saju, daeWoon: result.daeWoon)
        return user
    }
    #endif
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase 초기화 (FCM + Crashlytics 사용을 위해 가장 먼저).
        // GoogleService-Info.plist 부재 시(CI/test) configure가 assertion → 가드.
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
            // Crashlytics는 FirebaseApp.configure 후 자동 시작. 명시적 참조로 활성 보장.
            _ = Crashlytics.crashlytics()
        }
        // Kakao SDK 초기화 (Info.plist의 KAKAO_APP_KEY 사용). 빈 키면 skip.
        let kakaoKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String ?? ""
        if !kakaoKey.isEmpty {
            KakaoSDK.initSDK(appKey: kakaoKey)
        }
        // AdMob 초기화
        AdsManager.start()
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
    @Environment(\.scenePhase) private var scenePhase
    @Query private var users: [UserProfile]
    @State private var appConfig: AppConfigDTO?
    @State private var refreshedUser: UserProfile?

    // SwiftData iOS 18 FutureBackingData mitigation —
    // bg→fg 복귀 시 @Model의 relationship backing data가 swap되어
    // user.sajuProfile 접근 시 fatal error 발생. PersistentIdentifier로
    // 재조회한 인스턴스는 fresh backing data로 복원됨.
    private var currentUser: UserProfile? {
        refreshedUser ?? users.first
    }

    var body: some View {
        ZStack {
            if let user = currentUser {
                MainTabView(user: user)
            } else {
                OnboardingView()
            }

            if let cfg = appConfig, cfg.requiresForceUpdate() {
                ForceUpdateView(message: cfg.force_update_message, storeURL: cfg.app_store_url)
            }
        }
        .task {
            appConfig = try? await APIClient.shared.fetchAppConfig()
            // 로그인된 사용자에게 알림 권한 자동 요청 (한 번만, system이 알아서 dedupe)
            if users.first != nil {
                _ = await PushManager.shared.requestPermission()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active,
                  let id = users.first?.persistentModelID else { return }
            refreshedUser = modelContext.model(for: id) as? UserProfile
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

            sajuTab

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
        // ATT prompt — 로그인 + 온보딩 완료 후 main tab 진입 시 한 번 호출.
        // .notDetermined 상태에서만 prompt (Apple은 거부 후 재요청 불가).
        // AdMob personalized ads 활성화에 IDFA 필요. 거부 시 non-personalized로 fallback.
        .task {
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                _ = await ATTrackingManager.requestTrackingAuthorization()
            }
        }
    }

    @ViewBuilder
    private var sajuTab: some View {
        Group {
            if let profile = user.sajuProfile, let saju = profile.computed {
                SajuResultView(saju: saju, daeWoon: profile.daeWoon, nickname: user.nickname)
            } else {
                Text("사주 정보가 없습니다")
            }
        }
        .tabItem {
            Label("사주", systemImage: "square.grid.2x2")
        }
    }
}
