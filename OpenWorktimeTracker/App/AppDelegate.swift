import AppKit
import ServiceManagement
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var updaterController: SPUStandardUpdaterController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Sparkle updater — don't auto-start until a valid feed URL is configured
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
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
