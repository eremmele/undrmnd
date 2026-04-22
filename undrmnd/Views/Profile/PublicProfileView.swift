import SwiftUI

/// Read-only profile from a `contributed by @handle` line. Full layout in ProfileView pass.
struct PublicProfileView: View {
    let username: String

    var body: some View {
        NavigationStack {
            VStack {
                Text("@\(username)")
                    .font(.title2)
                    .padding()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
