import SwiftUI
import UIKit

/// “What are you looking for?” screen from the web prototype (`NA`).
struct GoalClarifierView: View {
    var onPickTopic: () -> Void

    private let chips = [
        "Understand a topic",
        "Find a community",
        "Contribute to a discussion",
        "Attend an event",
        "Save something for later",
        "Explore freely"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("What are you looking for?")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(chips, id: \.self) { chip in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onPickTopic()
                        } label: {
                            Text(chip)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .foregroundStyle(UndrmndPrototypeTheme.primary)
                                .background(UndrmndPrototypeTheme.paper)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(UndrmndPrototypeTheme.primary, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(chip)
                        .accessibilityHint("Starts a curated path on this theme")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Or describe what's on your mind…")
                        .font(.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(UndrmndPrototypeTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                )

                Text("Each choice leads to a curated path — a short, focused journey through ideas, not an open-ended browse.")
                    .font(.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
    }
}
