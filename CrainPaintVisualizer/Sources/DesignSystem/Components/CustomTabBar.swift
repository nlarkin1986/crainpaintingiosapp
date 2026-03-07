import SwiftUI

struct CustomTabBar: View {
    @Environment(Theme.self) private var theme
    @Binding var selectedTab: AppTab
    let onDoubleTap: (AppTab) -> Void

    @Namespace private var pillNamespace
    @State private var hoverTab: AppTab?

    var body: some View {
        VStack(spacing: 0) {
            // Subtle top divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.border.opacity(0.3),
                            theme.border.opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
            
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, theme.space12)
            .padding(.top, theme.space12)
            .padding(.bottom, theme.space8)
        }
        .padding(.bottom, safeAreaBottom)
        .background {
            // Premium frosted glass with clean white base
            ZStack {
                Color.white.opacity(0.95)
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
            .shadow(color: .black.opacity(0.04), radius: 1, y: -1)
            .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if selectedTab == tab {
                onDoubleTap(tab)
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    selectedTab = tab
                }
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Premium animated pill indicator
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ColorTokens.aquaSubtle,
                                        ColorTokens.aquaSubtle.opacity(0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 68, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        ColorTokens.aqua.opacity(0.2),
                                        lineWidth: 1.5
                                    )
                            )
                            .matchedGeometryEffect(id: "activeTabPill", in: pillNamespace)
                            .shadow(color: ColorTokens.aqua.opacity(0.1), radius: 6, y: 2)
                    } else {
                        Color.clear
                            .frame(width: 68, height: 36)
                    }

                    // Icon with enhanced visuals
                    Image(systemName: isSelected ? tab.iconFilled : tab.iconOutlined)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected 
                                ? ColorTokens.aqua
                                : theme.textTertiary
                        )
                        .symbolEffect(.bounce.up.byLayer, value: isSelected)
                        .frame(width: 68, height: 36)
                }

                // Tab label with improved typography
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(
                        isSelected 
                            ? ColorTokens.aquaDark
                            : theme.textTertiary
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var safeAreaBottom: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0)
    }
}
