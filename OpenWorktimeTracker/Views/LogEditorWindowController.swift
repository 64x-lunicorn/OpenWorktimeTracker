import AppKit
import SwiftUI

final class LogEditorWindowController {
    static let shared = LogEditorWindowController()

    private var window: NSWindow?

    private init() {}

    func show(manager: WorkdayManager) {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let editorView = LogEditorView(
            persistence: manager.persistence,
            manager: manager
        )
        let hostingView = NSHostingView(rootView: editorView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = String(localized: "logEditor.title")
        window.contentView = hostingView
        window.minSize = NSSize(width: 550, height: 400)
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func dismiss() {
        window?.close()
        window = nil
    }
}
