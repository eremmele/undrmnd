import SwiftUI

/// Sheet over the first-run map: contribution stays visually tied to the library, not a separate “form screen.”
struct OnboardingStrataDetailView: View {
    let strata: Strata
    var onContributionComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var observation = ""
    @FocusState private var isObservationFocused: Bool

    private static let fieldPanel = Color(red: 0.17, green: 0.17, blue: 0.18)
    private static let hairline = Color.white.opacity(0.10)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Self.hairline)
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text(strata.title)
                .font(AppFont.title3)
                .foregroundStyle(ExploreFogNavigationInk.title)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            Text("A small mark here reaches the commons—just a phrase is enough.")
                .font(AppFont.caption)
                .foregroundStyle(ExploreFogNavigationInk.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 14)

            TextField("Add a note from this corner of the map", text: $observation, axis: .vertical)
                .textFieldStyle(.plain)
                .font(AppFont.body)
                .fogMapSearchFieldInk()
                .focused($isObservationFocused)
                .lineLimit(3 ... 6)
                .submitLabel(.done)
                .onSubmit(submitObservation)
                .padding(14)
                .background(
                    Self.fieldPanel,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Self.hairline, lineWidth: 1)
                )

            Button(action: submitObservation) {
                Text("Save to the library")
                    .font(AppFont.subheadlineEmphasis)
                    .foregroundStyle(ExploreFogNavigationInk.title)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(UndrmndPrototypeTheme.accent.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(UndrmndPrototypeTheme.accent.opacity(0.45), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .disabled(observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(LearningCommonsFogMapView.nightCanvas.ignoresSafeArea())
        .colorScheme(.dark)
    }

    private func submitObservation() {
        let t = observation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        onContributionComplete()
        dismiss()
    }
}

#Preview {
    Text("Map behind")
        .sheet(isPresented: .constant(true)) {
            OnboardingStrataDetailView(
                strata: Strata.mock(title: "Dark matter halos"),
                onContributionComplete: {}
            )
            .presentationDetents([.medium])
            .presentationBackground(LearningCommonsFogMapView.nightCanvas)
        }
}
