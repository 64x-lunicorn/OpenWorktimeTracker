import SwiftUI

struct MetricCardsView: View {
    @Environment(WorkdayManager.self) private var manager

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            MetricCard(
                icon: "arrow.right.circle",
                label: "Start",
                value: manager.currentEntry?.startTime.hoursMinutesString ?? "--:--"
            )

            MetricCard(
                icon: "clock",
                label: "Gross",
                value: manager.grossTime.hoursMinutesFormatted
            )

            MetricCard(
                icon: "cup.and.saucer",
                label: "Auto Break",
                value: manager.autoBreak.hoursMinutesFormatted,
                accent: manager.autoBreak > 0 ? DesignTokens.Colors.accentGreen : nil
            )
        }
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let icon: String
    let label: String
    let value: String
    var accent: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label.uppercased())
                    .font(DesignTokens.Typography.labelMicro)
                    .tracking(1)
            }
            .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)

            Text(value)
                .font(DesignTokens.Typography.titleMedium)
                .foregroundStyle(accent ?? DesignTokens.Colors.onSurface)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}
