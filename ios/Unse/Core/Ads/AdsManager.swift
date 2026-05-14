@preconcurrency import GoogleMobileAds
import SwiftUI
import UIKit

// MARK: - AdsManager (SDK init + 광고 단위 ID)

@MainActor
enum AdsManager {
    // DEBUG: Google 공식 테스트 광고 단위 ID (publisher 3940256099942544 = Google sandbox).
    //        실제 광고 단위로 디버그 빌드에서 호출 시 'no fill' + 정책 위반으로 계정 정지 위험.
    //        https://developers.google.com/admob/ios/test-ads
    // RELEASE: 실제 광고 단위 ID (publisher 6728704748176389 = 사용자 본인).
    #if DEBUG
    static let bannerUnitId   = "ca-app-pub-3940256099942544/2934735716"
    static let rewardedUnitId = "ca-app-pub-3940256099942544/1712485313"
    #else
    static let bannerUnitId   = "ca-app-pub-6728704748176389/8622581309"
    static let rewardedUnitId = "ca-app-pub-6728704748176389/8918094770"
    #endif

    /// 앱 시작 시 1회 호출.
    static func start() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}

// MARK: - BannerAdView (SwiftUI wrapper of GADBannerView)

struct BannerAdView: UIViewRepresentable {
    let unitId: String

    func makeUIView(context: Context) -> GADBannerView {
        let view = GADBannerView(adSize: GADAdSizeBanner)   // 320x50 standard banner
        view.adUnitID = unitId
        view.rootViewController = topViewController()
        view.load(GADRequest())
        return view
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        uiView.rootViewController = topViewController()
    }

    private func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first { $0.isKeyWindow }?.rootViewController
    }
}

// MARK: - RewardedAdPresenting (testable abstraction)

/// ViewModel은 이 protocol에만 의존 — test에서 mock 주입 가능.
@MainActor
protocol RewardedAdPresenting {
    func loadAndShow(unitId: String, onReward: @escaping () -> Void)
}

// MARK: - RewardedAdLoader (보상형 광고 — 실 SDK 구현)

@MainActor
final class RewardedAdLoader: NSObject, RewardedAdPresenting {
    private var rewarded: GADRewardedAd?
    private var onReward: (() -> Void)?

    func loadAndShow(unitId: String, onReward: @escaping () -> Void) {
        self.onReward = onReward
        Task {
            do {
                rewarded = try await GADRewardedAd.load(withAdUnitID: unitId, request: GADRequest())
                guard let rewarded, let presenter = topViewController() else { return }
                rewarded.present(fromRootViewController: presenter) { [weak self] in
                    self?.onReward?()
                    self?.rewarded = nil
                }
            } catch {
                print("[Ads] rewarded load failed: \(error)")
            }
        }
    }

    private func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first { $0.isKeyWindow }?.rootViewController
    }
}
