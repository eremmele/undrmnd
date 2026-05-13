import Foundation
import Supabase

// MARK: - RPC params

private struct ListContributeThreadsParams: Encodable, Sendable {
    let pillar: String?
    let lim: Int
}

private struct GetContributeThreadParams: Encodable, Sendable {
    let thread_id: UUID
}

// MARK: - List row (list_contribute_threads)

struct ContributeThreadListRow: Decodable, Sendable {
    let id: UUID
    let title: String
    let topic: String
    let createdByHandle: String?
    let createdAt: Date?
    let updatedAt: Date?
    let postCount: Int
    let lastPostHandle: String?
    let lastPostAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, topic
        case createdByHandle = "created_by_handle"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case postCount = "post_count"
        case lastPostHandle = "last_post_handle"
        case lastPostAt = "last_post_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        topic = try c.decode(String.self, forKey: .topic)
        createdByHandle = try c.decodeIfPresent(String.self, forKey: .createdByHandle)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
        lastPostHandle = try c.decodeIfPresent(String.self, forKey: .lastPostHandle)
        lastPostAt = try c.decodeIfPresent(Date.self, forKey: .lastPostAt)
        if let n = try? c.decode(Int.self, forKey: .postCount) {
            postCount = n
        } else if let n64 = try? c.decode(Int64.self, forKey: .postCount) {
            postCount = Int(n64)
        } else {
            postCount = 0
        }
    }
}

// MARK: - Detail payload (get_contribute_thread → jsonb)

private struct ContributeThreadDetailPayload: Decodable, Sendable {
    let thread: RemoteContributeThread
    let posts: [RemoteContributePost]
}

private struct RemoteContributeThread: Decodable, Sendable {
    let id: UUID
    let title: String
    let topic: String
    let createdByHandle: String?
    let isActive: Bool?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, topic
        case createdByHandle = "created_by_handle"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct RemoteContributePost: Decodable, Sendable {
    let id: UUID
    let body: String
    let authorHandle: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, body
        case authorHandle = "author_handle"
        case createdAt = "created_at"
    }
}

// MARK: - Service

enum CommunityService {
    private static let relativeTime: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    static func listThreads(
        pillar: Pillar?,
        limit: Int = 50,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> [ContributeThreadListRow] {
        let lim = min(max(limit, 1), 80)
        let pillarRaw: String? = pillar.map(\.rawValue)
        let res: PostgrestResponse<[ContributeThreadListRow]> = try await client
            .rpc("list_contribute_threads", params: ListContributeThreadsParams(pillar: pillarRaw, lim: lim))
            .execute()
        return res.value
    }

    /// All active threads (bounded); used for lightweight client-side search over titles/topics.
    static func listAllThreadsForSearch(
        limit: Int = 80,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> [ContributeThreadListRow] {
        try await listThreads(pillar: nil, limit: limit, client: client)
    }

    /// Remote posts when available; otherwise `nil` (caller may fall back to seed data).
    static func loadRemoteDiscussionThread(threadId: UUID) async -> PillarDiscussionThread? {
        let payload: ContributeThreadDetailPayload?
        do {
            let res: PostgrestResponse<ContributeThreadDetailPayload> = try await SupabaseService.shared.client
                .rpc("get_contribute_thread", params: GetContributeThreadParams(thread_id: threadId))
                .single()
                .execute()
            payload = res.value
        } catch {
            payload = nil
        }
        guard let payload else { return nil }
        return detailPayloadAsDiscussionThread(payload)
    }

    static func pillar(fromTopicColumn topic: String) -> Pillar {
        Pillar(rawValue: topic) ?? .howWeKnow
    }

    static func listRowAsDiscussionThread(_ row: ContributeThreadListRow) -> PillarDiscussionThread {
        let pillar = pillar(fromTopicColumn: row.topic)
        let activity = row.lastPostAt.map { relativeTime.localizedString(for: $0, relativeTo: Date()) }
            ?? row.updatedAt.map { relativeTime.localizedString(for: $0, relativeTo: Date()) }
            ?? "recently"
        return PillarDiscussionThread(
            id: row.id,
            pillar: pillar,
            titleQuestion: row.title,
            contentItems: [],
            seedReplies: [],
            lastActivityLabel: activity,
            listedReplyCount: row.postCount
        )
    }

    private static func detailPayloadAsDiscussionThread(_ payload: ContributeThreadDetailPayload) -> PillarDiscussionThread {
        let t = payload.thread
        let pillar = pillar(fromTopicColumn: t.topic)
        let replies: [ThreadReply] = payload.posts.map { p in
            ThreadReply(
                id: p.id,
                authorHandle: handleDisplay(p.authorHandle),
                body: p.body,
                timeLabel: p.createdAt.map { relativeTime.localizedString(for: $0, relativeTo: Date()) } ?? ""
            )
        }
        let activity = t.updatedAt.map { relativeTime.localizedString(for: $0, relativeTo: Date()) } ?? "recently"
        return PillarDiscussionThread(
            id: t.id,
            pillar: pillar,
            titleQuestion: t.title,
            contentItems: [],
            seedReplies: replies,
            lastActivityLabel: activity,
            listedReplyCount: replies.isEmpty ? nil : replies.count
        )
    }

    private static func handleDisplay(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("@") { return t }
        return "@\(t)"
    }
}
