import SwiftUI

// MARK: - Palette

/// The accent colours the app and the widget paint a Workday with, plus the
/// muted `secondary` for text and a Workday not yet started. The one place their
/// light and dark values live.
enum PaletteColor: CaseIterable {
    case blue
    case green
    case orange
    case red
    case secondary

    var color: Color {
        switch self {
        case .blue: return Values.blue
        case .green: return Values.green
        case .orange: return Values.orange
        case .red: return Values.red
        case .secondary: return Values.secondary
        }
    }

    private enum Values {
        static let blue = Color(light: .init(hex: 0x0058BC), dark: .init(hex: 0x007AFF))
        static let green = Color(light: .init(hex: 0x006B27), dark: .init(hex: 0x34C759))
        static let orange = Color(light: .init(hex: 0x995000), dark: .init(hex: 0xFF9500))
        static let red = Color(light: .init(hex: 0xBA1A1A), dark: .init(hex: 0xFF453A))
        static let secondary = Color(light: .init(hex: 0x414755), dark: .init(hex: 0xC1C6D7))
    }
}

// MARK: - Tracking State

extension WorkdayState {
    /// The colour of the tracking state on its own, before any Threshold Level.
    var accent: PaletteColor {
        switch self {
        case .notStarted: return .secondary
        case .running: return .green
        case .paused: return .orange
        case .ended: return .blue
        }
    }

    /// The app's label key.
    var labelKey: String {
        "state.\(rawValue)"
    }

    /// Resolves in the app's bundle.
    var localizedLabel: String {
        String(localized: String.LocalizationValue(labelKey))
    }

    /// The widget keeps its own, shorter wording under its own keys.
    var widgetLabelKey: String {
        switch self {
        case .notStarted: return "widget.state.idle"
        case .running, .paused, .ended: return "widget.state.\(rawValue)"
        }
    }

    /// Resolves in the widget extension's bundle.
    var widgetLabel: String {
        String(localized: String.LocalizationValue(widgetLabelKey))
    }
}

// MARK: - Threshold Level

extension ThresholdLevel {
    /// The accent a Workday's Net Work Time is painted with at this level.
    var accent: PaletteColor {
        switch self {
        case .normal: return .blue
        case .elevated: return .orange
        case .critical: return .red
        }
    }

    /// `nil` leaves the menu bar to its native, wallpaper-aware rendering.
    var menuBarAccent: PaletteColor? {
        self == .normal ? nil : accent
    }
}

// MARK: - Workday Appearance

/// How a Workday looks for a tracking state at a Threshold Level.
struct WorkdayAppearance: Equatable {
    let state: WorkdayState
    let level: ThresholdLevel

    /// Elevated and critical Threshold Levels take over from the tracking state.
    var indicator: PaletteColor {
        level == .normal ? state.accent : level.accent
    }

    /// Progress toward the daily goal stays green until the Threshold Ladder is reached.
    var progress: PaletteColor {
        level == .normal ? .green : indicator
    }
}
