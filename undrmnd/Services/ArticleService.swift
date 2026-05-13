import Foundation
import Supabase

/// Must match the PostgREST function signature: `public.get_article_for_card(card_id uuid)`.
private struct GetArticleForCardParams: Encodable, Sendable {
    let card_id: UUID
}

private struct GetArticleParams: Encodable, Sendable {
    let article_id: UUID
}

private struct CommitArticleVersionParams: Encodable, Sendable {
    let article_id: UUID
    let body: String
    let commit_message: String?
}

private struct ForkArticleBranchParams: Encodable, Sendable {
    let branch_id: UUID
    let title: String
    let slug: String
    let body: String
}

/// Response row when the RPC returns `{ "id": "uuid" }`.
private struct IdRow: Decodable, Sendable {
    let id: UUID
}

enum ArticleServiceError: Error, LocalizedError {
    case signInRequired
    case rlsRejection
    case unexpectedPayload
    /// `get_article_for_card` / `get_article` returned SQL `NULL` — no `articles` row linked to this `content_items` id.
    case noArticleForContent

    var errorDescription: String? {
        switch self {
        case .signInRequired: return "Sign in to perform this action."
        case .rlsRejection: return "Not permitted."
        case .unexpectedPayload: return "The server response could not be read."
        case .noArticleForContent:
            return "No full article is linked to this card yet."
        }
    }
}

/// PostgREST can return JSON `null` for an RPC; `ArticleBundle` alone does not decode that.
private struct ArticleBundleOrNull: Decodable, Sendable {
    let value: ArticleBundle?

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if try c.decodeNil() {
            value = nil
            return
        }
        value = try c.decode(ArticleBundle.self)
    }
}

enum ArticleService {
    private static func mapRPCAuthFailure(_ error: Error) -> Error {
        if let e = error as? PostgrestError {
            let code = e.code ?? ""
            let msg = e.message.lowercased()
            if code == "42501"
                || (code == "PGRST" && msg.contains("rls"))
                || msg.contains("jwt") || msg.contains("not authorized") {
                return ArticleServiceError.signInRequired
            }
            if msg.contains("row-level security") || msg.contains("permission denied") {
                return ArticleServiceError.signInRequired
            }
        }
        let desc = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        if desc.lowercased().contains("jwt") || desc.lowercased().contains("permission") {
            return ArticleServiceError.signInRequired
        }
        return error
    }

    static func fetchForCard(
        contentId: UUID,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> ArticleBundle {
        let res: PostgrestResponse<ArticleBundleOrNull> = try await client
            .rpc("get_article_for_card", params: GetArticleForCardParams(card_id: contentId))
            .execute()
        guard let bundle = res.value.value else {
            throw ArticleServiceError.noArticleForContent
        }
        return bundle
    }

    static func fetch(
        articleId: UUID,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> ArticleBundle {
        let res: PostgrestResponse<ArticleBundleOrNull> = try await client
            .rpc("get_article", params: GetArticleParams(article_id: articleId))
            .execute()
        guard let bundle = res.value.value else {
            throw ArticleServiceError.noArticleForContent
        }
        return bundle
    }

    static func commitVersion(
        articleId: UUID,
        body: String,
        commitMessage: String?,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> UUID {
        do {
            let res: PostgrestResponse<IdRow> = try await client
                .rpc(
                    "commit_article_version",
                    params: CommitArticleVersionParams(
                        article_id: articleId,
                        body: body,
                        commit_message: commitMessage
                    )
                )
                .execute()
            return res.value.id
        } catch {
            throw mapRPCAuthFailure(error)
        }
    }

    static func forkBranch(
        branchId: UUID,
        title: String,
        slug: String,
        body: String,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> UUID {
        do {
            let res: PostgrestResponse<IdRow> = try await client
                .rpc(
                    "fork_article_branch",
                    params: ForkArticleBranchParams(
                        branch_id: branchId,
                        title: title,
                        slug: slug,
                        body: body
                    )
                )
                .execute()
            return res.value.id
        } catch {
            throw mapRPCAuthFailure(error)
        }
    }
}
