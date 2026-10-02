import AppTrackingTransparency
#if canImport(AdmobSwiftUI)
import AdmobSwiftUI
#endif

/// Manages flags determining how ads and app review requests behave
@MainActor
final class ExperienceManager {

    static let shared = ExperienceManager()

    /// Milestones (by documents closed) at which to ask for an App Store review.
    let documentsClosedCountsToAskForReview = [5, 20, 50, 100]

    var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined

    #if canImport(AdmobSwiftUI)
    private var adsStarted = false

    /// Asks for tracking consent, then starts the Google Mobile Ads SDK — never the reverse, as the
    /// SDK collects device data the moment it starts. Does nothing until the person qualifies for ads,
    /// so the prompt arrives alongside the first ad rather than on first launch. Call once the scene
    /// is active: the system silently skips the prompt otherwise, so an undetermined result waits
    /// for the next activation.
    func requestTrackingThenStartAds() async {
        guard !adsStarted, qualifiesForAds, !ScreenshotMode.isActive else { return }
        trackingAuthorizationStatus = await ATTrackingManager.requestTrackingAuthorization()
        guard trackingAuthorizationStatus != .notDetermined else { return }
        adsStarted = true
        AdmobSwiftUI.initialize()
    }

    private var qualifiesForAds: Bool {
        #if DEBUG
        true
        #else
        // Enable ads only after the 1st app review request, so brand-new
        // people get a clean experience and ads ramp with engagement.
        UserDefaults.standard.integer(forKey: UserDefaults.Key.documentsClosedCount) > documentsClosedCountsToAskForReview.first!
        #endif
    }
    #endif

    var shouldShowAds: Bool {
        #if canImport(AdmobSwiftUI)
        // Loading an ad would start the SDK itself, ahead of the tracking prompt
        guard adsStarted else { return false }
        #if DEBUG
        // Devices running debug builds should expose their tracking ID to Google to meet TOS
        return trackingAuthorizationStatus == .authorized
        #else
        return true
        #endif
        #else
        return false
        #endif
    }

}
