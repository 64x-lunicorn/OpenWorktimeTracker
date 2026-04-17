import SwiftUI

#if canImport(AppKit)
    import AppKit

    extension Color {
        init(hex: UInt, alpha: Double = 1.0) {
            self.init(
                .sRGB,
                red: Double((hex >> 16) & 0xFF) / 255.0,
                green: Double((hex >> 8) & 0xFF) / 255.0,
                blue: Double(hex & 0xFF) / 255.0,
                opacity: alpha
            )
        }

        init(light: Color, dark: Color) {
            self.init(
                nsColor: NSColor(
                    name: nil,
                    dynamicProvider: { appearance in
                        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                        return isDark ? NSColor(dark) : NSColor(light)
                    }))
        }
    }
#endif
