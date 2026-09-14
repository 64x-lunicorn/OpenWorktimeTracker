import SwiftUI

struct LogEditorView: View {
    let manager: WorkdayManager

    @State private var entries: [TimeEntry] = []
    @State private var selectedDate: String?

    var body: some View {
        NavigationSplitView {
            List(entries, selection: $selectedDate) { entry in
                LogEntryRow(workday: manager.workday(for: entry))
                    .tag(entry.date)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            .onAppear { loadEntries() }
        } detail: {
            if let date = selectedDate,
                let entry = entries.first(where: { $0.date == date }) {
                LogEntryEditView(
                    entry: entry,
                    manager: manager,
                    onSave: { savedEntry in
                        if let i = entries.firstIndex(where: { $0.date == savedEntry.date }) {
                            entries[i] = savedEntry
                        }
                    },
                    onDelete: { dateString in
                        guard manager.deleteLog(entry) else { return }
                        entries.removeAll { $0.date == dateString }
                        selectedDate = entries.first?.date
                    }
                )
                .id(entry.id)
            } else {
                ContentUnavailableView(
                    entries.isEmpty ? String(localized: "logEditor.noEntries")
                        : String(localized: "logEditor.selectEntry"),
                    systemImage: "calendar"
                )
            }
        }
        .frame(minWidth: 650, minHeight: 450)
        .alert(
            String(localized: "logEditor.error.title"),
            isPresented: Binding(
                get: { manager.logMutationError != nil },
                set: { if !$0 { manager.clearLogMutationError() } }
            )
        ) {
            Button(String(localized: "logEditor.error.dismiss")) {
                manager.clearLogMutationError()
            }
        } message: {
            Text(manager.logMutationError?.localizedDescription ?? "")
        }
    }

    private func loadEntries() {
        entries = manager.loadDailyLogs()
        if selectedDate == nil {
            selectedDate = entries.first?.date
        }
    }
}

// MARK: - Entry Row

private struct LogEntryRow: View {
    let workday: Workday

    private var entry: TimeEntry { workday.payload }

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
        workday.netWorkTime
    }

    private var timeColor: Color {
        workday.thresholdLevel.accent.color
    }
}
