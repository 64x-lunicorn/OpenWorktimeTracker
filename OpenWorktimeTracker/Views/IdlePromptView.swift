import SwiftUI

struct IdlePromptView: View {
    @Environment(WorkdayManager.self) private var manager

    let idlePeriod: IdlePeriod

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
                .accessibilityHidden(true)

            // Title
            Text(
                idlePeriod.spansMidnight
                    ? String(localized: "idle.newWorkday")
                    : String(localized: "idle.inactivityDetected")
            )
            .font(DesignTokens.Typography.headlineSmall)
            .foregroundStyle(DesignTokens.Colors.onSurface)
            .multilineTextAlignment(.center)

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

            Text("idle.decisionHelp")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                .multilineTextAlignment(.center)

            // Actions
            if idlePeriod.spansMidnight {
                midnightActions
            } else {
                sameDayActions
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: DesignTokens.promptWidth)
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
            ActionButton(
                title: String(localized: "idle.wasWorkTime"), icon: "person.2.fill",
                style: .tinted(DesignTokens.Colors.accentGreen),
                subtitle: String(localized: "idle.work.detail")
            ) {
                manager.handleIdleDecision(.work)
            }

            ActionButton(
                title: String(localized: "idle.wasPause"), icon: "cup.and.saucer.fill",
                style: .tinted(DesignTokens.Colors.accentOrange),
                subtitle: String(localized: "idle.pause.detail")
            ) {
                manager.handleIdleDecision(.pause)
            }

            Text("idle.dayActions")
                .font(DesignTokens.Typography.labelSmall)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignTokens.Spacing.sm)

            ActionButton(
                title: String(
                    format: String(localized: "idle.endDay.atTime"),
                    idlePeriod.idleStart.hoursMinutesString),
                icon: "stop.circle", style: .secondary,
                subtitle: String(
                    format: String(localized: "idle.endDay.afterHours"),
                    netTimeAtIdleStart.hoursMinutesFormatted)
            ) {
                manager.handleIdleDecisionAndEndDay()
            }

            ActionButton(
                title: String(localized: "idle.restart"), icon: "arrow.clockwise.circle",
                style: .secondary,
                subtitle: String(
                    format: String(localized: "idle.restart.detail"),
                    idlePeriod.idleStart.hoursMinutesString)
            ) {
                manager.handleIdleDecisionAndRestart()
            }
        }
    }

    // MARK: - Midnight Crossing Actions

    private var midnightActions: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ActionButton(
                title: String(
                    format: String(localized: "idle.endYesterday"),
                    idlePeriod.idleStart.hoursMinutesString),
                icon: "sunrise", style: .primary,
                subtitle: String(localized: "idle.startToday")
            ) {
                manager.handleNewDayFromIdle(endYesterdayAt: idlePeriod.idleStart)
            }

            ActionButton(
                title: String(localized: "idle.countAsWork"), icon: "person.2",
                style: .secondary
            ) {
                manager.handleIdleDecision(.work)
            }
        }
    }
}

// MARK: - Formatting

/// View-layer presentation for an IdlePeriod. Kept out of the domain type so
/// Core/Models has no UI-facing concerns.
private extension IdlePeriod {
    var formattedDuration: String {
        Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes], width: .wide))
    }

    var formattedRange: String {
        if spansMidnight {
            return "\(idleStart.formatted(date: .abbreviated, time: .shortened)) – "
                + idleEnd.formatted(date: .abbreviated, time: .shortened)
        }
        return "\(idleStart.hoursMinutesString) – \(idleEnd.hoursMinutesString)"
    }
}
