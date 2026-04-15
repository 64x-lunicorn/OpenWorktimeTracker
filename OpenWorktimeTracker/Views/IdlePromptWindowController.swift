import AppKit
import SwiftUI

/// Manages a free-floating NSPanel for the idle prompt.
/// Shown as a top-level window independent of the menu bar popover.
final class IdlePromptWindowController {
    static let shared = IdlePromptWindowController()

    private var panel: NSPanel?

    private init() {}

    func show(promptInfo: IdlePromptInfo, manager: WorkdayManager) {
        // Dismiss any existing panel first
        dismiss()

        let promptView = IdlePromptView(
            promptInfo: promptInfo,
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )
        .environment(manager)

        let hostingView = NSHostingView(rootView: promptView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 340),
            styleMask: [.titled, .closable, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        panel.title =
            promptInfo.spansMidnight
            ? String(localized: "idle.panel.newWorkday")
            : String(localized: "idle.panel.inactivity")
        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true

        // Size to content
        if let contentView = panel.contentView {
            let fittingSize = contentView.fittingSize
            let frameSize = panel.frameRect(
                forContentRect: NSRect(origin: .zero, size: fittingSize)
            ).size
            panel.setContentSize(fittingSize)
            panel.setFrame(
                NSRect(
                    origin: panel.frame.origin,
                    size: frameSize
                ),
                display: false
            )
        }

        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.panel = panel
    }

    func dismiss() {
        panel?.close()
        panel = nil
    }
}
