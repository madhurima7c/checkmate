import SwiftUI
import Supabase

struct ContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: Profile?
    @State private var contacts: [Profile] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var inviteEmail = ""
    @State private var showInviteField = false

    var filteredContacts: [Profile] {
        guard !searchText.isEmpty else { return contacts }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredContacts) { contact in
                    Button {
                        selected = contact
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(uiColor: .systemGray4))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(contact.name.prefix(1).uppercased())
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                )
                            Text(contact.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selected?.id == contact.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.checkmateBlue)
                            }
                        }
                    }
                }

                Section {
                    if showInviteField {
                        HStack {
                            TextField("Email address", text: $inviteEmail)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                            Button("Invite") { sendInvite() }
                                .foregroundStyle(Color.checkmateBlue)
                                .disabled(inviteEmail.isEmpty)
                        }
                    } else {
                        Button("Invite someone new…") {
                            showInviteField = true
                        }
                        .foregroundStyle(Color.checkmateBlue)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search")
            .navigationTitle("Send to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await loadContacts() }
        }
    }

    private func loadContacts() async {
        guard let userId = AuthService.shared.currentUserId else { return }
        isLoading = true
        // Load all profiles except current user
        // In production, scope this to accepted connections only
        let profiles: [Profile] = (try? await SupabaseClient.shared
            .from("profiles")
            .select()
            .neq("id", value: userId.uuidString)
            .order("name")
            .execute()
            .value) ?? []
        contacts = profiles
        isLoading = false
    }

    private func sendInvite() {
        // Post-MVP: send Supabase magic link to inviteEmail
        // For now, show confirmation
        showInviteField = false
        inviteEmail = ""
    }
}
