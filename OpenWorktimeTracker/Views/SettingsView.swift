import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Environment(WorkdayManager.self) private var manager

    // Appearance
    @AppStorage(AppSettingsKey.orangeThresholdHours) private var orangeThreshold = AppDefaults
        .orangeThresholdHours
    @AppStorage(AppSettingsKey.redThresholdHours) private var redThreshold = AppDefaults
        .redThresholdHours

    // ArbZG Breaks
    @AppStorage(AppSettingsKey.breakAfter6hMinutes) private var break6h = AppDefaults
        .breakAfter6hMinutes
    @AppStorage(AppSettingsKey.breakAfter9hMinutes) private var break9h = AppDefaults
        .breakAfter9hMinutes

    // Notifications
    @AppStorage(AppSettingsKey.notificationsEnabled) private var notificationsEnabled = AppDefaults
        .notificationsEnabled
    @AppStorage(AppSettingsKey.normalNotificationHours) private var normalHours = AppDefaults
        .normalNotificationHours
    @AppStorage(AppSettingsKey.criticalNotificationHours) private var criticalHours = AppDefaults
        .criticalNotificationHours
    @AppStorage(AppSettingsKey.milestoneNotificationHours) private var milestoneHours = AppDefaults
        .milestoneNotificationHours

    // Idle
    @AppStorage(AppSettingsKey.idleThresholdMinutes) private var idleThreshold = AppDefaults
        .idleThresholdMinutes

    // Startup
    @State private var launchAtLogin = AppDelegate.isLaunchAtLoginEnabled

    // Cloud
    @AppStorage(AppSettingsKey.iCloudSyncEnabled) private var iCloudSync = AppDefaults
        .iCloudSyncEnabled

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("settings.general", systemImage: "gear")
                }

            notificationsTab
                .tabItem {
                    Label("settings.notifications", systemImage: "bell")
                }

            dataTab
                .tabItem {
                    Label("settings.data", systemImage: "folder")
                }
        }
        .frame(width: 450, height: 350)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section(String(localized: "settings.appearance")) {
                HStack {
                    Text("settings.orangeThreshold")
                    Spacer()
                    TextField("", value: $orangeThreshold, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: orangeThreshold) { _, newValue in
                            orangeThreshold = max(0, newValue)
                            if orangeThreshold >= redThreshold {
                                redThreshold = orangeThreshold + 0.5
                            }
                        }
                }
                HStack {
                    Text("settings.redThreshold")
                    Spacer()
                    TextField("", value: $redThreshold, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: redThreshold) { _, newValue in
                            redThreshold = max(0.5, newValue)
                            if redThreshold <= orangeThreshold {
                                orangeThreshold = redThreshold - 0.5
                            }
                        }
                }
            }

            Section(String(localized: "settings.autoBreak")) {
                HStack {
                    Text("settings.breakAfter6h")
                    Spacer()
                    TextField("", value: $break6h, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: break6h) { _, newValue in
                            break6h = max(0, min(300, newValue))
                        }
                }
                HStack {
                    Text("settings.breakAfter9h")
                    Spacer()
                    TextField("", value: $break9h, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: break9h) { _, newValue in
                            break9h = max(0, min(300, newValue))
                            if break9h < break6h {
                                break9h = break6h
                            }
                        }
                }
            }

            Section(String(localized: "settings.idleDetection")) {
                HStack {
                    Text("settings.idleThreshold")
                    Spacer()
                    TextField("", value: $idleThreshold, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: idleThreshold) { _, newValue in
                            idleThreshold = max(1, newValue)
                        }
                }
            }

            Section(String(localized: "settings.startup")) {
                Toggle(String(localized: "settings.launchAtLogin"), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        AppDelegate.setLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Notifications Tab

    private var notificationsTab: some View {
        Form {
            Section {
                Toggle(
                    String(localized: "settings.enableNotifications"), isOn: $notificationsEnabled)
            }

            Section(String(localized: "settings.thresholds")) {
                HStack {
                    Text("settings.normalHours")
                    Spacer()
                    TextField("", value: $normalHours, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: normalHours) { _, newValue in
                            normalHours = max(0.5, newValue)
                        }
                }
                HStack {
                    Text("settings.criticalHours")
                    Spacer()
                    TextField("", value: $criticalHours, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: criticalHours) { _, newValue in
                            criticalHours = max(normalHours, newValue)
                        }
                }
                HStack {
                    Text("settings.milestoneHours")
                    Spacer()
                    TextField("", value: $milestoneHours, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: milestoneHours) { _, newValue in
                            milestoneHours = max(criticalHours, newValue)
                        }
                }
            }

            Text("settings.notificationHelp")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    // MARK: - Data Tab

    private var dataTab: some View {
        Form {
            Section(String(localized: "settings.logs")) {
                HStack {
                    Button(String(localized: "settings.openLogFolder")) {
                        NSWorkspace.shared.open(manager.persistence.logDirectory)
                    }

                    Button(String(localized: "settings.chooseLogFolder")) {
                        chooseLogFolder()
                    }
                }
            }

            Section(String(localized: "settings.cloudSync")) {
                Toggle(String(localized: "settings.syncICloud"), isOn: $iCloudSync)
                    .onChange(of: iCloudSync) { _, newValue in
                        if newValue {
                            manager.persistence.syncWithCloud()
                        }
                    }

                if iCloudSync {
                    if CloudSyncManager.shared.iCloudAvailable {
                        Label("settings.iCloudConnected", systemImage: "checkmark.icloud")
                            .foregroundStyle(.secondary)
                            .font(.caption)

                        Button(String(localized: "settings.syncNow")) {
                            manager.persistence.syncWithCloud()
                        }
                    } else {
                        Label(
                            String(localized: "settings.iCloudUnavailable"),
                            systemImage: "exclamationmark.icloud"
                        )
                        .foregroundStyle(.orange)
                        .font(.caption)
                    }
                }
            }

            Section(String(localized: "settings.export")) {
                Button(String(localized: "settings.exportCSV")) {
                    if let url = manager.persistence.exportCSV() {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            Section(String(localized: "settings.about")) {
                HStack {
                    Text("settings.version")
                    Spacer()
                    Text(
                        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
                            as? String ?? "?"
                    )
                    .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Helpers

    private func chooseLogFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "settings.choosePrompt")
        panel.message = String(localized: "settings.chooseMessage")

        if panel.runModal() == .OK, let url = panel.url {
            manager.persistence.setCustomLogFolder(url)
        }
    }
}
