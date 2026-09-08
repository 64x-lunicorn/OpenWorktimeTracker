import SwiftUI
import WidgetKit
import os.log

private let logger = Logger(subsystem: "com.openworktimetracker.app.widget", category: "Snapshot")

// MARK: - Timeline Entry

struct WorktimeEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

// MARK: - Timeline Provider

struct WorktimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorktimeEntry {
        let now = Date()
        return WorktimeEntry(date: now, snapshot: WidgetSnapshot(
            measuredAt: now,
            state: "running",
            netTime: 5 * 3600 + 23 * 60,
            grossTime: 6 * 3600,
            startTime: Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: now),
            workDate: "2024-01-15",
            targetHours: 8.0,
            orangeThreshold: 8.0,
            redThreshold: 9.5
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (WorktimeEntry) -> Void) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorktimeEntry>) -> Void) {
        let entry = createEntry()
        let isRunning = entry.snapshot?.isRunning == true
        // The running view counts up live via Text(timerInterval:), so timelines
        // only need occasional refreshes to update the progress ring and colors.
        // Refreshing every minute would exhaust WidgetKit's daily reload budget
        // and freeze the widget. The app also reloads timelines immediately on
        // pause/resume/end, so a longer interval here is safe.
        let refreshMinutes = isRunning ? 15 : 60
        let nextUpdate = Calendar.current.date(
            byAdding: .minute, value: refreshMinutes, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> WorktimeEntry {
        do {
            let snapshot = try SharedDefaults.shared.readSnapshot()
            return WorktimeEntry(date: Date(), snapshot: snapshot)
        } catch {
            logger.error("Cannot read widget snapshot: \(error.localizedDescription)")
            return WorktimeEntry(date: Date(), snapshot: nil)
        }
    }
}

// MARK: - Small Widget View

struct WorktimeWidgetSmallView: View {
    let snapshot: WidgetSnapshot
    let date: Date

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

            Group {
                if snapshot.isRunning {
                    Text(timerInterval: snapshot.liveNetStart...Date.distantFuture, countsDown: false)
                } else {
                    Text(formatTime(snapshot.netTime))
                }
            }
            .font(.system(size: 28, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)

            if let start = snapshot.startTime {
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
        switch snapshot.thresholdLevel(at: date) {
        case .critical: return Color(light: .init(hex: 0xBA1A1A), dark: .init(hex: 0xFF453A))
        case .elevated: return Color(light: .init(hex: 0xE67700), dark: .init(hex: 0xFF9500))
        case .normal:
            switch snapshot.state {
            case "running": return Color(light: .init(hex: 0x1B7A2B), dark: .init(hex: 0x30D158))
            case "paused": return Color(light: .init(hex: 0xE67700), dark: .init(hex: 0xFF9500))
            case "ended": return Color(light: .init(hex: 0x0055D4), dark: .init(hex: 0x0A84FF))
            default: return .secondary
            }
        }
    }

    private var stateLabel: String {
        switch snapshot.state {
        case "running": return String(localized: "widget.state.running")
        case "paused": return String(localized: "widget.state.paused")
        case "ended": return String(localized: "widget.state.ended")
        default: return String(localized: "widget.state.idle")
        }
    }
}

// MARK: - Medium Widget View

struct WorktimeWidgetMediumView: View {
    let snapshot: WidgetSnapshot
    let date: Date

    private var netTimeSeconds: TimeInterval { snapshot.netTime(at: date) }

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

                Group {
                    if snapshot.isRunning {
                        Text(
                            timerInterval: snapshot.liveNetStart...Date.distantFuture,
                            countsDown: false)
                    } else {
                        Text(formatTime(snapshot.netTime))
                    }
                }
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)

                if let start = snapshot.startTime {
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
                            from: 0, to: min(1.0, netTimeSeconds / (snapshot.targetHours * 3600))
                        )
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(
                        String(
                            format: "%.0f%%",
                            min(100, netTimeSeconds / (snapshot.targetHours * 3600) * 100))
                    )
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                }
                .frame(width: 60, height: 60)

                Text(
                    String(
                        format: String(localized: "widget.target"),
                        formatTime(snapshot.targetHours * 3600))
                )
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var stateColor: Color {
        switch snapshot.thresholdLevel(at: date) {
        case .critical: return Color(light: .init(hex: 0xBA1A1A), dark: .init(hex: 0xFF453A))
        case .elevated: return Color(light: .init(hex: 0xE67700), dark: .init(hex: 0xFF9500))
        case .normal:
            switch snapshot.state {
            case "running": return Color(light: .init(hex: 0x1B7A2B), dark: .init(hex: 0x30D158))
            case "paused": return Color(light: .init(hex: 0xE67700), dark: .init(hex: 0xFF9500))
            case "ended": return Color(light: .init(hex: 0x0055D4), dark: .init(hex: 0x0A84FF))
            default: return .secondary
            }
        }
    }

    private var stateLabel: String {
        switch snapshot.state {
        case "running": return String(localized: "widget.state.running")
        case "paused": return String(localized: "widget.state.paused")
        case "ended": return String(localized: "widget.state.ended")
        default: return String(localized: "widget.state.idle")
        }
    }

    private var progressColor: Color {
        switch snapshot.thresholdLevel(at: date) {
        case .critical: return Color(light: .init(hex: 0xBA1A1A), dark: .init(hex: 0xFF453A))
        case .elevated: return Color(light: .init(hex: 0xE67700), dark: .init(hex: 0xFF9500))
        case .normal: return Color(light: .init(hex: 0x1B7A2B), dark: .init(hex: 0x30D158))
        }
    }
}

// MARK: - Helpers

private func formatTime(_ seconds: TimeInterval) -> String {
    let h = Int(seconds) / 3600
    let m = (Int(seconds) % 3600) / 60
    return String(format: "%d:%02d", h, m)
}

private let hourMinuteFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}()

private func formatHourMinute(_ date: Date) -> String {
    hourMinuteFormatter.string(from: date)
}

// MARK: - Widget View Router

struct WorktimeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WorktimeEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemMedium:
                WorktimeWidgetMediumView(snapshot: snapshot, date: entry.date)
            default:
                WorktimeWidgetSmallView(snapshot: snapshot, date: entry.date)
            }
        } else {
            Text(String(localized: "widget.state.unavailable"))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(.fill.tertiary, for: .widget)
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
        .configurationDisplayName("widget.name")
        .description("widget.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
