import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @State private var showEmailForm = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var error: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Checkmate")
                    .font(.system(size: 36, weight: .bold))
                Text("Tasks for you and your people.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleResult(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(10)

                Button {
                    showEmailForm.toggle()
                } label: {
                    Text("Continue with Email")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showEmailForm) {
            emailFormSheet
        }
    }

    private var emailFormSheet: some View {
        NavigationStack {
            Form {
                if isSignUp {
                    Section {
                        TextField("Your name", text: $name)
                    }
                }
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                }
                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEmailForm = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button(isSignUp ? "Create" : "Sign In") {
                            Task { await submitEmail() }
                        }
                        .disabled(email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty))
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(isSignUp ? "Already have an account? Sign in" : "No account? Create one") {
                        isSignUp.toggle()
                        error = nil
                    }
                    .font(.footnote)
                }
            }
        }
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            Task {
                do {
                    try await AuthService.shared.signInWithApple(credential: credential)
                    await TaskStore.shared.fetchTasks()
                } catch {
                    self.error = error.localizedDescription
                }
            }
        case .failure(let err):
            error = err.localizedDescription
        }
    }

    private func submitEmail() async {
        isLoading = true
        error = nil
        do {
            if isSignUp {
                try await AuthService.shared.signUp(email: email, password: password, name: name)
            } else {
                try await AuthService.shared.signIn(email: email, password: password)
            }
            showEmailForm = false
            await TaskStore.shared.fetchTasks()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
