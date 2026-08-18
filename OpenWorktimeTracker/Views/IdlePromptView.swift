import SwiftUI

struct IdlePromptView: View {
    @Environment(WorkdayManager.self) private var manager

    let idlePeriod: IdlePeriod
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Icon
            Image(systemName: idlePeriod.spansMidnight ? "sunrise.fill" : "moon.zzz.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    idlePeriod.spansMidnight
                        ? DesignTokens.Colors.accentOrange
                        : DesignTokens.Colors.accentBlue
                )
                .padding(.top, DesignTokens.Spacing.lg)

            // Title
            Text(
                idlePeriod.spansMidnight
                    ? String(localized: "idle.newWorkday")
                    : String(localized: "idle.inactivityDetected")
            )
            .font(DesignTokens.Typography.headlineSmall)
            .foregroundStyle(DesignTokens.Colors.onSurface)

            // Details
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(
                    String(
                        format: String(localized: "idle.youWereInactive"),
                        idlePeriod.formattedDuration)
                )
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(DesignTokens.Colors.onSurface)

                Text(idlePeriod.formattedRange)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .monospacedDigit()
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(DesignTokens.Colors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))

            // Actions
            if idlePeriod.spansMidnight {
                midnightActions
            } else {
                sameDayActions
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: 320)
        .background(DesignTokens.Colors.surface)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            Text(
                idlePeriod.spansMidnight
                    ? String(localized: "idle.newWorkday")
                    : String(localized: "idle.inactivityDetected")
            ))
    }

    // MARK: - Same Day Actions

    /// Net work time if the day were ended at idle start.
    private var netTimeAtIdleStart: TimeInterval {
        manager.currentWorkday?.netWorkTime(endingAt: idlePeriod.idleStart) ?? 0
    }

    private var sameDayActions: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Button {
                manager.handleIdleDecision(.work)
                onDismiss?()
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text("idle.wasWorkTime")
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
                onDismiss?()
            } label: {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("idle.wasPause")
                }
                .font(DesignTokens.Typography.labelLarge)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DesignTokens.Colors.accentOrange.opacity(0.15))
                .foregroundStyle(DesignTokens.Colors.accentOrange)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
            .buttonStyle(.plain)

            Button {
                manager.handleIdleDecisionAndEndDay()
                onDismiss?()
            } label: {
                VStack(spacing: 2) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text(
                            String(
                                format: String(localized: "idle.endDay.atTime"),
                                idlePeriod.idleStart.hoursMinutesString))
                    }
                    .font(DesignTokens.Typography.labelLarge)
                    Text(
                        String(
                            format: String(localized: "idle.endDay.afterHours"),
                            netTimeAtIdleStart.hoursMinutesFormatted))
                    .font(DesignTokens.Typography.labelMicro)
                    .foregroundStyle(DesignTokens.Colors.accentRed.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DesignTokens.Colors.accentRed.opacity(0.15))
                .foregroundStyle(DesignTokens.Colors.accentRed)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
            .buttonStyle(.plain)

            Button {
                manager.handleIdleDecisionAndRestart()
                onDismiss?()
            } label: {
                VStack(spacing: 2) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("idle.restart")
                    }
                    .font(DesignTokens.Typography.labelLarge)
                    Text(
                        String(
                            format: String(localized: "idle.restart.detail"),
                            idlePeriod.idleStart.hoursMinutesString))
                    .font(DesignTokens.Typography.labelMicro)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DesignTokens.Colors.surfaceContainerHigh)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Midnight Crossing Actions

    private var midnightActions: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Button {
                manager.handleNewDayFromIdle(endYesterdayAt: idlePeriod.idleStart)
                onDismiss?()
            } label: {
                VStack(spacing: 2) {
                    Text(
                        String(
                            format: String(localized: "idle.endYesterday"),
                            idlePeriod.idleStart.hoursMinutesString))
                    Text("idle.startToday")
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
                onDismiss?()
            } label: {
                Text("idle.countAsWork")
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

// MARK: - Formatting

/// View-layer presentation for an IdlePeriod. Kept out of the domain type so
/// Core/Models has no UI-facing concerns.
private extension IdlePeriod {
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes) Min"
    }

    var formattedRange: String {
        "\(idleStart.hoursMinutesString) – \(idleEnd.hoursMinutesString)"
    }
}
