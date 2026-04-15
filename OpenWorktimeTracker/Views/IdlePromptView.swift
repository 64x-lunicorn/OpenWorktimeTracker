import SwiftUI

struct IdlePromptView: View {
    @Environment(WorkdayManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    let promptInfo: IdlePromptInfo

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Icon
            Image(systemName: promptInfo.spansMidnight ? "sunrise.fill" : "moon.zzz.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    promptInfo.spansMidnight
                        ? DesignTokens.Colors.accentOrange
                        : DesignTokens.Colors.accentBlue
                )
                .padding(.top, DesignTokens.Spacing.lg)

            // Title
            Text(promptInfo.spansMidnight ? "Neuer Arbeitstag!" : "Inaktivität erkannt")
                .font(DesignTokens.Typography.headlineSmall)
                .foregroundStyle(DesignTokens.Colors.onSurface)

            // Details
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Du warst \(promptInfo.formattedDuration) inaktiv")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundStyle(DesignTokens.Colors.onSurface)

                Text(promptInfo.formattedRange)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .monospacedDigit()
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(DesignTokens.Colors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))

            // Actions
            if promptInfo.spansMidnight {
                midnightActions
            } else {
                sameDayActions
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: 320)
        .background(DesignTokens.Colors.surface)
    }

    // MARK: - Same Day Actions

    private var sameDayActions: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Button {
                manager.handleIdleDecision(.work)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text("War Arbeitszeit (Meeting/Testen)")
                }
                .font(DesignTokens.Typography.labelLarge)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DesignTokens.Colors.accentGreen.opacity(0.15))
                .foregroundStyle(DesignTokens.Colors.accentGreen)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
            .buttonStyle(.plain)

            Button {
                manager.handleIdleDecision(.pause)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("War Pause (abziehen)")
                }
                .font(DesignTokens.Typography.labelLarge)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DesignTokens.Colors.accentOrange.opacity(0.15))
                .foregroundStyle(DesignTokens.Colors.accentOrange)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Midnight Crossing Actions

    private var midnightActions: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Button {
                manager.handleNewDayFromIdle(endYesterdayAt: promptInfo.idleStart)
                dismiss()
            } label: {
                VStack(spacing: 2) {
                    Text("Gestern um \(promptInfo.idleStart.hoursMinutesString) beenden")
                    Text("Heute jetzt starten")
                        .font(DesignTokens.Typography.labelMicro)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                }
                .font(DesignTokens.Typography.labelLarge)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DesignTokens.Colors.accentBlue.opacity(0.15))
                .foregroundStyle(DesignTokens.Colors.accentBlue)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
            .buttonStyle(.plain)

            Button {
                manager.handleIdleDecision(.work)
                dismiss()
            } label: {
                Text("Alles als Arbeitszeit zählen")
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
}
