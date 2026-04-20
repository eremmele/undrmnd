import Foundation

struct WalkGuide: Equatable, Hashable {
    var name: String
    var completed: String
}

struct WalkHandoff: Equatable, Hashable {
    var user: String
    var text: String
}

struct WalkBranchOption: Identifiable, Equatable, Hashable {
    var id: String
    var label: String
    var preview: String
}

struct WalkDestinationAction: Identifiable, Equatable, Hashable {
    var id: String { action }
    var iconName: String
    var label: String
    var action: String
}

enum WalkPathNode: Identifiable, Equatable, Hashable {
    case spark(
        id: String,
        title: String,
        content: String,
        footprints: Int?,
        handoff: WalkHandoff?
    )
    case nugget(id: String, title: String, content: String, source: String?)
    case branch(
        id: String,
        title: String,
        compassRose: String?,
        branches: [WalkBranchOption]
    )
    case community(id: String, title: String, content: String)
    case contribute(id: String, title: String, content: String)
    case destination(id: String, title: String, content: String, actions: [WalkDestinationAction])

    var id: String {
        switch self {
        case .spark(let id, _, _, _, _),
             .nugget(let id, _, _, _),
             .branch(let id, _, _, _),
             .community(let id, _, _),
             .contribute(let id, _, _),
             .destination(let id, _, _, _):
            return id
        }
    }
}

struct WalkPath: Identifiable, Equatable, Hashable {
    var id: String
    var title: String
    var guide: WalkGuide?
    var nodes: [WalkPathNode]

    static let climateAnxiety = WalkPath(
        id: "climate-anxiety",
        title: "Climate Anxiety",
        guide: WalkGuide(name: "Mara", completed: "2 weeks ago"),
        nodes: [
            .spark(
                id: "spark-1",
                title: "75% of young people report feeling anxious about climate change",
                content: "But anxiety isn't the whole story — understanding what drives it can change how you respond.",
                footprints: 47,
                handoff: WalkHandoff(
                    user: "jm_rivers",
                    text: "I did this path at 2am feeling overwhelmed. You're not alone."
                )
            ),
            .nugget(
                id: "nugget-1",
                title: "The psychology of eco-anxiety",
                content: "Hickman et al. (2021) surveyed 10,000 young people across 10 countries. 59% reported feeling very or extremely worried. The distress correlated with perceived government inaction, not just environmental awareness.",
                source: "The Lancet Planetary Health"
            ),
            .branch(
                id: "branch-1",
                title: "Where do you want to go next?",
                compassRose: "Before you choose — what do you think is the bigger driver of climate anxiety: the science itself, or the feeling of powerlessness?",
                branches: [
                    WalkBranchOption(id: "science", label: "The science behind it", preview: "Tipping points, IPCC findings"),
                    WalkBranchOption(id: "community", label: "What communities are doing", preview: "Local groups, collective action"),
                    WalkBranchOption(id: "personal", label: "Personal coping strategies", preview: "Practical tools, mindset shifts")
                ]
            ),
            .nugget(
                id: "nugget-2",
                title: "Tipping points, explained",
                content: "Climate tipping points are thresholds where small changes cause large, often irreversible shifts — ice sheet collapse, permafrost thaw, Amazon dieback. Several systems are approaching these thresholds simultaneously.",
                source: "Nature Climate Change"
            ),
            .nugget(
                id: "nugget-3",
                title: "What the IPCC actually says",
                content: "The 2023 Synthesis Report confirms: limiting warming to 1.5°C is still possible but requires rapid, systemic change. Every fraction of a degree matters for reducing risks to people and ecosystems.",
                source: "IPCC AR6 Synthesis Report"
            ),
            .community(
                id: "community-1",
                title: "12 people are discussing climate science",
                content: "Join the conversation in the Climate Science campfire"
            ),
            .contribute(
                id: "contribute-1",
                title: "What do you know about this?",
                content: "Your experience matters. Share a resource, a personal insight, or a counterpoint."
            ),
            .destination(
                id: "destination-1",
                title: "You've arrived",
                content: "You've explored the science behind climate anxiety. What would you like to do?",
                actions: [
                    WalkDestinationAction(iconName: "bubble.left.and.bubble.right", label: "Join the discussion", action: "campfire"),
                    WalkDestinationAction(iconName: "person.3", label: "Find a community", action: "nearby"),
                    WalkDestinationAction(iconName: "calendar", label: "Attend an event", action: "event"),
                    WalkDestinationAction(iconName: "bookmark", label: "Save this path", action: "save"),
                    WalkDestinationAction(iconName: "clock", label: "Continue later", action: "later"),
                    WalkDestinationAction(iconName: "pencil.line", label: "Leave a handoff", action: "handoff")
                ]
            )
        ]
    )

    static let firstWalk = WalkPath(
        id: "first-walk",
        title: "Your First Walk",
        guide: WalkGuide(name: "Amara", completed: "started here too"),
        nodes: [
            .spark(
                id: "fw-spark",
                title: "It's okay not to know where to begin",
                content: "This is a short walk — just 4 stops. Think of it as practice. You can't get lost here.",
                footprints: 312,
                handoff: WalkHandoff(
                    user: "amara_k",
                    text: "I was nervous to start too. Just keep going — it gets easier."
                )
            ),
            .nugget(
                id: "fw-nugget-1",
                title: "How your phone is designed to keep you scrolling",
                content: "Social media platforms use positive intermittent reinforcement — the same mechanic as slot machines. You never know when the next reward is coming, so you keep pulling.",
                source: "Center for Humane Technology"
            ),
            .branch(
                id: "fw-branch",
                title: "Which feels more true for you?",
                compassRose: nil,
                branches: [
                    WalkBranchOption(id: "aware", label: "I know it's bad, but I can't stop", preview: "The awareness paradox"),
                    WalkBranchOption(id: "curious", label: "I want to understand why it works on me", preview: "The psychology")
                ]
            ),
            .destination(
                id: "fw-destination",
                title: "You just completed your first path",
                content: "That's it. You followed a trail, made a choice, and arrived somewhere. Everything in this app works like this.",
                actions: [
                    WalkDestinationAction(iconName: "map", label: "See your map", action: "territory"),
                    WalkDestinationAction(iconName: "arrow.right", label: "Explore a longer path", action: "entry"),
                    WalkDestinationAction(iconName: "bookmark", label: "Save & close", action: "later")
                ]
            )
        ]
    )
}

/// Mirrors `SAVED_PATHS` in `undrmnd-screens.tsx`: label shows ADHD progress while resume opens `CLIMATE_PATH` (same as the web demo).
struct SavedPathProgress: Equatable, Hashable {
    var title: String
    var completedNodes: Int
    var totalNodes: Int
    var path: WalkPath

    static let demoResume = SavedPathProgress(
        title: "Understanding ADHD",
        completedNodes: 2,
        totalNodes: 5,
        path: .climateAnxiety
    )
}

extension WalkPath {
    var exploredNuggetTitles: [String] {
        nodes.compactMap { node in
            if case .nugget(_, let title, _, _) = node { return title }
            return nil
        }
    }

    /// Pull quote on the closing ritual; matches the Vite panel for the climate path.
    var carryQuote: String {
        if id == WalkPath.climateAnxiety.id {
            return "Every fraction of a degree matters for reducing risks to people and ecosystems."
        }
        return "You followed a trail with a beginning and an end — that shape matters."
    }

    var closingTerritoryBlurb: String {
        if id == WalkPath.climateAnxiety.id {
            return "You've explored 1 path across 1 topic. Your territory now includes climate anxiety and eco-psychology."
        }
        return "You've completed a guided walk. Your map will grow as you finish more paths — always finite, never an endless feed."
    }
}
