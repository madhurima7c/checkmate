import SwiftUI

/// Figma 571:10199–10205 — bottom chrome (icon tabs + FAB).
struct HomeBottomBar: View {
    @Binding var selectedTab: AppTab
    var onAdd: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            tabPill
            Spacer(minLength: 16)
            addButton
        }
        .padding(.horizontal, 24)
    }

    private var tabPill: some View {
        HStack(spacing: 0) {
            tabIcon(.myTodo, asset: .noteTab)
            tabIcon(.friends, asset: .friendsTab)
        }
        .padding(4)
        .frame(width: 123, height: 52)
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
                        FigmaIcon.noteTab(size: 27)
                    case .friendsTab:
                        FigmaIcon.friendsTab(size: 27)
                    }
                }
                .opacity(selected ? 1 : 0.45)
            }
            .frame(width: 57, height: 44)
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
                FigmaIcon.addFAB(size: 25)
            }
            .frame(width: 52, height: 52)
        }
        .buttonStyle(BoopButtonStyle())
    }
}

enum AppTab: Hashable {
    case myTodo, friends
}
