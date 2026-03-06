import SwiftUI

struct CustomTabBar: View {
    @Environment(Theme.self) private var theme
    @Binding var selectedTab: AppTab
    let onDoubleTap: (AppTab) -> Void

    @Namespace private var pillNamespace

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, theme.space8)
            .padding(.top, theme.space8)
            .padding(.bottom, theme.space4)
        }
        .padding(.bottom, safeAreaBottom)
        .background {
            // Frosted glass material with a subtle top shadow
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if selectedTab == tab {
                onDoubleTap(tab)
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedTab = tab
                }
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    // Sliding pill indicator using matchedGeometryEffect
                    if isSelected {
                        Capsule()
                            .fill(theme.accentSubtle)
                            .frame(width: 64, height: 32)
                            .matchedGeometryEffect(id: "activeTabPill", in: pillNamespace)
                    } else {
                        Color.clear
                            .frame(width: 64, height: 32)
                    }

                    Image(systemName: isSelected ? tab.iconFilled : tab.iconOutlined)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? theme.actionPrimaryPressed : theme.textTertiary)
                        .symbolEffect(.bounce.byLayer, value: isSelected)
                        .frame(width: 64, height: 32)
                }

                Text(tab.title)
                    .font(.caption2.weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? theme.actionPrimaryPressed : theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
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
