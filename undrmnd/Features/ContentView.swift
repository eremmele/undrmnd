import SwiftUI

struct RootView: View {
    @State private var selectedTab: Tab = .today

    enum Tab {
        case today
        case forum
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodaySessionView()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }
                .tag(Tab.today)

            ForumPlaceholderView()
                .tabItem {
                    Label("Forum", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(Tab.forum)
        }
    }
}

struct TodaySessionView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today’s session")
                        .font(.largeTitle.bold())
                    Text("A short, finite set of cards to explore, contribute, and then log off feeling lighter.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // TODO: replace with real, finite cards from Supabase
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .overlay(
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Placeholder card")
                                .font(.headline)
                            Text("This is where a micro-curiosity or tiny contribution prompt will live.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    )

                Spacer()

                Text("You’ll see just a few items per session — no infinite scrolling.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Today")
        }
    }
}

struct ForumPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Forum (coming soon)")
                    .font(.title2.bold())

                Text("A gentle discussion space for questions, stories, and collaboration — designed to be kind, not chaotic.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("Forum")
        }
    }
}
