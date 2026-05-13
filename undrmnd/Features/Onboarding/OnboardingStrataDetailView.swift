import SwiftUI

/// Sheet over the first-run map: contribution stays visually tied to the library, not a separate “form screen.”
struct OnboardingStrataDetailView: View {
    let strata: Strata
    var onContributionComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var observation = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(UndrmndPrototypeTheme.divider)
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text(strata.title)
                .font(AppFont.title3)
                .foregroundStyle(UndrmndPrototypeTheme.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            Text("A small mark here reaches the commons—just a phrase is enough.")
                .font(AppFont.caption)
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 14)

            TextField("Add a note from this corner of the map", text: $observation, axis: .vertical)
                .textFieldStyle(.plain)
                .font(AppFont.body)
                .lineLimit(3 ... 6)
                .padding(14)
                .background(
                    UndrmndPrototypeTheme.panel.opacity(0.92),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                )

            Button(action: submitObservation) {
                Text("Save to the library")
                    .font(AppFont.subheadlineEmphasis)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(UndrmndPrototypeTheme.accent.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(UndrmndPrototypeTheme.accent.opacity(0.3), lineWidth: 1)
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
        .background(Color.clear)
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
        }
}
