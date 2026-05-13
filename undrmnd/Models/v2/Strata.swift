import Foundation

// MARK: - Strata (spatial library atom)

/// Atomic knowledge object for the **undrmnd** spatial library (see `docs/undrmnd-product-brief.md`).
/// Schema is intentionally explicit for API + forkability.
struct Strata: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    /// Plain-language summary for cards and previews.
    var plainSummary: String?
    /// Citation, institution, or “where this came from.”
    var sourceOrOrigin: String?
    var topicTags: [String]
    var relatedStrataIds: [UUID]
    var contributionPrompts: [String]
    var verificationState: StrataVerificationState
    /// Field notes linked to this Strata (or empty until backend exists).
    var attachedFieldNoteIds: [UUID]
    /// How the Strata reads on the 2D map (fog / silhouette / clear).
    var mapVisibility: StrataMapVisibility
    /// Soft relationship hints for graph + UI (not a full triple store).
    var relationshipKinds: [StrataRelationship]

    enum CodingKeys: String, CodingKey {
        case id, title
        case plainSummary = "plain_summary"
        case sourceOrOrigin = "source_or_origin"
        case topicTags = "topic_tags"
        case relatedStrataIds = "related_strata_ids"
        case contributionPrompts = "contribution_prompts"
        case verificationState = "verification_state"
        case attachedFieldNoteIds = "attached_field_note_ids"
        case mapVisibility = "map_visibility"
        case relationshipKinds = "relationship_kinds"
    }
}

enum StrataVerificationState: String, Codable, Hashable {
    case unverified
    case communityReviewed = "community_reviewed"
    case verifiedPartial = "verified_partial"
    case verified
}

enum StrataMapVisibility: String, Codable, Hashable {
    case obscured
    case partial
    case revealed
}

enum StrataRelationship: String, Codable, Hashable {
    case relatedTo = "related_to"
    case builtFrom = "built_from"
    case contributedNear = "contributed_near"
    case answeredBy = "answered_by"
    case fieldNoteAttached = "field_note_attached"
}

extension Strata {
    /// Preview / mock Strata for UI and first-run island (not production defaults).
    static func mock(
        id: UUID = UUID(),
        title: String,
        plainSummary: String? = nil,
        visibility: StrataMapVisibility = .revealed
    ) -> Strata {
        Strata(
            id: id,
            title: title,
            plainSummary: plainSummary,
            sourceOrOrigin: nil,
            topicTags: [],
            relatedStrataIds: [],
            contributionPrompts: [],
            verificationState: .unverified,
            attachedFieldNoteIds: [],
            mapVisibility: visibility,
            relationshipKinds: []
        )
    }

    /// Build a starter island from Supabase search hits (`content_items` ids = Strata ids for navigation).
    static func mapCluster(from previews: [ContentPreview]) -> [Strata] {
        previews.enumerated().map { index, preview in
            let visibility: StrataMapVisibility
            if index == 0 {
                visibility = .revealed
            } else if index < 4 {
                visibility = .partial
            } else {
                visibility = .obscured
            }
            return Strata.fromContentPreview(preview, mapVisibility: visibility)
        }
    }

    static func fromContentPreview(_ preview: ContentPreview, mapVisibility: StrataMapVisibility) -> Strata {
        let origin = preview.contributedBy.map { "Community · @" + $0 }
        return Strata(
            id: preview.id,
            title: preview.title,
            plainSummary: preview.hook,
            sourceOrOrigin: origin,
            topicTags: [],
            relatedStrataIds: [],
            contributionPrompts: [],
            verificationState: .unverified,
            attachedFieldNoteIds: [],
            mapVisibility: mapVisibility,
            relationshipKinds: [.contributedNear]
        )
    }
}
