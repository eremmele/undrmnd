//
//  TodaySessionViewModel.swift
//  undrmnd
//
//  Created by Erica Remmele on 3/11/26.
//

import Foundation
import Supabase

struct CardItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let hook: String
    let interactionType: String
}

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

@MainActor final class TodaySessionViewModel: ObservableObject {
    @Published private(set) var cards: [CardItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    func loadTodayCards() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let client = SupabaseService.shared.client

            let rows: [ContentItemRow] = try await client
                .rpc("get_random_cards", params: ["n": 3])
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
