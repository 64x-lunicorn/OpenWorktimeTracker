import SwiftUI

struct LogEntryEditView: View {
    @Binding var entry: TimeEntry
    let persistence: PersistenceManager
    let manager: WorkdayManager
    let onSave: (TimeEntry) -> Void
    let onDelete: (String) -> Void

    @State private var editedStart: Date
    @State private var editedEnd: Date
    @State private var editedPauseHours: Int
    @State private var editedPauseMinutes: Int
    @State private var editedNote: String
    @State private var editedIdleDecisions: [IdleDecision]
    @State private var showDeleteConfirmation = false
    @State private var hasChanges = false

    init(
        entry: Binding<TimeEntry>,
        persistence: PersistenceManager,
        manager: WorkdayManager,
        onSave: @escaping (TimeEntry) -> Void,
        onDelete: @escaping (String) -> Void
    ) {
        self._entry = entry
        self.persistence = persistence
        self.manager = manager
        self.onSave = onSave
        self.onDelete = onDelete

        let e = entry.wrappedValue
        self._editedStart = State(initialValue: e.startTime)
        self._editedEnd = State(initialValue: e.endTime ?? Date())
        self._editedPauseHours = State(initialValue: Int(e.manualPauseSeconds) / 3600)
        self._editedPauseMinutes = State(initialValue: (Int(e.manualPauseSeconds) % 3600) / 60)
        self._editedNote = State(initialValue: e.note)
        self._editedIdleDecisions = State(initialValue: e.idleDecisions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                Divider()
                timeSection
                Divider()
                pauseSection
                if !editedIdleDecisions.isEmpty {
                    Divider()
                    idleDecisionsSection
                }
                Divider()
                noteSection
                Divider()
                computedSection
                Divider()
                actionSection
            }
            .padding(20)
        }
        .onChange(of: entry.id) {
            resetFields()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text(weekdayString)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(statusLabel)
            .font(.system(size: 11, weight: .semibold))
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusLabel: String {
        switch entry.status {
        case .running: return String(localized: "state.running")
        case .paused: return String(localized: "state.paused")
        case .ended: return String(localized: "state.ended")
        }
    }

    private var statusColor: Color {
        switch entry.status {
        case .running: return DesignTokens.Colors.accentGreen
        case .paused: return DesignTokens.Colors.accentOrange
        case .ended: return DesignTokens.Colors.accentBlue
        }
    }

    // MARK: - Time

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "logEditor.times"))
                .font(.system(size: 12, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "logEditor.start"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "", selection: $editedStart,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .onChange(of: editedStart) { _, _ in hasChanges = true }
                }

                if entry.endTime != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "logEditor.end"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        DatePicker(
                            "", selection: $editedEnd,
                            in: editedStart...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .onChange(of: editedEnd) { _, _ in hasChanges = true }
                    }
                }
            }
        }
    }

    // MARK: - Pause

    private var pauseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "logEditor.manualPause"))
                .font(.system(size: 12, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Stepper(value: $editedPauseHours, in: 0...8) {
                        Text("\(editedPauseHours)h")
                            .monospacedDigit()
                            .frame(width: 30, alignment: .trailing)
                    }
                    .onChange(of: editedPauseHours) { _, _ in hasChanges = true }
                }

                HStack(spacing: 4) {
                    Stepper(value: $editedPauseMinutes, in: 0...59) {
                        Text("\(editedPauseMinutes)m")
                            .monospacedDigit()
                            .frame(width: 35, alignment: .trailing)
                    }
                    .onChange(of: editedPauseMinutes) { _, _ in hasChanges = true }
                }
            }
        }
    }

    // MARK: - Idle Decisions

    private var idleDecisionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "logEditor.idleDecisions"))
                .font(.system(size: 12, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            ForEach(Array(editedIdleDecisions.enumerated()), id: \.element.id) { index, decision in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            "\(decision.idleStart.hoursMinutesString) → \(decision.idleEnd.hoursMinutesString)"
                        )
                        .font(.system(size: 12, design: .rounded))
                        .monospacedDigit()

                        Text(decision.duration.hoursMinutesFormatted)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Picker("", selection: $editedIdleDecisions[index].decision) {
                        Text(String(localized: "logEditor.work"))
                            .tag(IdleDecision.Decision.work)
                        Text(String(localized: "logEditor.pause"))
                            .tag(IdleDecision.Decision.pause)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                    .onChange(of: editedIdleDecisions[index].decision) { _, _ in
                        hasChanges = true
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            decision.decision == .pause
                                ? DesignTokens.Colors.accentOrange.opacity(0.08)
                                : DesignTokens.Colors.accentGreen.opacity(0.08)
                        )
                )
            }
        }
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "logEditor.note"))
                .font(.system(size: 12, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            TextEditor(text: $editedNote)
                .font(.system(size: 13))
                .frame(minHeight: 60, maxHeight: 100)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2))
                )
                .onChange(of: editedNote) { _, _ in hasChanges = true }
        }
    }

    // MARK: - Computed Values (readonly)

    private var computedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "logEditor.computed"))
                .font(.system(size: 12, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            let previewEntry = buildPreviewEntry()
            let calc = BreakCalculator()
            let gross = previewEntry.grossTime
            let workBeforeAuto = previewEntry.workTimeBeforeAutoBreak
            let autoBrk = calc.autoBreak(
                forWorkTime: workBeforeAuto,
                alreadyPaused: previewEntry.totalPause
            )
            let net = max(0, workBeforeAuto - autoBrk)

            HStack(spacing: 24) {
                computedItem(
                    label: String(localized: "logEditor.grossTime"),
                    value: gross.hoursMinutesFormatted
                )
                computedItem(
                    label: String(localized: "logEditor.autoBreak"),
                    value: autoBrk.hoursMinutesFormatted
                )
                computedItem(
                    label: String(localized: "logEditor.netTime"),
                    value: net.hoursMinutesFormatted
                )
            }
        }
    }

    private func computedItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 70)
    }

    // MARK: - Actions

    private var actionSection: some View {
        HStack {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label(String(localized: "logEditor.delete"), systemImage: "trash")
            }
            .confirmationDialog(
                String(localized: "logEditor.deleteConfirm"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "logEditor.delete"), role: .destructive) {
                    onDelete(entry.date)
                }
            }

            Spacer()

            Button(String(localized: "logEditor.save")) {
                save()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasChanges || !isValid)
        }
    }

    // MARK: - Helpers

    private var isValid: Bool {
        if entry.endTime != nil {
            return editedStart < editedEnd
        }
        return true
    }

    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: entry.date) else { return "" }
        let weekday = DateFormatter()
        weekday.dateFormat = "EEEE"
        return weekday.string(from: date)
    }

    private func buildPreviewEntry() -> TimeEntry {
        var preview = entry
        preview.startTime = editedStart
        if entry.endTime != nil {
            preview.endTime = editedEnd
        }
        preview.manualPauseSeconds = TimeInterval(editedPauseHours * 3600 + editedPauseMinutes * 60)
        preview.idleDecisions = editedIdleDecisions
        return preview
    }

    private func save() {
        var updated = entry
        updated.startTime = editedStart
        if entry.endTime != nil {
            updated.endTime = editedEnd
        }
        updated.manualPauseSeconds = TimeInterval(
            editedPauseHours * 3600 + editedPauseMinutes * 60)
        updated.idleDecisions = editedIdleDecisions
        updated.note = editedNote
        persistence.save(updated)
        entry = updated
        hasChanges = false
        onSave(updated)
    }

    private func resetFields() {
        editedStart = entry.startTime
        editedEnd = entry.endTime ?? Date()
        editedPauseHours = Int(entry.manualPauseSeconds) / 3600
        editedPauseMinutes = (Int(entry.manualPauseSeconds) % 3600) / 60
        editedNote = entry.note
        editedIdleDecisions = entry.idleDecisions
        hasChanges = false
    }
}
