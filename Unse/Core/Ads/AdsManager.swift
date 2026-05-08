@preconcurrency import GoogleMobileAds
import SwiftUI
import UIKit

// MARK: - AdsManager (SDK init + 광고 단위 ID)

@MainActor
enum AdsManager {
    static let bannerUnitId   = "ca-app-pub-6728704748176389/8622581309"
    static let rewardedUnitId = "ca-app-pub-6728704748176389/8918094770"

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

// MARK: - RewardedAdLoader (보상형 광고)

@MainActor
final class RewardedAdLoader: NSObject {
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
