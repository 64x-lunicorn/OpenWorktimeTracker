import AppKit
import Carbon.HIToolbox

final class GlobalShortcutManager {

    static let shared = GlobalShortcutManager()

    private var pauseMonitor: Any?
    private var endMonitor: Any?

    var onPauseResume: (() -> Void)?
    var onEndDay: (() -> Void)?

    func register() {
        unregister()

        // Ctrl+Option+P — Pause/Resume
        pauseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains([.control, .option]),
                event.keyCode == kVK_ANSI_P
            else { return }
            DispatchQueue.main.async {
                self?.onPauseResume?()
            }
        }

        // Ctrl+Option+E — End Day
        endMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains([.control, .option]),
                event.keyCode == kVK_ANSI_E
            else { return }
            DispatchQueue.main.async {
                self?.onEndDay?()
            }
        }
    }

    func unregister() {
        if let monitor = pauseMonitor {
            NSEvent.removeMonitor(monitor)
            pauseMonitor = nil
        }
        if let monitor = endMonitor {
            NSEvent.removeMonitor(monitor)
            endMonitor = nil
        }
    }

    deinit {
        unregister()
    }
}
