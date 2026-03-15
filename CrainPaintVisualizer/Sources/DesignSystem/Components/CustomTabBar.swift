import SwiftUI

struct CustomTabBar: View {
    @Environment(Theme.self) private var theme
    @Binding var selectedTab: AppTab
    let onDoubleTap: (AppTab) -> Void

    @Namespace private var pillNamespace

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.space4) {
                ForEach(AppTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, theme.space8)
            .padding(.vertical, theme.space4)
            .background(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .fill(theme.card.opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radiusLG)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 10, y: -2)
            )
            .padding(.horizontal, theme.space12)
            .padding(.top, theme.space4)
            .sensoryFeedback(.selection, trigger: selectedTab)
        }
        .padding(.bottom, max(safeAreaBottom, theme.space8))
        .background(
            LinearGradient(
                colors: [theme.background.opacity(0), theme.background.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("app.tabBar")
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if selectedTab == tab {
                onDoubleTap(tab)
            } else {
                withAnimation(.easeInOut(duration: 0.18)) {
                    selectedTab = tab
                }
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(theme.primary.opacity(0.12))
                            .frame(width: 68, height: 32)
                            .matchedGeometryEffect(id: "activeTabPill", in: pillNamespace)
                    } else {
                        Color.clear
                            .frame(width: 68, height: 32)
                    }

                    Image(systemName: isSelected ? tab.iconFilled : tab.iconOutlined)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? theme.actionPrimaryPressed : theme.textTertiary)
                        .frame(width: 68, height: 32)
                }

                Text(tab.title)
                    .font(theme.micro.weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? theme.actionPrimaryPressed : theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityIdentifier(tab.accessibilityIdentifier)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var safeAreaBottom: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0)
    }
}

private extension AppTab {
    var accessibilityIdentifier: String {
        switch self {
        case .preview:
            return "app.tab.preview"
        case .library:
            return "app.tab.library"
        case .more:
            return "app.tab.more"
        }
    }
}
