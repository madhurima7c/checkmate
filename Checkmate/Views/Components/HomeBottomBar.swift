import SwiftUI

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
        .padding(.bottom, 8)
    }

    private var tabPill: some View {
        HStack(spacing: 0) {
            tabItem(.myTodo, icon: "NoteBlank", label: "To-do")
            tabItem(.friends, icon: "UsersTab", label: "Friends")
        }
        .padding(4)
        .frame(width: 123, height: 52)
        .background(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.07), radius: 4.5, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                        .stroke(Color.black.opacity(0.03), lineWidth: 1)
                )
        )
    }

    private func tabItem(_ tab: AppTab, icon: String, label: String) -> some View {
        let selected = selectedTab == tab
        return Button {
            withAnimation(Theme.spring) { selectedTab = tab }
        } label: {
            VStack(spacing: 1) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 27, height: 27)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(-0.1)
            }
            .foregroundStyle(selected ? Color(hex: 0x393834) : Color(hex: 0x1A1916).opacity(0.45))
            .frame(width: 57, height: 44)
            .background(
                Group {
                    if selected {
                        Capsule().fill(Color(hex: 0xEDEDED))
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button(action: onAdd) {
            ZStack {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(Theme.Palette.dark)
                    .shadow(color: .black.opacity(0.07), radius: 4.5, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .stroke(Color.black.opacity(0.03), lineWidth: 1)
                    )
                Image("PlusFab")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
            }
            .frame(width: 52, height: 52)
        }
        .buttonStyle(BoopButtonStyle())
    }
}

enum AppTab: Hashable {
    case myTodo, friends
}
