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

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            notificationsTab
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            dataTab
                .tabItem {
                    Label("Data", systemImage: "folder")
                }
        }
        .frame(width: 450, height: 350)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section("Appearance") {
                HStack {
                    Text("Orange threshold (h)")
                    Spacer()
                    TextField("", value: $orangeThreshold, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Red threshold (h)")
                    Spacer()
                    TextField("", value: $redThreshold, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Auto Break (ArbZG)") {
                HStack {
                    Text("Break after > 6h (min)")
                    Spacer()
                    TextField("", value: $break6h, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Break after > 9h (min)")
                    Spacer()
                    TextField("", value: $break9h, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Idle Detection") {
                HStack {
                    Text("Idle threshold (min)")
                    Spacer()
                    TextField("", value: $idleThreshold, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
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
                Toggle("Enable notifications", isOn: $notificationsEnabled)
            }

            Section("Thresholds") {
                HStack {
                    Text("Normal (h)")
                    Spacer()
                    TextField("", value: $normalHours, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Critical (h)")
                    Spacer()
                    TextField("", value: $criticalHours, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Milestone (h)")
                    Spacer()
                    TextField("", value: $milestoneHours, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }
            }

            Text("Notifications are sent once per day when net time crosses a threshold.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    // MARK: - Data Tab

    private var dataTab: some View {
        Form {
            Section("Logs") {
                HStack {
                    Button("Open Log Folder") {
                        NSWorkspace.shared.open(manager.persistence.logDirectory)
                    }

                    Button("Choose Log Folder...") {
                        chooseLogFolder()
                    }
                }
            }

            Section("Export") {
                Button("Export as CSV...") {
                    if let url = manager.persistence.exportCSV() {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
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
        panel.prompt = "Choose"
        panel.message = "Select a folder for worktime logs"

        if panel.runModal() == .OK, let url = panel.url {
            manager.persistence.setCustomLogFolder(url)
        }
    }
}
