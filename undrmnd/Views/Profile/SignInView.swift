import AuthenticationServices
import SwiftUI
import Supabase

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss

    private let client = SupabaseService.shared.client

    @State private var errorMessage: String?
    @State private var isBusy = false

    // Email / OTP
    @State private var email = ""
    @State private var otpCode = ""
    @State private var codeRequestSent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Use Sign in with Apple, or your email. Magic links and one-time codes are sent by the project’s Supabase Auth settings.")
                        .font(AppFont.subheadline)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    appleSection

                    Divider().padding(.vertical, 4)

                    emailSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppFont.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
            .background(UndrmndPrototypeTheme.paper)
            .navigationTitleBrand("Sign in")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var appleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sign in with Apple")
                .font(AppFont.headline)
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task { await handleAppleCompletion(result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .disabled(isBusy)
        }
    }

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Email")
                .font(AppFont.headline)
            TextField("Email address", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(UndrmndPrototypeTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(UndrmndPrototypeTheme.divider)
                        .allowsHitTesting(false)
                )

            if codeRequestSent {
                TextField("6-digit code from email", text: $otpCode)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(UndrmndPrototypeTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(UndrmndPrototypeTheme.divider)
                            .allowsHitTesting(false)
                    )
            }

            Button {
                Task { await codeRequestSent ? verifyEmailOTP() : sendEmailCode() }
            } label: {
                Text(codeRequestSent ? "Verify code" : "Send sign-in code")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LargeProminentPathButtonStyle())
            .disabled(isBusy || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if codeRequestSent {
                Button("Use a different email") {
                    codeRequestSent = false
                    otpCode = ""
                }
                .font(AppFont.caption)
            }
        }
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        switch result {
        case .failure(let err):
            if (err as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = err.localizedDescription
        case .success(let auth):
            guard
                let apple = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = apple.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Couldn’t read Apple identity token."
                return
            }
            isBusy = true
            defer { isBusy = false }
            do {
                _ = try await client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .apple,
                        idToken: idToken
                    )
                )
                if let fullName = apple.fullName {
                    var parts: [String] = []
                    if let g = fullName.givenName { parts.append(g) }
                    if let f = fullName.familyName { parts.append(f) }
                    let s = parts.joined(separator: " ")
                    if !s.isEmpty {
                        try? await client.auth.update(
                            user: UserAttributes(data: ["full_name": .string(s)])
                        )
                    }
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func sendEmailCode() async {
        errorMessage = nil
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !e.isEmpty else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await client.auth.signInWithOTP(
                email: e,
                redirectTo: nil,
                shouldCreateUser: true
            )
            codeRequestSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func verifyEmailOTP() async {
        errorMessage = nil
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = otpCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard e.count > 0, code.count > 0 else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            _ = try await client.auth.verifyOTP(
                email: e,
                token: code,
                type: .email
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
