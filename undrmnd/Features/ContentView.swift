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
    @StateObject private var viewModel = TodaySessionViewModel()

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

                if viewModel.isLoading {
                    ProgressView("Loading today’s cards…")
                        .padding(.top, 16)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                } else if viewModel.cards.isEmpty {
                    Text("No cards available yet. Check back soon.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                } else {
                    ForEach(viewModel.cards) { card in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                            .frame(maxWidth: .infinity, minHeight: 140)
                            .overlay(
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(card.title)
                                        .font(.headline)
                                    Text(card.hook)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            )
                    }
                }

                Spacer()

                Text("You’ll see just a few items per session — no infinite scrolling.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Today")  
            .task {
                await viewModel.loadTodayCards()
            }
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
