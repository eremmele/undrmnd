import Combine
import CoreGraphics
import Foundation

/// Drives the linear first-run flow (interstitial → choose seed → island → read → contribute → main app).
@MainActor
final class OnboardingCoordinator: ObservableObject {
    enum Phase: Equatable {
        case interstitial
        case chooseBeginning
        case revealing(seed: String)
        case firstIsland(seed: String)
        case onboardingComplete
    }

    private static let completedKey = "undrmnd.onboarding.completed"

    @Published var phase: Phase = .interstitial
    /// Non-nil while user is on the first island loop (navigation / fog animation).
    @Published var starterCluster: [Strata] = []
    /// Original chosen query for deterministic first-island visual tuning.
    @Published private(set) var chosenSeed: String = ""
    /// Last topic used to build the starter cluster (not rendered on the fog carve).
    @Published private(set) var activeSeed: String = ""
    /// After contribution, widen the fog reveal edge before handing off to `MainTabView`.
    @Published var expandedFogReveal: Bool = false
    @Published private(set) var hasUnlockedMainNavigation: Bool

    /// “Replay” intro splash for users who already finished onboarding (profile action).
    @Published var showReplayInterstitial = false

    init() {
        #if DEBUG
        // Demo / iteration: always start onboarding on launch. Release builds persist completion normally.
        UserDefaults.standard.removeObject(forKey: Self.completedKey)
        #endif

        hasUnlockedMainNavigation = UserDefaults.standard.bool(forKey: Self.completedKey)
        if hasUnlockedMainNavigation {
            phase = .onboardingComplete
        }
    }

    func requestReplayIntroSplash() {
        showReplayInterstitial = true
    }

    func dismissReplayIntroSplash() {
        showReplayInterstitial = false
    }

    func continuedFromInterstitial() {
        phase = .chooseBeginning
    }

    /// Splash → topic search (toolbar on the search screen).
    func returnToInterstitial() {
        phase = .interstitial
        chosenSeed = ""
        activeSeed = ""
        starterCluster = []
        expandedFogReveal = false
    }

    /// First island map → topic search again.
    func returnToTopicSearchFromMap() {
        phase = .chooseBeginning
        starterCluster = []
        expandedFogReveal = false
        chosenSeed = ""
        activeSeed = ""
    }

    /// Reveal loading → topic search if the user backs out before the map appears.
    func returnToTopicSearchFromRevealing() {
        guard case .revealing = phase else { return }
        phase = .chooseBeginning
        starterCluster = []
        expandedFogReveal = false
        chosenSeed = ""
        activeSeed = ""
    }

    func submitSeed(_ raw: String) {
        let seed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !seed.isEmpty else { return }
        chosenSeed = seed
        activeSeed = seed
        phase = .revealing(seed: seed)
    }

    /// Called from the revealing screen — loads matching `content_items` from Supabase, then shows the island.
    /// Falls back to a curated cluster of real `content_items` ids if search and `get_random_cards` both fail.
    func completeRevealTransition() async {
        guard case let .revealing(seed) = phase else { return }
        activeSeed = seed
        var cluster: [Strata] = []
        do {
            let rows = try await ContentService.searchContentItems(query: seed, limit: 12)
            if !rows.isEmpty {
                cluster = Strata.mapCluster(from: rows.map { ContentPreview(from: $0) })
            }
        } catch {
            #if DEBUG
            print("OnboardingCoordinator: search_content_items failed (deploy docs/supabase_search_content_items.sql) — \(error)")
            #endif
        }
        if cluster.isEmpty {
            do {
                let previews = try await ContentService.fetchRandomCards(n: 6, padWithSessionFallback: false)
                if !previews.isEmpty {
                    cluster = Strata.mapCluster(from: previews)
                }
            } catch {
                #if DEBUG
                print("OnboardingCoordinator: get_random_cards fallback failed — \(error)")
                #endif
            }
        }
        if cluster.isEmpty {
            cluster = OnboardingClusterBuilder.cluster(for: seed)
        }
        starterCluster = cluster
        guard case .revealing = phase else { return }
        phase = .firstIsland(seed: seed)
    }

    /// Contribution saved: widen visible band, upgrade one obscured node to partial, then unlock the tab shell.
    func completeFirstContribution() {
        expandedFogReveal = true
        promoteOneNodeFromFog()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) { [weak self] in
            guard let self else { return }
            UserDefaults.standard.set(true, forKey: Self.completedKey)
            hasUnlockedMainNavigation = true
            phase = .onboardingComplete
            starterCluster = []
            expandedFogReveal = false
            chosenSeed = ""
            activeSeed = ""
        }
    }

    private func promoteOneNodeFromFog() {
        guard let idx = starterCluster.firstIndex(where: { $0.mapVisibility == .obscured }) else { return }
        var row = starterCluster[idx]
        row.mapVisibility = .partial
        starterCluster[idx] = row
    }

    func strata(withId id: UUID) -> Strata? {
        starterCluster.first { $0.id == id }
    }

    var chosenSeedRevealAspect: CGFloat {
        Self.revealAspect(for: chosenSeed.isEmpty ? activeSeed : chosenSeed)
    }

    private static func revealAspect(for seed: String) -> CGFloat {
        let scalars = seed.unicodeScalars
        let hash = scalars.reduce(UInt32(2_166_136_261)) { partial, scalar in
            (partial ^ scalar.value) &* 16_777_619
        }
        let normalized = CGFloat(hash % 2_001) / 1_000 - 1
        return 1 + (normalized * 0.1)
    }
}

// MARK: - Seed → starter Strata

enum OnboardingClusterBuilder {
    /// Curated `content_items` that have active parent articles — used only when search + `get_random_cards` both fail.
    /// Keep in sync with production seed data so first-island taps always open `ArticleView`.
    private static let starterCatalog: [ContentPreview] = [
        ContentPreview(
            id: UUID(uuidString: "617c1b37-21cd-44b9-b69f-a78d91e960d8")!,
            title: "Is consciousness something physics can describe?",
            hook: "We don't have a theory that explains why there's a \"what it's like\" to be you.",
            interactionType: .reflect,
            sourceUrl: "https://doi.org/10.1038/s41586-023-06345-5",
            actionUrl: nil,
            topic: .mindAndBrain,
            contributedBy: "sage_m"
        ),
        ContentPreview(
            id: UUID(uuidString: "db1826a6-623f-4e65-bb8d-cc7c09ebdaf0")!,
            title: "Why is the replication crisis not a scandal?",
            hook: "Somewhere between 36% and 65% of published psychology findings don't replicate. That's not a failure — it's the system working.",
            interactionType: .read,
            sourceUrl: "https://doi.org/10.1126/science.aac4716",
            actionUrl: nil,
            topic: .howWeKnow,
            contributedBy: "ilhan_b"
        ),
        ContentPreview(
            id: UUID(uuidString: "96877444-fc2d-48af-8e5a-94769b9a11dd")!,
            title: "Look at a 1,000-year-old star map",
            hook: "The Dunhuang Star Chart is the oldest known graphical representation of the full sky. The stars are accurate.",
            interactionType: .read,
            sourceUrl: "https://www.loc.gov/item/2021668393/",
            actionUrl: nil,
            topic: .cosmos,
            contributedBy: "ilhan_b"
        ),
        ContentPreview(
            id: UUID(uuidString: "ae4343a6-9d4e-4d40-8faf-39e7449b56fa")!,
            title: "Read a real lab notebook from 1905",
            hook: "Marie Curie's lab notebooks are digitized, in the public domain, and still radioactive.",
            interactionType: .read,
            sourceUrl: "https://gallica.bnf.fr/ark:/12148/bpt6k14752x",
            actionUrl: "https://gallica.bnf.fr/ark:/12148/bpt6k14752x",
            topic: .howWeKnow,
            contributedBy: "nneka_o"
        ),
        ContentPreview(
            id: UUID(uuidString: "67940ad6-4dc7-491d-a776-7645e5a1d524")!,
            title: "Try a four-breath pause",
            hook: "In for four. Hold for four. Out for four. Hold for four. One cycle.",
            interactionType: .observe,
            sourceUrl: "https://doi.org/10.1016/j.xcrm.2022.100895",
            actionUrl: nil,
            topic: .mindAndBrain,
            contributedBy: "marco_dz"
        ),
        ContentPreview(
            id: UUID(uuidString: "afde594c-e7b8-498d-8723-2bf5c171dc60")!,
            title: "Why did the last Ice Age end so fast?",
            hook: "The shift out of the last glacial maximum happened in centuries, not millennia. Current climate models struggle to reproduce it.",
            interactionType: .reflect,
            sourceUrl: "https://doi.org/10.1038/nature10915",
            actionUrl: nil,
            topic: .livingWorld,
            contributedBy: "priya_lk"
        ),
    ]

    /// Rotate the curated deck by seed hash so repeat runs feel different, while every dot stays a real card id.
    static func cluster(for seed: String) -> [Strata] {
        let trimmed = seed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !starterCatalog.isEmpty else { return [] }
        let h = UInt64(bitPattern: Int64(trimmed.hashValue))
        let r = Int(h % UInt64(starterCatalog.count))
        let rotated: [ContentPreview] =
            r == 0 ? starterCatalog : Array(starterCatalog[r...] + starterCatalog[..<r])
        return Strata.mapCluster(from: rotated)
    }
}
