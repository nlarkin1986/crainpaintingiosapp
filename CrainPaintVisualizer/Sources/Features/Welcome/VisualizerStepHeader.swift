import SwiftUI

/// Modern, clean step navigation for the visualizer flow
/// Replaces the cramped "COLOR | PHOTO | SURFACE" header
struct VisualizerStepHeader: View {
    @Environment(Theme.self) private var theme
    
    let currentStep: VisualizerStep
    let onStepTap: (VisualizerStep) -> Void
    
    enum VisualizerStep: Int, CaseIterable, Identifiable {
        case color = 0
        case photo = 1
        case surface = 2
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .color: return "Colors"
            case .photo: return "Photo"
            case .surface: return "Surface"
            }
        }
        
        var icon: String {
            switch self {
            case .color: return "paintpalette.fill"
            case .photo: return "photo.fill"
            case .surface: return "sofa.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Step indicators
            HStack(spacing: 0) {
                ForEach(VisualizerStep.allCases) { step in
                    stepButton(for: step)
                    
                    if step.rawValue < VisualizerStep.allCases.count - 1 {
                        // Connector line
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? theme.primary : theme.border)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, theme.spacingLG)
            .padding(.vertical, theme.spacingMD)
            
            Divider()
        }
        .background(.ultraThinMaterial)
    }
    
    private func stepButton(for step: VisualizerStep) -> some View {
        let isActive = step == currentStep
        let isComplete = step.rawValue < currentStep.rawValue
        let isUpcoming = step.rawValue > currentStep.rawValue
        
        return Button {
            onStepTap(step)
        } label: {
            VStack(spacing: 8) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(isActive ? theme.primary : isComplete ? theme.stepComplete : theme.muted)
                        .frame(width: 44, height: 44)
                    
                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: step.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isActive ? .white : theme.mutedForeground)
                    }
                }
                
                // Step label
                Text(step.title)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? theme.primary : isUpcoming ? theme.mutedForeground : theme.foreground)
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 80)
        .contentShape(Rectangle())
        .accessibilityLabel(step.title)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityHint(isActive ? "Current step" : isComplete ? "Completed" : "Not yet available")
    }
}

#Preview {
    VStack {
        VisualizerStepHeader(currentStep: .color) { _ in }
        Spacer()
        VisualizerStepHeader(currentStep: .photo) { _ in }
        Spacer()
        VisualizerStepHeader(currentStep: .surface) { _ in }
    }
    .environment(Theme())
}
