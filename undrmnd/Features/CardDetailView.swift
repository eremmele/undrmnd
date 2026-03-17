import SwiftUI

struct CardDetailView: View {
    let card: CardItem
    let onComplete: () -> Void

    private var ctaTitle: String {
        let t = card.interactionType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if t.contains("reflect") { return "Reflect on this" }
        if t.contains("vote") || t.contains("poll") { return "Cast your vote" }
        if t.contains("question") || t.contains("ask") { return "Ask a question" }
        return "Continue"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(card.title)
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(card.hook)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Button(ctaTitle) {
                    print("CTA tapped:", ctaTitle, "interactionType:", card.interactionType, "cardID:", card.id)
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .navigationTitle("Card")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

