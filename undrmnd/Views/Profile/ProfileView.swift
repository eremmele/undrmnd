import SwiftUI

struct ProfileView: View {
    @Environment(\.returnToIntroSplash) private var returnToIntroSplash

    @State private var myProfile: Profile?
    @State private var isSignedIn = false
    @State private var loadError: String?
    @State private var isEditing = false
    @State private var showSignIn = false
    @State private var displayName = ""
    @State private var bio = ""
    @State private var handle = ""
    @State private var pillars = Set<Pillar>()

    @State private var cards: [ContentListRow] = []
    @State private var pathNodes: [PathNodeRow] = []
    @State private var pathTitles: [UUID: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            if isSignedIn, let err = loadError {
                Text(err)
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(UndrmndPrototypeTheme.panel)
                    .overlay(
                        Rectangle()
                            .fill(UndrmndPrototypeTheme.divider)
                            .frame(height: 1),
                        alignment: .bottom
                    )
                    .accessibilityLabel("Profile error")
            }
            Group {
                if !isSignedIn {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("Sign in to claim a handle")
                            .font(AppFont.headline)
                        Button {
                            showSignIn = true
                        } label: {
                            Text("Open sign in")
                        }
                        .buttonStyle(LargeProminentPathButtonStyle())
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                } else if let p = myProfile {
                    profileBody(p)
                } else {
                    claimForm
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 8)
        }
        .background(UndrmndPrototypeTheme.paper)
        /// Keeps the control above the tab bar and out of scroll views; without this it often sits under the tab chrome.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            quietLogoutFooter
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await refreshSession() }
        .onChange(of: isSignedIn) { _, _ in Task { await load() } }
        .onChange(of: showSignIn) { _, isShowing in
            if !isShowing { Task { await refreshSession(); await load() } }
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
        }
        .sheet(isPresented: $isEditing) {
            if let p = myProfile {
                ProfileEditView(profile: p) {
                    Task { await load() }
                }
            }
        }
    }

    private var claimForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Claim your handle")
                .font(AppFont.title2)
            TextField("handle (2–24: a–z, 0–9, _)", text: $handle)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
            TextField("Display name (optional)", text: $displayName)
                .keyboardType(.default)
                .submitLabel(.done)
            TextField("Bio, one line (optional, 140 max)", text: $bio, axis: .vertical)
                .lineLimit(2...3)
                .keyboardType(.default)
            Text("Pillars to follow")
                .font(AppFont.caption)
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
            ForEach(Pillar.allCases) { pillar in
                Toggle(pillar.displayName, isOn: bindingPillar(pillar))
            }
            Button {
                Task { await saveClaim() }
            } label: {
                Text("Save profile")
            }
            .buttonStyle(LargeProminentPathButtonStyle())
        }
        .padding(20)
    }

    @ViewBuilder
    private func profileBody(_ p: Profile) -> some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.displayName ?? p.username)
                                .font(AppFont.title2)
                            Text("@\(p.username)")
                                .font(AppFont.subheadline)
                                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        }
                        Spacer()
                        Button("Edit") { isEditing = true }
                            .foregroundStyle(UndrmndPrototypeTheme.primary)
                    }
                    if let b = p.bio, !b.isEmpty {
                        Text(b)
                            .font(AppFont.body)
                    }
                    if !p.pillarsFollowing.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Following")
                                .font(AppFont.caption)
                                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                            FlowPillChips(titles: p.pillarsFollowing.map(\.displayName))
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contributions")
                            .font(AppFont.headline)
                        ForEach(cards) { c in
                            NavigationLink {
                                ContentDetailReadOnlyView(contentId: c.id)
                            } label: {
                                Text(c.title)
                                    .font(AppFont.subheadline)
                                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                            }
                        }
                    }
                    if !pathNodes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("On paths")
                                .font(AppFont.headline)
                            ForEach(pathNodes) { n in
                                let title = pathTitles[n.pathId] ?? "Path"
                                Text("\(title) · \(n.branchPrompt ?? "node")")
                                    .font(AppFont.caption)
                                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                            }
                        }
                    }

                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: max(0, geo.size.height - 40))
                }
                .padding(20)
                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func bindingPillar(_ p: Pillar) -> Binding<Bool> {
        Binding(
            get: { pillars.contains(p) },
            set: { on in
                if on { pillars.insert(p) } else { pillars.remove(p) }
            }
        )
    }

    /// Footer above the tab bar: replay intro + log out (no extra divider strip).
    private var quietLogoutFooter: some View {
        VStack(spacing: 0) {
            Button {
                returnToIntroSplash()
            } label: {
                Text("Open intro again")
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open intro again")
            .accessibilityHint("Shows the introductory screen.")

            Button {
                Task { await logoutAndReturnToIntro() }
            } label: {
                Text("Log out")
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(UndrmndPrototypeTheme.panel.opacity(0.92))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log out")
            .accessibilityHint("Ends your session if you are signed in, then opens the introductory screen.")
        }
        .background(UndrmndPrototypeTheme.paper)
    }

    private func logoutAndReturnToIntro() async {
        try? await SupabaseService.shared.client.auth.signOut()
        await MainActor.run {
            loadError = nil
            myProfile = nil
            isSignedIn = false
            returnToIntroSplash()
        }
    }

    private func refreshSession() async {
        isSignedIn = SupabaseService.shared.client.auth.currentSession != nil
            && (SupabaseService.shared.client.auth.currentSession?.isExpired == false)
    }

    private func load() async {
        await refreshSession()
        guard isSignedIn else {
            myProfile = nil
            return
        }
        loadError = nil
        do {
            myProfile = try await ProfileService.fetchMyProfile()
            if let p = myProfile {
                cards = try await ProfileService.fetchContributedCards(username: p.username)
                pathNodes = try await ProfileService.fetchAuthoredPathNodes(username: p.username)
                let ids = pathNodes.map(\.pathId)
                pathTitles = try await ProfileService.pathTitles(for: ids)
            } else {
                cards = []
                pathNodes = []
                pathTitles = [:]
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func saveClaim() async {
        let h = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        let bioT = String(bio.prefix(140))
        do {
            try await ProfileService.claimHandle(
                username: h,
                displayName: displayName.isEmpty ? nil : displayName,
                bio: bioT.isEmpty ? nil : bioT,
                pillarsFollowing: Pillar.allCases.filter { pillars.contains($0) }
            )
            await load()
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct FlowPillChips: View {
    let titles: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(titles, id: \.self) { t in
                Text(t)
                    .font(AppFont.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(UndrmndPrototypeTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                    )
            }
        }
    }
}
