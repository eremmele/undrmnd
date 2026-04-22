import SwiftUI

struct ProfileView: View {
    @Environment(\.openTerritoryMapFromShell) private var openTerritoryMap
    @Environment(\.openTopicSearchFromShell) private var openTopicSearch
    @Environment(\.openAlertsFromShell) private var openAlertsFromShell

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
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitleBrand("Profile")
        .task { await refreshSession() }
        .onChange(of: isSignedIn) { _, _ in Task { await load() } }
        .onChange(of: showSignIn) { _, isShowing in
            if !isShowing { Task { await refreshSession(); await load() } }
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
        }
        .toolbar {
            ExploreShellToolbar.items(openMap: openTerritoryMap, openSearch: openTopicSearch, openAlerts: openAlertsFromShell)
            if isSignedIn {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign out") {
                        Task { await signOut() }
                    }
                    .tint(UndrmndPrototypeTheme.secondary)
                }
            }
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
            TextField("Display name (optional)", text: $displayName)
            TextField("Bio, one line (optional, 140 max)", text: $bio, axis: .vertical)
                .lineLimit(2...3)
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
                            Text("\(title) — \(n.branchPrompt ?? "node")")
                                .font(AppFont.caption)
                                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        }
                    }
                }
            }
            .padding(20)
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

    private func refreshSession() async {
        isSignedIn = SupabaseService.shared.client.auth.currentSession != nil
            && (SupabaseService.shared.client.auth.currentSession?.isExpired == false)
    }

    private func signOut() async {
        do {
            try await SupabaseService.shared.client.auth.signOut()
            myProfile = nil
            isSignedIn = false
        } catch {
            loadError = error.localizedDescription
        }
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
