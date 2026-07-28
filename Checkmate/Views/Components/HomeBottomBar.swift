import SwiftUI

/// Figma 571:10199–10205 — bottom chrome (icon tabs + FAB).
struct HomeBottomBar: View {
    @Binding var selectedTab: AppTab
    var onAdd: () -> Void
    @Environment(\.homePageTuning) private var tuning

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            tabPill
            Spacer(minLength: CGFloat(tuning.navItemSpacing))
            addButton
        }
        .padding(.horizontal, 24)
    }

    private var tabPill: some View {
        HStack(spacing: CGFloat(tuning.navItemSpacing)) {
            tabIcon(.myTodo, asset: .noteTab)
            tabIcon(.friends, asset: .friendsTab)
        }
        .padding(.horizontal, 20)
        .frame(height: CGFloat(tuning.navControlSize))
        .background(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .fill(Color.white)
                .tabBarShadow()
                .overlay(
                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                        .stroke(Color.black.opacity(0.03), lineWidth: 1)
                )
        )
    }

    private enum TabAsset {
        case noteTab, friendsTab
    }

    private func tabIcon(_ tab: AppTab, asset: TabAsset) -> some View {
        let selected = selectedTab == tab
        return Button {
            withAnimation(Theme.spring) { selectedTab = tab }
        } label: {
            ZStack {
                Group {
                    switch asset {
                    case .noteTab:
                        FigmaIcon.noteTab(size: CGFloat(tuning.navIconSize))
                    case .friendsTab:
                        FigmaIcon.friendsTab(size: CGFloat(tuning.navIconSize))
                    }
                }
                .opacity(selected ? 1 : 0.45)
            }
            .frame(
                width: CGFloat(tuning.navIconSize),
                height: CGFloat(tuning.navControlSize)
            )
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button(action: onAdd) {
            ZStack {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(Theme.Palette.dark)
                    .tabBarShadow()
                    .overlay(
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .stroke(Color.black.opacity(0.03), lineWidth: 1)
                    )
                FigmaIcon.addFAB(size: CGFloat(tuning.fabIconSize))
            }
            .frame(
                width: CGFloat(tuning.navControlSize),
                height: CGFloat(tuning.navControlSize)
            )
        }
        .buttonStyle(BoopButtonStyle())
    }
}

enum AppTab: Hashable {
    case myTodo, friends
}
