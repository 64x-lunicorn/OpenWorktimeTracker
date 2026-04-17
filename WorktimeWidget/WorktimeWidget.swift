import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct WorktimeEntry: TimelineEntry {
    let date: Date
    let state: String
    let netTimeSeconds: TimeInterval
    let grossTimeSeconds: TimeInterval
    let startTime: Date?
    let workDate: String
    let targetHours: Double
    let orangeThreshold: Double
    let redThreshold: Double
}

// MARK: - Timeline Provider

struct WorktimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorktimeEntry {
        WorktimeEntry(
            date: Date(),
            state: "running",
            netTimeSeconds: 5 * 3600 + 23 * 60,
            grossTimeSeconds: 6 * 3600,
            startTime: Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date()),
            workDate: "2024-01-15",
            targetHours: 8.0,
            orangeThreshold: 8.0,
            redThreshold: 9.5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WorktimeEntry) -> Void) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorktimeEntry>) -> Void) {
        let entry = createEntry()
        let isRunning = entry.state == "running"
        let refreshMinutes = isRunning ? 1 : 5
        let nextUpdate = Calendar.current.date(
            byAdding: .minute, value: refreshMinutes, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> WorktimeEntry {
        WorktimeEntry(
            date: Date(),
            state: SharedDefaults.readState(),
            netTimeSeconds: SharedDefaults.readNetTime(),
            grossTimeSeconds: SharedDefaults.readGrossTime(),
            startTime: SharedDefaults.readStartTime(),
            workDate: SharedDefaults.readDate(),
            targetHours: SharedDefaults.readTargetHours(),
            orangeThreshold: SharedDefaults.readOrangeThreshold(),
            redThreshold: SharedDefaults.readRedThreshold()
        )
    }
}

// MARK: - Small Widget View

struct WorktimeWidgetSmallView: View {
    let entry: WorktimeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Circle()
                    .fill(stateColor)
                    .frame(width: 6, height: 6)
                Text(stateLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            Spacer()

            Text(formatTime(entry.netTimeSeconds))
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)

            if let start = entry.startTime {
                Text(
                    String(
                        format: String(localized: "widget.since"),
                        formatHourMinute(start))
                )
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var stateColor: Color {
        let hours = entry.netTimeSeconds / 3600
        if hours >= entry.redThreshold {
            return Color(light: .init(hex: 0xBA1A1A), dark: .init(hex: 0xFF453A))
        }
        if hours >= entry.orangeThreshold {
            return Color(light: .init(hex: 0xE67700), dark: .init(hex: 0xFF9500))
        }
        switch entry.state {
        case "running": return Color(light: .init(hex: 0x1B7A2B), dark: .init(hex: 0x30D158))
        case "paused": return Color(light: .init(hex: 0xE67700), dark: .init(hex: 0xFF9500))
        case "ended": return Color(light: .init(hex: 0x0055D4), dark: .init(hex: 0x0A84FF))
        default: return .secondary
        }
    }

    private var stateLabel: String {
        switch entry.state {
        case "running": return String(localized: "widget.state.running")
        case "paused": return String(localized: "widget.state.paused")
        case "ended": return String(localized: "widget.state.ended")
        default: return String(localized: "widget.state.idle")
        }
    }
}

// MARK: - Medium Widget View

struct WorktimeWidgetMediumView: View {
    let entry: WorktimeEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 6, height: 6)
                    Text(stateLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }

                Spacer()

                Text(formatTime(entry.netTimeSeconds))
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                if let start = entry.startTime {
                    Text(
                        String(
                            format: String(localized: "widget.since"),
                            formatHourMinute(start))
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 6)
                    Circle()
                        .trim(
                            from: 0, to: min(1.0, entry.netTimeSeconds / (entry.targetHours * 3600))
                        )
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(
                        String(
                            format: "%.0f%%",
                            min(100, entry.netTimeSeconds / (entry.targetHours * 3600) * 100))
                    )
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                }
                .frame(width: 60, height: 60)

                Text(
                    String(
                        format: String(localized: "widget.target"),
                        Int(entry.targetHours))
                )
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var stateColor: Color {
        let hours = entry.netTimeSeconds / 3600
        if hours >= entry.redThreshold {
            return Color(light: .init(hex: 0xBA1A1A), dark: .init(hex: 0xFF453A))
        }
        if hours >= entry.orangeThreshold {
            return Color(light: .init(hex: 0xE67700), dark: .init(hex: 0xFF9500))
        }
        switch entry.state {
        case "running": return Color(light: .init(hex: 0x1B7A2B), dark: .init(hex: 0x30D158))
        case "paused": return Color(light: .init(hex: 0xE67700), dark: .init(hex: 0xFF9500))
        case "ended": return Color(light: .init(hex: 0x0055D4), dark: .init(hex: 0x0A84FF))
        default: return .secondary
        }
    }

    private var stateLabel: String {
        switch entry.state {
        case "running": return String(localized: "widget.state.running")
        case "paused": return String(localized: "widget.state.paused")
        case "ended": return String(localized: "widget.state.ended")
        default: return String(localized: "widget.state.idle")
        }
    }

    private var progressColor: Color {
        let hours = entry.netTimeSeconds / 3600
        if hours >= entry.redThreshold {
            return Color(light: .init(hex: 0xBA1A1A), dark: .init(hex: 0xFF453A))
        }
        if hours >= entry.orangeThreshold {
            return Color(light: .init(hex: 0xE67700), dark: .init(hex: 0xFF9500))
        }
        return Color(light: .init(hex: 0x1B7A2B), dark: .init(hex: 0x30D158))
    }
}

// MARK: - Helpers

private func formatTime(_ seconds: TimeInterval) -> String {
    let h = Int(seconds) / 3600
    let m = (Int(seconds) % 3600) / 60
    return String(format: "%d:%02d", h, m)
}

private func formatHourMinute(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

// MARK: - Widget View Router

struct WorktimeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WorktimeEntry

    var body: some View {
        switch family {
        case .systemMedium:
            WorktimeWidgetMediumView(entry: entry)
        default:
            WorktimeWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct WorktimeWidget: Widget {
    let kind: String = "WorktimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorktimeProvider()) { entry in
            WorktimeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Work Time")
        .description("Shows your current work time at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
