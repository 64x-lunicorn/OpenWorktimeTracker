import AppKit
import Observation
import ServiceManagement
import Sparkle
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var updaterController: SPUStandardUpdaterController!
    var workdayManager: WorkdayManager?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        guard let workdayManager else {
            preconditionFailure("WorkdayManager must be configured before application launch")
        }
        menuBarController = MenuBarController(manager: workdayManager)
        NSApp.mainMenu = makeMainMenu()
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

    @MainActor
    func makeMainMenu() -> NSMenu {
        let menu = NSMenu()
        let appMenu = NSMenu()
        let appItem = menu.addItem(withTitle: "OpenWorktimeTracker", action: nil, keyEquivalent: "")
        appItem.submenu = appMenu
        let settings = appMenu.addItem(
            withTitle: String(localized: "menubar.settings"), action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: String(localized: "menubar.quit"),
            action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q").target = NSApp

        let editMenu = NSMenu(title: String(localized: "menu.edit"))
        menu.addItem(withTitle: editMenu.title, action: nil, keyEquivalent: "").submenu = editMenu
        for (title, action, key) in [
            ("menu.undo", "undo:", "z"), ("menu.redo", "redo:", "Z"),
            ("menu.cut", "cut:", "x"), ("menu.copy", "copy:", "c"),
            ("menu.paste", "paste:", "v"), ("menu.selectAll", "selectAll:", "a")
        ] {
            editMenu.addItem(
                withTitle: NSLocalizedString(title, comment: ""),
                action: Selector(action), keyEquivalent: key)
        }
        let windowMenu = NSMenu(title: String(localized: "menu.window"))
        menu.addItem(withTitle: windowMenu.title, action: nil, keyEquivalent: "").submenu = windowMenu
        windowMenu.addItem(
            withTitle: String(localized: "menu.close"),
            action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        return menu
    }

    @MainActor @objc private func openSettings() {
        menuBarController?.showSettings()
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

/// Keeps mouse handling in AppKit rather than in a hosted SwiftUI menu-bar label.
@MainActor
final class MenuBarController: NSObject {
    let statusItem: NSStatusItem
    let popover = NSPopover()
    private let manager: WorkdayManager
    private var settingsWindow: NSWindow?

    init(manager: WorkdayManager) {
        self.manager = manager
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        let content = MenuBarView(onOpenSettings: { [weak self] in self?.showSettings() })
            .environment(manager)
        popover.contentViewController = NSHostingController(rootView: content)
        popover.contentSize = NSSize(
            width: DesignTokens.popoverWidth, height: DesignTokens.popoverMinHeight)
        popover.behavior = .transient
        popover.animates = false
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: .leftMouseUp)
            button.imagePosition = .imageLeading
            button.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }
        updateStatus()
    }

    deinit {
        let item = statusItem
        DispatchQueue.main.async {
            NSStatusBar.system.removeStatusItem(item)
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateStatus() {
        withObservationTracking {
            let button = statusItem.button
            let icon: String
            switch manager.state {
            case .notStarted: icon = "clock"
            case .running: icon = "clock.fill"
            case .paused: icon = "pause.circle"
            case .ended: icon = "checkmark.circle"
            }
            button?.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
            let color: NSColor = manager.thresholdLevel == .normal
                ? .labelColor : NSColor(manager.thresholdLevel.accent)
            button?.contentTintColor = color
            button?.attributedTitle = NSAttributedString(
                string: manager.menuBarTitle, attributes: [.foregroundColor: color])
            button?.toolTip = String(localized: "timer.accessibility.netWorkTime")
                + ": " + manager.menuBarTitle + " - " + manager.state.localizedLabel
            button?.setAccessibilityLabel(button?.toolTip)
        } onChange: { [weak self] in
            DispatchQueue.main.async { [weak self] in self?.updateStatus() }
        }
    }

    func showSettings() {
        popover.performClose(nil)
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 520),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered, defer: false)
            window.title = String(localized: "menubar.settings")
            window.contentViewController = NSHostingController(
                rootView: SettingsView().environment(manager))
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
