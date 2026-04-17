import SwiftUI

struct TimerDisplayView: View {
    @Environment(WorkdayManager.self) private var manager

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Label
            Text("timer.netWorkTime")
                .font(DesignTokens.Typography.labelSmall)
                .tracking(2)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)

            // Large Timer
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(hoursMinutes)
                    .font(DesignTokens.Typography.displayLarge)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(":\(seconds)")
                    .font(DesignTokens.Typography.displaySeconds)
                    .foregroundStyle(DesignTokens.Colors.accentBlue)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            // Progress to daily goal
            ProgressBarView(
                progress: goalProgress,
                thresholdColor: thresholdColor
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("timer.accessibility.netWorkTime"))
        .accessibilityValue(Text(hoursMinutes))
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                DesignTokens.Colors.surfaceContainerLow
                // Decorative glow
                Circle()
                    .fill(DesignTokens.Colors.accentBlue.opacity(0.05))
                    .blur(radius: 40)
                    .offset(x: -60, y: -30)
                Circle()
                    .fill(DesignTokens.Colors.accentGreen.opacity(0.05))
                    .blur(radius: 40)
                    .offset(x: 60, y: 30)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))
    }

    // MARK: - Computed

    private var hoursMinutes: String {
        let total = Int(manager.displayTime)
        let h = total / 3600
        let m = (total % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }

    private var seconds: String {
        let s = Int(manager.displayTime) % 60
        return String(format: "%02d", s)
    }

    private var goalProgress: Double {
        let goal =
            (UserDefaults.standard.object(forKey: AppSettingsKey.normalNotificationHours) as? Double
                ?? AppDefaults.normalNotificationHours) * 3600
        guard goal > 0 else { return 0 }
        return min(1.0, manager.displayTime / goal)
    }

    private var thresholdColor: Color {
        switch manager.menuBarColor {
        case .normal: return DesignTokens.Colors.accentBlue
        case .orange: return DesignTokens.Colors.accentOrange
        case .red: return DesignTokens.Colors.accentRed
        }
    }
}
