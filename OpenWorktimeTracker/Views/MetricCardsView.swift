import SwiftUI

struct MetricCardsView: View {
    @Environment(WorkdayManager.self) private var manager
    @State private var isEditingStart = false
    @State private var isEditingEnd = false
    @State private var editedStartTime = Date()
    @State private var editedEndTime = Date()

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Row 1: Start, Gross, Auto Break
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Start time (tappable to edit)
                Button {
                    editedStartTime = manager.currentEntry?.startTime ?? Date()
                    isEditingStart.toggle()
                } label: {
                    MetricCard(
                        icon: "arrow.right.circle",
                        label: String(localized: "metric.start"),
                        value: manager.currentEntry?.startTime.hoursMinutesString ?? "--:--",
                        isEditable: true
                    )
                }
                .buttonStyle(.plain)

                MetricCard(
                    icon: "clock",
                    label: String(localized: "metric.gross"),
                    value: manager.grossTime.hoursMinutesFormatted
                )

                MetricCard(
                    icon: "cup.and.saucer",
                    label: String(localized: "metric.autoBreak"),
                    value: manager.autoBreak.hoursMinutesFormatted,
                    accent: manager.autoBreak > 0 ? DesignTokens.Colors.accentGreen : nil
                )
            }

            // Row 2: Manual Pause, End/ETA
            HStack(spacing: DesignTokens.Spacing.sm) {
                MetricCard(
                    icon: "pause.circle",
                    label: String(localized: "metric.manualPause"),
                    value: manager.manualPause.hoursMinutesFormatted,
                    accent: manager.manualPause > 0 ? DesignTokens.Colors.accentOrange : nil
                )

                if manager.state == .ended {
                    // End time (tappable to edit)
                    Button {
                        editedEndTime = manager.currentEntry?.endTime ?? Date()
                        isEditingEnd.toggle()
                    } label: {
                        MetricCard(
                            icon: "stop.circle",
                            label: String(localized: "metric.end"),
                            value: manager.currentEntry?.endTime?.hoursMinutesString ?? "--:--",
                            isEditable: true
                        )
                    }
                    .buttonStyle(.plain)
                } else if let eta = manager.estimatedEndTime {
                    MetricCard(
                        icon: "target",
                        label: String(localized: "metric.eta"),
                        value: eta.hoursMinutesString,
                        accent: DesignTokens.Colors.accentBlue
                    )
                } else {
                    MetricCard(
                        icon: "checkmark.circle",
                        label: String(localized: "metric.target"),
                        value: String(localized: "metric.reached")
                    )
                }
            }
        }
        .popover(isPresented: $isEditingStart, arrowEdge: .bottom) {
            timeEditor(title: String(localized: "metric.editStartTime"), date: $editedStartTime) {
                manager.updateStartTime(editedStartTime)
                isEditingStart = false
            }
        }
        .popover(isPresented: $isEditingEnd, arrowEdge: .bottom) {
            timeEditor(title: String(localized: "metric.editEndTime"), date: $editedEndTime) {
                manager.updateEndTime(editedEndTime)
                isEditingEnd = false
            }
        }
    }

    private func timeEditor(title: String, date: Binding<Date>, onSave: @escaping () -> Void)
        -> some View
    {
        let hours = Binding<Int>(
            get: { Calendar.current.component(.hour, from: date.wrappedValue) },
            set: { newHour in
                var comps = Calendar.current.dateComponents(
                    [.year, .month, .day, .minute, .second], from: date.wrappedValue)
                comps.hour = newHour
                if let newDate = Calendar.current.date(from: comps) {
                    date.wrappedValue = newDate
                }
            }
        )
        let minutes = Binding<Int>(
            get: { Calendar.current.component(.minute, from: date.wrappedValue) },
            set: { newMinute in
                var comps = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .second], from: date.wrappedValue)
                comps.minute = newMinute
                if let newDate = Calendar.current.date(from: comps) {
                    date.wrappedValue = newDate
                }
            }
        )

        return VStack(spacing: DesignTokens.Spacing.md) {
            Text(title)
                .font(DesignTokens.Typography.labelLarge)
                .foregroundStyle(DesignTokens.Colors.onSurface)

            HStack(spacing: 4) {
                // Hours stepper
                VStack(spacing: 2) {
                    Text("H")
                        .font(DesignTokens.Typography.labelMicro)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    Stepper(value: hours, in: 0...23) {
                        Text(String(format: "%02d", hours.wrappedValue))
                            .font(DesignTokens.Typography.displaySmall)
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                }

                Text(":")
                    .font(DesignTokens.Typography.displaySmall)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .padding(.top, 14)

                // Minutes stepper
                VStack(spacing: 2) {
                    Text("M")
                        .font(DesignTokens.Typography.labelMicro)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    Stepper(value: minutes, in: 0...59) {
                        Text(String(format: "%02d", minutes.wrappedValue))
                            .font(DesignTokens.Typography.displaySmall)
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                }
            }

            HStack {
                Button(String(localized: "metric.cancel")) {
                    isEditingStart = false
                    isEditingEnd = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)

                Spacer()

                Button(String(localized: "metric.save")) {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(width: 200)
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let icon: String
    let label: String
    let value: String
    var accent: Color?
    var isEditable: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label.uppercased())
                    .font(DesignTokens.Typography.labelMicro)
                    .tracking(1)
                if isEditable {
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 8))
                        .opacity(0.5)
                }
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
