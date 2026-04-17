import SwiftUI

struct MaxHoursPromptView: View {
    @Environment(WorkdayManager.self) private var manager

    let hours: Double
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(DesignTokens.Colors.accentRed)
                .padding(.top, DesignTokens.Spacing.lg)

            // Title
            Text("maxhours.title")
                .font(DesignTokens.Typography.headlineSmall)
                .foregroundStyle(DesignTokens.Colors.onSurface)

            // Details
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(
                    String(
                        format: String(localized: "maxhours.body"),
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
                Button {
                    manager.endDay()
                    onDismiss?()
                } label: {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("maxhours.endDay")
                    }
                    .font(DesignTokens.Typography.labelLarge)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DesignTokens.Colors.accentRed.opacity(0.15))
                    .foregroundStyle(DesignTokens.Colors.accentRed)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
                .buttonStyle(.plain)

                Button {
                    onDismiss?()
                } label: {
                    HStack {
                        Image(systemName: "arrow.forward.circle.fill")
                        Text("maxhours.continueWorking")
                    }
                    .font(DesignTokens.Typography.labelLarge)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DesignTokens.Colors.surfaceContainerHigh)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: 320)
        .background(DesignTokens.Colors.surface)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("maxhours.title"))
    }
}
