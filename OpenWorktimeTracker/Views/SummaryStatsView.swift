import SwiftUI

struct SummaryStatsView: View {
    @Environment(WorkdayManager.self) private var manager
    @State private var period: Period = .week
    @State private var entries: [TimeEntry] = []

    enum Period: String, CaseIterable {
        case week
        case month

        var label: LocalizedStringKey {
            switch self {
            case .week: return "summary.week"
            case .month: return "summary.month"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Header with picker
            HStack {
                Text("summary.title")
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .tracking(1.5)
                Spacer()
                Picker("", selection: $period) {
                    ForEach(Period.allCases, id: \.self) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            if entries.isEmpty {
                Text("summary.noData")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DesignTokens.Spacing.sm)
            } else {
                // Stats grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: DesignTokens.Spacing.sm
                ) {
                    StatCard(
                        label: String(localized: "summary.totalHours"),
                        value: String(format: "%.1fh", totalHours),
                        icon: "clock",
                        color: DesignTokens.Colors.accentBlue
                    )
                    StatCard(
                        label: String(localized: "summary.workDays"),
                        value: "\(workDays)",
                        icon: "calendar",
                        color: DesignTokens.Colors.accentGreen
                    )
                    StatCard(
                        label: String(localized: "summary.dailyAvg"),
                        value: String(format: "%.1fh", dailyAverage),
                        icon: "chart.bar",
                        color: DesignTokens.Colors.accentOrange
                    )
                    StatCard(
                        label: String(localized: "summary.overtime"),
                        value: overtimeFormatted,
                        icon: overtimeSeconds >= 0 ? "arrow.up.right" : "arrow.down.right",
                        color: overtimeSeconds >= 0
                            ? DesignTokens.Colors.accentRed : DesignTokens.Colors.accentGreen
                    )
                }
            }
        }
        .onAppear { loadEntries() }
        .onChange(of: period) { _, _ in loadEntries() }
    }

    // MARK: - Data Loading

    private func loadEntries() {
        let all = manager.persistence.loadAll()
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .week:
            guard
                let weekStart = calendar.date(
                    from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
                )
            else {
                entries = []
                return
            }
            entries = all.filter { entry in
                guard let date = parseDate(entry.date) else { return false }
                return date >= weekStart && date <= now
            }

        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let monthStart = calendar.date(from: components) else {
                entries = []
                return
            }
            entries = all.filter { entry in
                guard let date = parseDate(entry.date) else { return false }
                return date >= monthStart && date <= now
            }
        }
    }

    // MARK: - Computed Stats

    private var totalHours: Double {
        entries.reduce(0) { $0 + netHours(for: $1) }
    }

    private var workDays: Int {
        entries.count
    }

    private var dailyAverage: Double {
        guard workDays > 0 else { return 0 }
        return totalHours / Double(workDays)
    }

    private var targetHoursPerDay: Double {
        UserDefaults.standard.object(forKey: AppSettingsKey.normalNotificationHours) as? Double
            ?? AppDefaults.normalNotificationHours
    }

    private var overtimeSeconds: Double {
        totalHours - (Double(workDays) * targetHoursPerDay)
    }

    private var overtimeFormatted: String {
        let abs = abs(overtimeSeconds)
        let sign = overtimeSeconds >= 0 ? "+" : "-"
        return String(format: "%@%.1fh", sign, abs)
    }

    // MARK: - Helpers

    private func netHours(for entry: TimeEntry) -> Double {
        let calc = BreakCalculator()
        let net = calc.netWorkTime(
            grossTime: entry.grossTime,
            manualPause: entry.totalManualPause,
            idlePause: entry.totalIdlePause
        )
        return net.inHours
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(color)
                Text(label)
                    .font(DesignTokens.Typography.labelMicro)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }

            Text(value)
                .font(DesignTokens.Typography.titleMedium)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }
}
