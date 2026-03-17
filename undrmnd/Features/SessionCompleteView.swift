import SwiftUI

struct SessionCompleteView: View {
    let cardsServedCount: Int
    let cardsCompletedCount: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Text("That’s your session for today.")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("\(cardsServedCount) cards · come back tomorrow")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("\(cardsCompletedCount) of \(cardsServedCount) completed")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            Spacer()

            Button("Done") { onDone() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

