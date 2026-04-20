import SwiftUI

struct LogEditorView: View {
    let persistence: PersistenceManager
    let manager: WorkdayManager

    @State private var entries: [TimeEntry] = []
    @State private var selectedDate: String?

    var body: some View {
        NavigationSplitView {
            List(entries, selection: $selectedDate) { entry in
                LogEntryRow(entry: entry)
                    .tag(entry.date)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            .onAppear { loadEntries() }
        } detail: {
            if let date = selectedDate,
                let index = entries.firstIndex(where: { $0.date == date })
            {
                LogEntryEditView(
                    entry: $entries[index],
                    persistence: persistence,
                    manager: manager,
                    onSave: { savedEntry in
                        if let i = entries.firstIndex(where: { $0.date == savedEntry.date }) {
                            entries[i] = savedEntry
                        }
                        if savedEntry.date == TimeEntry.dateString(from: Date()) {
                            manager.reloadCurrentEntry()
                        }
                    },
                    onDelete: { dateString in
                        persistence.delete(for: dateString)
                        entries.removeAll { $0.date == dateString }
                        selectedDate = entries.first?.date
                        if dateString == TimeEntry.dateString(from: Date()) {
                            manager.reloadCurrentEntry()
                        }
                    }
                )
            } else {
                Text(String(localized: "logEditor.noEntries"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 650, minHeight: 450)
    }

    private func loadEntries() {
        entries = persistence.loadAll()
        if selectedDate == nil {
            selectedDate = entries.first?.date
        }
    }
}

// MARK: - Entry Row

private struct LogEntryRow: View {
    let entry: TimeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.date)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Spacer()
                Text(netTime.hoursMinutesFormatted)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(timeColor)
            }

            HStack(spacing: 4) {
                Text(entry.startTime.hoursMinutesString)
                if let end = entry.endTime {
                    Text("→")
                        .foregroundStyle(.tertiary)
                    Text(end.hoursMinutesString)
                }
                Spacer()
                if !entry.note.isEmpty {
                    Image(systemName: "note.text")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var netTime: TimeInterval {
        let calc = BreakCalculator()
        return calc.netWorkTime(
            grossTime: entry.grossTime,
            manualPause: entry.totalManualPause,
            idlePause: entry.totalIdlePause
        )
    }

    private var timeColor: Color {
        let hours = netTime.inHours
        if hours >= 9.5 { return DesignTokens.Colors.accentRed }
        if hours >= 8.0 { return DesignTokens.Colors.accentOrange }
        return DesignTokens.Colors.accentBlue
    }
}
