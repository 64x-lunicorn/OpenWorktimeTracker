import AppKit
import ServiceManagement
import Sparkle
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var updaterController: SPUStandardUpdaterController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set notification delegate so banners show for this menu bar app
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self

        // Request notification permission early at launch
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("[Notifications] Permission error: \(error.localizedDescription)")
            }
            print("[Notifications] Permission granted: \(granted)")
        }

        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Register launch at login if first launch
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            setLaunchAtLogin(true)
        }
    }

    // MARK: - Launch at Login

    static func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            UserDefaults.standard.set(enabled, forKey: AppSettingsKey.launchAtLogin)
        } catch {
            // Registration can fail silently — the toggle will reflect actual state
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        Self.setLaunchAtLogin(enabled)
    }

    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    // MARK: - Sparkle

    var updater: SPUUpdater {
        updaterController.updater
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
