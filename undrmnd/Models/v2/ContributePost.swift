import Foundation

// MARK: - ContributePost
//
// One post inside a contribute_threads conversation. Seed posts always have
// `authorUserId == nil` (text handles only); real posts written by signed-in
// users will carry a uuid.

struct ContributePost: Codable, Identifiable, Hashable {
    let id: UUID
    let threadId: UUID
    let body: String
    let authorHandle: String
    let authorUserId: UUID?
    let isOpening: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, body
        case threadId = "thread_id"
        case authorHandle = "author_handle"
        case authorUserId = "author_user_id"
        case isOpening = "is_opening"
        case createdAt = "created_at"
    }
}

// MARK: - Envelope for `get_contribute_thread(id)`

struct ContributeThreadBundle: Codable, Hashable {
    let thread: ContributeThread
    let posts: [ContributePost]
}
