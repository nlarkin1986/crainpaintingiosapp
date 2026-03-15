import SwiftUI

enum StepProgressStyle {
    case classic
    case pill
}

struct StepProgressView: View {
    @Environment(Theme.self) private var theme

    let steps: [String]
    let currentStep: Int
    var style: StepProgressStyle = .classic
    var icons: [String]? = nil

    var body: some View {
        switch style {
        case .classic:
            classicBody
        case .pill:
            pillBody
        }
    }

    private var classicBody: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(circleFill(for: index))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(index == currentStep ? theme.stepCurrent : .clear, lineWidth: 2)
                            )
                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        } else if let icons, index < icons.count {
                            Image(systemName: icons[index])
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(index == currentStep ? theme.primary : theme.mutedForeground)
                        } else {
                            Text("\(index + 1)")
                                .font(theme.subhead)
                                .foregroundStyle(index == currentStep ? theme.primary : theme.mutedForeground)
                        }
                    }
                    Text(step.uppercased())
                        .font(theme.micro)
                        .tracking(0.5)
                        .foregroundStyle(index <= currentStep ? theme.foreground : theme.mutedForeground)
                        .lineLimit(1)
                }

                if index < steps.count - 1 {
                    VStack {
                        Rectangle()
                            .fill(index < currentStep ? theme.primary : theme.border)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, theme.spacingXS)
                        Spacer().frame(height: 18)
                    }
                }
            }
        }
        .padding(.horizontal, theme.spacingMD)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
    }

    private var pillBody: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                if index > 0 {
                    Rectangle()
                        .fill(index <= currentStep ? theme.primary : theme.border)
                        .frame(height: 1)
                        .frame(maxWidth: 12)
                }

                HStack(spacing: theme.space4) {
                    if index < currentStep {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                    }
                    Text(step)
                        .font(theme.label)
                        .fontWeight(index == currentStep ? .semibold : .regular)
                }
                .foregroundStyle(pillTextColor(for: index))
                .padding(.horizontal, theme.space12)
                .padding(.vertical, theme.space4)
                .background(pillBackground(for: index))
                .clipShape(Capsule())
                .shadow(
                    color: index == currentStep ? theme.actionPrimary.opacity(0.3) : .clear,
                    radius: index == currentStep ? 6 : 0,
                    y: 0
                )
            }
        }
        .padding(.horizontal, theme.spacingMD)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
        .animation(Theme.animationDefault, value: currentStep)
    }

    @ViewBuilder
    private func pillBackground(for index: Int) -> some View {
        if index < currentStep {
            theme.primary
        } else if index == currentStep {
            theme.ctaGradient
        } else {
            theme.muted
        }
    }

    private func pillTextColor(for index: Int) -> Color {
        if index <= currentStep {
            return .white
        }
        return theme.mutedForeground
    }

    private func circleFill(for index: Int) -> Color {
        if index < currentStep { return theme.stepComplete }
        if index == currentStep { return .white }
        return theme.stepUpcoming
    }

}
