import SwiftUI

struct ActionButton: View {
    let title: String
    let icon: String
    let style: Style
    var subtitle: String?
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case tinted(Color)
    }

    var body: some View {
        switch style {
        case .primary:
            button
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.Colors.accentBlue)
        case .secondary, .tinted:
            button
                .buttonStyle(.bordered)
                .tint(tint)
        }
    }

    private var button: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(title)
                        .font(DesignTokens.Typography.labelLarge)
                    if let subtitle {
                        Text(subtitle)
                            .font(DesignTokens.Typography.bodySmall)
                    }
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 28, alignment: subtitle == nil ? .center : .leading)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .foregroundStyle(foreground)
        }
        .controlSize(.large)
    }

    private var tint: Color {
        switch style {
        case .primary: return DesignTokens.Colors.accentBlue
        case .secondary: return DesignTokens.Colors.surfaceContainerHigh
        case .tinted(let color): return color
        }
    }

    private var foreground: Color {
        switch style {
        case .primary: return DesignTokens.Colors.onAccent
        case .secondary: return DesignTokens.Colors.onSurface
        case .tinted(let color): return color
        }
    }
}
