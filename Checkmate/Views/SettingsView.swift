import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthService.shared

    // Local persistence for MVP — these will round-trip to Supabase
    // / NotificationService once the surface stabilizes.
    @AppStorage("notif.master") private var notifMaster = true
    @AppStorage("notif.assignedToMe") private var notifAssigned = true
    @AppStorage("notif.reminders") private var notifReminders = true
    @AppStorage("notif.dailySummaryHour") private var dailySummaryHour = 9
    @AppStorage("defaults.color") private var defaultColorRaw = StickyColor.yellow.rawValue
    @AppStorage("defaults.allDay") private var defaultAllDay = true
    @AppStorage(CheckmateConfig.DialKit.homePageKey) private var dialKitHomePageEnabled = false
    @AppStorage(CheckmateConfig.DialKit.todoSheetKey) private var dialKitTodoSheetEnabled = false
    @AppStorage(CheckmateConfig.DialKit.cardFocusKey) private var dialKitCardFocusEnabled = false
    @AppStorage(CheckmateConfig.DialKit.onboardingKey) private var dialKitOnboardingEnabled = false
    @AppStorage(CheckmateConfig.Onboarding.completedKey) private var onboardingCompleted = false
    @State private var showOnboardingPreview = false

    private var defaultColor: Binding<StickyColor> {
        Binding(
            get: { StickyColor(rawValue: defaultColorRaw) ?? .yellow },
            set: { defaultColorRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                notificationsSection
                defaultsSection
                dialKitSection
                onboardingSection
                friendsSection
                widgetSection
                aboutSection
                signOutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showOnboardingPreview) {
                OnboardingView()
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            HStack {
                Text("Sync mode")
                Spacer()
                Text(CheckmateConfig.isPrototype ? "Prototype (local)" : "Cloud")
                    .foregroundStyle(.secondary)
            }
            if !CheckmateConfig.pushEnabled {
                Text("Push notifications ship after Apple Developer enrollment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(uiColor: .systemGray3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text((auth.currentProfile?.name ?? "?").prefix(1).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading) {
                    Text(auth.currentProfile?.name ?? "User")
                        .font(.headline)
                    Text(auth.currentUserId?.uuidString ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("All notifications", isOn: $notifMaster)
            Toggle("Tasks assigned to me", isOn: $notifAssigned)
                .disabled(!notifMaster)
            Toggle("Reminders for my todos", isOn: $notifReminders)
                .disabled(!notifMaster)
            Stepper(value: $dailySummaryHour, in: 5...22) {
                Text("Daily summary at \(dailySummaryHour):00")
            }
            .disabled(!notifMaster)
        }
    }

    private var defaultsSection: some View {
        Section("Defaults") {
            Picker("Default color", selection: defaultColor) {
                ForEach(StickyColor.allCases) { c in
                    HStack {
                        Circle().fill(c.dot).frame(width: 14, height: 14)
                        Text(c.rawValue.capitalized)
                    }.tag(c)
                }
            }
            Toggle("New todos are All-day", isOn: $defaultAllDay)
        }
    }

    private var dialKitSection: some View {
        Section {
            Toggle("Home Page", isOn: $dialKitHomePageEnabled)
            Toggle("To-Do Sheet", isOn: $dialKitTodoSheetEnabled)
            Toggle("Press & Hold", isOn: $dialKitCardFocusEnabled)
            Toggle("Onboarding", isOn: $dialKitOnboardingEnabled)
        } header: {
            Text("DialKit")
        } footer: {
            Text("Enabled panels appear in DialKit’s drawer (use the header dropdown to switch). Disabled areas always use shipped defaults. Onboarding panels appear while the intro is open.")
        }
    }

    private var onboardingSection: some View {
        Section {
            Button {
                showOnboardingPreview = true
            } label: {
                Label("View onboarding", systemImage: "play.circle")
            }
            Button {
                onboardingCompleted = false
                dismiss()
            } label: {
                Label("Restart onboarding", systemImage: "arrow.counterclockwise.circle")
            }
        } header: {
            Text("Onboarding")
        } footer: {
            Text("View plays the intro right now. Restart clears the flag so it plays again immediately — and every time you restart.")
        }
    }

    private var friendsSection: some View {
        Section("Friends") {
            Button {
                Task { await InviteService.shared.presentInviteShareSheet() }
            } label: {
                Label("Invite a friend", systemImage: "person.crop.circle.badge.plus")
            }
        }
    }

    private var widgetSection: some View {
        Section("Widget") {
            Text("Long-press your home screen, tap Edit → Add Widget, search for Checkmate.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                Label("Refresh widget now", systemImage: "arrow.clockwise")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
            Link("Privacy", destination: URL(string: "https://checkmate.app/privacy")!)
            Link("Terms", destination: URL(string: "https://checkmate.app/terms")!)
        }
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                Task { try? await AuthService.shared.signOut() }
            } label: {
                Text("Sign out")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
