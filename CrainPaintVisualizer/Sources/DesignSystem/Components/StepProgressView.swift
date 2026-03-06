import SwiftUI

struct StepProgressView: View {
    @Environment(Theme.self) private var theme

    let steps: [String]
    let currentStep: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: theme.spacingSM) {
                    ZStack {
                        Circle()
                            .fill(circleColor(for: index))
                            .frame(width: 28, height: 28)
                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(theme.micro)
                                .foregroundStyle(index == currentStep ? .white : theme.mutedForeground)
                        }
                    }
                    Text(step)
                        .font(theme.caption)
                        .foregroundStyle(index <= currentStep ? theme.foreground : theme.mutedForeground)
                }

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? theme.primary : theme.border)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, theme.spacingXS)
                }
            }
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private func circleColor(for index: Int) -> Color {
        if index < currentStep { return theme.primary }
        if index == currentStep { return theme.primary }
        return theme.muted
    }
}
