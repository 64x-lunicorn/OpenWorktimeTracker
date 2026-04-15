import SwiftUI

struct WeekHistoryView: View {
    @Environment(WorkdayManager.self) private var manager
    @State private var entries: [TimeEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("history.last7days")
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .tracking(1.5)
                Spacer()
                Text(weekTotal)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundStyle(DesignTokens.Colors.accentBlue)
                    .monospacedDigit()
            }

            if entries.isEmpty {
                Text("history.noData")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DesignTokens.Spacing.sm)
            } else {
                VStack(spacing: 2) {
                    ForEach(entries) { entry in
                        DayRow(entry: entry, maxHours: maxHours)
                    }
                }
            }
        }
        .onAppear { loadHistory() }
    }

    private func loadHistory() {
        entries = manager.persistence.loadLastDays(7)
    }

    private var maxHours: Double {
        max(10, entries.map { netHours(for: $0) }.max() ?? 8)
    }

    private var weekTotal: String {
        let total = entries.reduce(0.0) { $0 + netHours(for: $1) }
        return String(format: "%.1fh total", total)
    }

    private func netHours(for entry: TimeEntry) -> Double {
        let calc = BreakCalculator()
        let net = calc.netWorkTime(
            grossTime: entry.grossTime,
            manualPause: entry.totalManualPause,
            idlePause: entry.totalIdlePause
        )
        return net.inHours
    }
}

// MARK: - Day Row

private struct DayRow: View {
    let entry: TimeEntry
    let maxHours: Double

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Weekday abbreviation
            Text(weekdayAbbr)
                .font(DesignTokens.Typography.labelMicro)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                .frame(width: 24, alignment: .leading)

            // Date
            Text(shortDate)
                .font(DesignTokens.Typography.labelMicro)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                .frame(width: 36, alignment: .leading)
                .monospacedDigit()

            // Bar
            GeometryReader { geo in
                let width = max(0, geo.size.width * (netHours / maxHours))
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: width, height: 12)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 16)

            // Hours
            Text(String(format: "%.1fh", netHours))
                .font(DesignTokens.Typography.labelMicro)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .monospacedDigit()
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.vertical, 1)
    }

    private var netHours: Double {
        let calc = BreakCalculator()
        let net = calc.netWorkTime(
            grossTime: entry.grossTime,
            manualPause: entry.totalManualPause,
            idlePause: entry.totalIdlePause
        )
        return net.inHours
    }

    private var barColor: Color {
        if netHours >= 10 { return DesignTokens.Colors.accentRed }
        if netHours >= 8 { return DesignTokens.Colors.accentOrange }
        return DesignTokens.Colors.accentBlue
    }

    private var weekdayAbbr: String {
        guard let date = parseDate() else { return "?" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }

    private var shortDate: String {
        guard let date = parseDate() else { return entry.date }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter.string(from: date)
    }

    private func parseDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: entry.date)
    }
}
