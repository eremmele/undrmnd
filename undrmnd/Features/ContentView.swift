import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to Undrmnd")
                        .font(.largeTitle.bold())
                    Text("A calm space to explore questions, learn with others, and contribute to science without endless scrolling.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Finite, session-based browsing \u2014 no infinite feeds.", systemImage: "hourglass")
                    Label("Ask beginner questions without backlash.", systemImage: "bubble.left.and.bubble.right")
                    Label("Discover tiny ways to contribute to real projects.", systemImage: "sparkles")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                Spacer()

                NavigationLink {
                    PlaceholderTodayView()
                } label: {
                    Text("Start a short session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button {
                    // TODO: later show how Undrmnd works / research rationale
                } label: {
                    Text("How Undrmnd works")
                        .font(.subheadline)
                }
                .padding(.bottom, 8)
            }
            .padding()
            .navigationTitle("Undrmnd")
        }
    }
}

struct PlaceholderTodayView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Today’s session")
                .font(.title2.bold())

            Text("This is where a small, finite set of cards and conversations will appear \u2014 designed to end, not to keep you here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .navigationTitle("Today")
    }
}
