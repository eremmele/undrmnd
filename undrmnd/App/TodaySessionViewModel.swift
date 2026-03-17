import Foundation
import Supabase

private struct SessionInsertRow: Encodable {
    let user_id: UUID?
    let started_at: Date
    let completed_at: Date?
    let status: String
    let cards_served_count: Int16
    let cards_completed_count: Int16
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
            interactionType: interaction_type,
            sourceUrl: nil,
            topic: nil
        )
    }
}

private struct RandomCardsParams: Encodable {
    let n: Int
}

@MainActor
final class TodaySessionViewModel: ObservableObject {
    @Published private(set) var cards: [CardItem] = []
    @Published private(set) var completedCardIDs: Set<UUID> = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private(set) var sessionStartedAt: Date = Date()

    var isSessionComplete: Bool {
        !cards.isEmpty && completedCardIDs.count >= cards.count
    }

    /// Load up to 3 random active cards for today’s finite session.
    func loadTodayCards() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            if cards.isEmpty {
                sessionStartedAt = Date()
            }

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

    func markCompleted(cardID: UUID) {
        completedCardIDs.insert(cardID)
    }

    func completeSession() async {
        let row = SessionInsertRow(
            user_id: nil,
            started_at: sessionStartedAt,
            completed_at: Date(),
            status: "completed",
            cards_served_count: Int16(cards.count),
            cards_completed_count: Int16(completedCardIDs.count)
        )

        do {
            _ = try await SupabaseService.shared.client
                .from("sessions")
                .insert(row)
                .execute()
        } catch {
            print("❌ Failed to write session row:", error)
        }
    }

    func resetSession() {
        cards = []
        completedCardIDs = []
        errorMessage = nil
        isLoading = false

        Task { await loadTodayCards() }
    }

    func cards(for topic: String) -> [CardItem] {
        cards.filter { $0.topic == topic }
    }
}
