import SwiftUI

/// Placeholder: Supabase auth is not in scope for this PR.
struct SignInView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Sign in to claim a handle")
                .font(.headline)
            Text("Email or magic-link sign-in can plug into Supabase Auth here. Not wired in this build.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
            // TODO: Wire `SupabaseService.shared.client.auth` (sign in with OTP, etc.) when you enable auth in the app.
        }
        .padding(24)
    }
}
