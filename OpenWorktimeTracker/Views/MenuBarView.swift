import SwiftUI

struct MenuBarView: View {
    @Environment(WorkdayManager.self) private var manager
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider().opacity(0.15)

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Timer HUD
                    TimerDisplayView()

                    // Metric Cards
                    MetricCardsView()

                    // Week History
                    WeekHistoryView()

                    // Summary Statistics
                    SummaryStatsView()

                    // Note
                    noteSection

                    // Actions
                    actionButtons
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .frame(width: DesignTokens.popoverWidth, height: DesignTokens.popoverMinHeight)
        .background(DesignTokens.Colors.surface)
        .environment(manager)
        .onAppear {
            manager.bootstrap()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    String(
                        format: String(localized: "menubar.workday"),
                        manager.currentEntry?.date ?? Date().dateString)
                )
                .font(DesignTokens.Typography.headlineSmall)
                .foregroundStyle(DesignTokens.Colors.onSurface)

                Text(manager.state.localizedLabel)
                    .font(DesignTokens.Typography.labelSmall)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(stateColor)
            }

            Spacer()

            statusBadge
        }
        .padding(DesignTokens.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("menubar.accessibility.header"))
        .accessibilityValue(Text(manager.state.localizedLabel))
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            if manager.state == .running {
                Circle()
                    .fill(DesignTokens.Colors.accentGreen)
                    .frame(width: 6, height: 6)
            }
            Text(manager.state.localizedLabel)
                .font(DesignTokens.Typography.labelMicro)
                .textCase(.uppercase)
                .tracking(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(stateColor.opacity(0.15))
        .clipShape(Capsule())
        .foregroundStyle(stateColor)
    }

    // MARK: - Note

    @State private var noteText = ""

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("menubar.note")
                .font(DesignTokens.Typography.labelSmall)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                .textCase(.uppercase)
                .tracking(1.5)

            TextField(
                String(localized: "menubar.note.placeholder"), text: $noteText, axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(DesignTokens.Typography.bodySmall)
            .lineLimit(2...4)
            .padding(DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            .onChange(of: noteText) { _, newValue in
                manager.updateNote(newValue)
            }
            .onAppear {
                noteText = manager.currentEntry?.note ?? ""
            }
            .onChange(of: manager.currentEntry?.id) { _, _ in
                noteText = manager.currentEntry?.note ?? ""
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if manager.state == .running {
                    ActionButton(
                        title: String(localized: "menubar.pause"), icon: "pause.fill",
                        style: .secondary
                    ) {
                        manager.pause()
                    }
                } else if manager.state == .paused {
                    ActionButton(
                        title: String(localized: "menubar.resume"), icon: "play.fill",
                        style: .secondary
                    ) {
                        manager.resume()
                    }
                }

                if manager.state == .running || manager.state == .paused {
                    ActionButton(
                        title: String(localized: "menubar.endDay"), icon: "stop.fill",
                        style: .primary
                    ) {
                        manager.endDay()
                    }
                }
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                if manager.state == .ended {
                    ActionButton(
                        title: String(localized: "menubar.restart"), icon: "arrow.counterclockwise",
                        style: .secondary
                    ) {
                        manager.restartDay()
                    }
                }

                Menu {
                    Button(String(localized: "menubar.openLogFolder")) {
                        NSWorkspace.shared.open(manager.persistence.logDirectory)
                    }
                    Button(String(localized: "menubar.exportCSV")) {
                        if let url = manager.persistence.exportCSV() {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Divider()
                    Button(String(localized: "menubar.settings")) {
                        openSettings()
                    }
                    .keyboardShortcut(",", modifiers: .command)
                    Divider()
                    Button(String(localized: "menubar.quit")) {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "ellipsis.circle")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignTokens.Colors.surfaceContainerHigh)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                }
                .menuStyle(.borderlessButton)
            }
        }
    }

    // MARK: - Helpers

    private var stateColor: Color {
        switch manager.state {
        case .notStarted: return DesignTokens.Colors.onSurfaceVariant
        case .running: return DesignTokens.Colors.accentGreen
        case .paused: return DesignTokens.Colors.accentOrange
        case .ended: return DesignTokens.Colors.accentBlue
        }
    }
}
