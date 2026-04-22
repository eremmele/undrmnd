import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String
    @State private var bio: String
    @State private var pillars: Set<Pillar>
    @State private var isSaving = false
    @State private var error: String?

    let onSaved: () -> Void

    init(profile: Profile, onSaved: @escaping () -> Void) {
        _displayName = State(initialValue: profile.displayName ?? "")
        _bio = State(initialValue: profile.bio ?? "")
        _pillars = State(initialValue: Set(profile.pillarsFollowing))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Display name", text: $displayName)
                }
                Section("Bio") {
                    TextField("One line (140 characters)", text: $bio, axis: .vertical)
                        .lineLimit(2...4)
                    Text("\(bio.count) / 140")
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                Section("Pillars you follow") {
                    ForEach(Pillar.allCases) { p in
                        Toggle(p.displayName, isOn: binding(for: p))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(UndrmndPrototypeTheme.paper)
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(isSaving)
                }
            }
            if let error {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
    }

    private func binding(for p: Pillar) -> Binding<Bool> {
        Binding(
            get: { pillars.contains(p) },
            set: { on in
                if on { pillars.insert(p) } else { pillars.remove(p) }
            }
        )
    }

    private func save() async {
        isSaving = true
        error = nil
        let b = String(bio.prefix(140))
        do {
            try await ProfileService.updateMyProfile(
                displayName: displayName.isEmpty ? nil : displayName,
                bio: b.isEmpty ? nil : b,
                pillarsFollowing: Pillar.allCases.filter { pillars.contains($0) }
            )
            onSaved()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}
