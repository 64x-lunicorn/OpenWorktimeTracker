import SwiftUI

struct MaxHoursPromptView: View {
    @Environment(WorkdayManager.self) private var manager

    let hours: Double

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(DesignTokens.Colors.accentRed)
                .accessibilityHidden(true)

            // Title
            Text("maxhours.title")
                .font(DesignTokens.Typography.headlineSmall)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .multilineTextAlignment(.center)

            // Details
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(
                    String(
                        format: String(localized: "maxhours.body"),
                        locale: Locale.current,
                        hours)
                )
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .multilineTextAlignment(.center)
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(DesignTokens.Colors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))

            // Actions
            VStack(spacing: DesignTokens.Spacing.sm) {
                ActionButton(
                    title: String(localized: "maxhours.endDay"), icon: "stop.circle.fill",
                    style: .primary
                ) {
                    manager.endDay()
                }

                ActionButton(
                    title: String(localized: "maxhours.continueWorking"), icon: "arrow.forward.circle",
                    style: .secondary
                ) {
                    manager.dismissIdlePeriod()
                }
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: DesignTokens.promptWidth)
        .background(DesignTokens.Colors.surface)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("maxhours.title"))
    }
}
