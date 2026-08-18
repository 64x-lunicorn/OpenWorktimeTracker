import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    let goalHours: Double
    var thresholdColor: Color = DesignTokens.Colors.accentBlue

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text(
                    String(
                        format: String(localized: "progress.goal"),
                        goalText)
                )
                .font(DesignTokens.Typography.labelMicro)
                .tracking(1)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)

                Spacer()

                Text("\(min(100, Int(progress * 100)))%")
                    .font(DesignTokens.Typography.labelMicro)
                    .tracking(1)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.Colors.surfaceContainerHighest.opacity(0.5))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(thresholdColor)
                        .frame(width: geometry.size.width * min(1.0, progress))
                        .shadow(color: thresholdColor.opacity(0.4), radius: 4, y: 0)
                }
            }
            .frame(height: 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("progress.accessibility.label"))
        .accessibilityValue(Text("\(min(100, Int(progress * 100)))%"))
    }

    private var goalText: String {
        let wholeHours = Int(goalHours)
        let minutes = Int((goalHours - Double(wholeHours)) * 60)
        if minutes > 0 {
            return "\(wholeHours)h \(minutes)m"
        }
        return "\(wholeHours)h"
    }
}
