import Foundation
import Supabase

struct CardItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let hook: String
    let interactionType: String
}

// Matches the shape returned from Supabase for content_items
private struct ContentItemRow: Decodable {
    let id: UUID
    let title: String
    let hook: String
    let interaction_type: String
    
    var asCardItem: CardItem {
        CardItem(
            id: id,
            title: title,
            hook: hook,
            interactionType: interaction_type
        )
    }
}

private struct RandomCardsParams: Encodable {
    let n: Int
}

@MainActor
final class TodaySessionViewModel: ObservableObject {
    @Published private(set) var cards: [CardItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    /// Load up to 3 random active cards for today’s finite session.
    func loadTodayCards() async {
        guard !isLoading else { return }

        print("🔶 loadTodayCards started")

        isLoading = true
        errorMessage = nil

        do {
            let rows: [ContentItemRow] = try await SupabaseService.shared.client
                .rpc("get_random_cards", params: RandomCardsParams(n: 3))
                .execute()
                .value

            cards = rows.map { $0.asCardItem }
        } catch {
            print("❌ TodaySession error:", error)
            cards = []
            errorMessage = "We couldn't load today's cards. Please try again in a bit."
        }

        isLoading = false
    }
}
