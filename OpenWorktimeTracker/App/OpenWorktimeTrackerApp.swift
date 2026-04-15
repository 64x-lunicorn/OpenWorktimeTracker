import Sparkle
import SwiftUI

@main
struct OpenWorktimeTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var workdayManager = WorkdayManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(workdayManager)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: menuBarIcon)
                    .symbolEffect(.pulse, isActive: workdayManager.state == .running)
                Text(workdayManager.menuBarTitle)
                    .monospacedDigit()
            }
            .foregroundStyle(menuBarForeground)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(workdayManager)
        }
    }

    private var menuBarIcon: String {
        switch workdayManager.state {
        case .notStarted: return "clock"
        case .running: return "clock.fill"
        case .paused: return "pause.circle"
        case .ended: return "checkmark.circle"
        }
    }

    private var menuBarForeground: some ShapeStyle {
        switch workdayManager.menuBarColor {
        case .normal: return AnyShapeStyle(.primary)
        case .orange: return AnyShapeStyle(DesignTokens.Colors.accentOrange)
        case .red: return AnyShapeStyle(DesignTokens.Colors.accentRed)
        }
    }
}
