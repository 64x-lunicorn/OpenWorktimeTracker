import AppKit
import SwiftUI
import XCTest

@testable import OpenWorktimeTracker

final class ViewLayoutTests: XCTestCase {
    @MainActor
    func testNativeApplicationPreservesEditingShortcuts() throws {
        let delegate = AppDelegate()
        let menu = delegate.makeMainMenu()
        let appMenu = try XCTUnwrap(menu.items.first?.submenu)
        XCTAssertEqual(appMenu.items.first?.keyEquivalent, ",")
        XCTAssertTrue(appMenu.items.first?.target === delegate)
        let editMenu = try XCTUnwrap(menu.items.dropFirst().first?.submenu)
        for (item, expected) in zip(editMenu.items, [
            ("undo:", "z"), ("redo:", "Z"), ("cut:", "x"),
            ("copy:", "c"), ("paste:", "v"), ("selectAll:", "a")
        ]) {
            XCTAssertEqual(item.action, Selector(expected.0))
            XCTAssertEqual(item.keyEquivalent, expected.1)
            XCTAssertNil(item.target)
        }
        XCTAssertEqual(editMenu.items.count, 6)
    }

    @MainActor
    func testNativeStatusButtonOpensAndClosesExistingDashboard() async throws {
        XCTAssertTrue(NSApp.delegate is AppDelegate)
        let manager = WorkdayManager(store: InMemoryDailyLogStore())
        let controller = MenuBarController(manager: manager)
        let button = try XCTUnwrap(controller.statusItem.button)
        XCTAssertTrue(button.target === controller)
        XCTAssertNotNil(button.action)
        XCTAssertFalse(controller.popover.isShown)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertTrue(button.sendAction(button.action, to: button.target))
        for _ in 0..<30 where !controller.popover.isShown {
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertTrue(controller.popover.isShown)
        XCTAssertEqual(
            controller.popover.contentSize,
            NSSize(width: DesignTokens.popoverWidth, height: DesignTokens.popoverMinHeight))
        XCTAssertTrue(button.sendAction(button.action, to: button.target))
        for _ in 0..<30 where controller.popover.isShown {
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertFalse(controller.popover.isShown)
        XCTAssertEqual(manager.state, .notStarted)
    }

    @MainActor
    func testPromptsFitInCompactWindowsInBothAppearances() throws {
        let manager = WorkdayManager(store: InMemoryDailyLogStore())
        let end = Date(timeIntervalSince1970: 1_800_000_000)
        for language in ["de", "en"] {
            for dark in [false, true] {
                for midnight in [false, true] {
                    let period = IdlePeriod(
                        idleStart: end.addingTimeInterval(midnight ? -50_400 : -2_700),
                        idleEnd: end, spansMidnight: midnight)
                    try assertLayout(
                        IdlePromptView(idlePeriod: period).environment(manager),
                        name: "idle-\(language)-\(dark)-\(midnight)",
                        language: language, dark: dark,
                        bounds: CGSize(width: DesignTokens.promptWidth, height: 640))
                }
                try assertLayout(
                    MaxHoursPromptView(hours: 10).environment(manager),
                    name: "max-hours-\(language)-\(dark)",
                    language: language, dark: dark,
                    bounds: CGSize(width: DesignTokens.promptWidth, height: 480))
            }
        }
    }

    @MainActor
    func testMetricCardsFitPopoverWidthBeforeStarting() throws {
        let manager = WorkdayManager(store: InMemoryDailyLogStore())
        for language in ["de", "en"] {
            try assertLayout(
                MetricCardsView().environment(manager)
                    .frame(width: DesignTokens.popoverWidth - 2 * DesignTokens.Spacing.lg),
                name: "metrics-not-started-\(language)", language: language, dark: false,
                bounds: CGSize(
                    width: DesignTokens.popoverWidth - 2 * DesignTokens.Spacing.lg, height: 250))
        }
    }

    @MainActor
    func testLogEditorFitsNarrowDetailColumn() throws {
        let manager = WorkdayManager(store: InMemoryDailyLogStore())
        var entry = TimeEntry(startTime: Date(timeIntervalSince1970: 1_700_000_000))
        entry.endTime = entry.startTime.addingTimeInterval(8 * 3600)
        entry.status = .ended
        try assertLayout(
            LogEntryEditView(entry: entry, manager: manager, onSave: { _ in }, onDelete: { _ in })
                .frame(width: 380, height: 450),
            name: "log-editor-narrow", language: "de", dark: false,
            bounds: CGSize(width: 380, height: 450))
    }

    @MainActor
    private func assertLayout<Content: View>(
        _ content: Content, name: String, language: String, dark: Bool,
        bounds: CGSize
    ) throws {
        let host = NSHostingView(rootView: content
            .background(DesignTokens.Colors.surface)
            .environment(\.locale, Locale(identifier: language))
            .environment(\.colorScheme, dark ? .dark : .light))
        host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        let size = host.fittingSize
        XCTAssertEqual(size.width, bounds.width, accuracy: 1, name)
        XCTAssertGreaterThan(size.height, 0, name)
        XCTAssertLessThanOrEqual(size.height, bounds.height, name)
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let data = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
