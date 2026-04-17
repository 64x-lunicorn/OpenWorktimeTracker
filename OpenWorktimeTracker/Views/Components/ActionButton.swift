import SwiftUI

struct ActionButton: View {
    let title: String
    let icon: String
    let style: Style
    let action: () -> Void

    enum Style {
        case primary
        case secondary
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(DesignTokens.Typography.labelLarge)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }

    private var background: some ShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.accentBlue,
                        DesignTokens.Colors.accentBlue.opacity(0.85),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .secondary:
            return AnyShapeStyle(DesignTokens.Colors.surfaceContainerHigh)
        }
    }

    private var foreground: Color {
        switch style {
        case .primary: return .white
        case .secondary: return DesignTokens.Colors.onSurface
        }
    }
}
