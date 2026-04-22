import Foundation

// MARK: - Profile

struct Profile: Decodable, Identifiable, Hashable, Equatable {
    let id: UUID
    let username: String
    let displayName: String?
    let bio: String?
    private let pillarsFollowingRaw: [String]
    let contributionsCount: Int
    let isContributor: Bool
    let joinedAt: Date

    var pillarsFollowing: [Pillar] {
        pillarsFollowingRaw.compactMap { Pillar(rawValue: $0) }
    }

    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case displayName = "display_name"
        case pillarsFollowingRaw = "pillars_following"
        case contributionsCount = "contributions_count"
        case isContributor = "is_contributor"
        case joinedAt = "joined_at"
    }
}

struct ProfileUpdate: Encodable {
    var displayName: String?
    var bio: String?
    var pillarsFollowing: [Pillar]

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case bio
        case pillarsFollowing = "pillars_following"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(displayName, forKey: .displayName)
        try c.encodeIfPresent(bio, forKey: .bio)
        try c.encode(pillarsFollowing.map(\.rawValue), forKey: .pillarsFollowing)
    }
}

struct ProfileInsert: Encodable {
    let id: UUID
    let username: String
    var displayName: String?
    var bio: String?
    var pillarsFollowing: [Pillar]

    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case displayName = "display_name"
        case pillarsFollowing = "pillars_following"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(username, forKey: .username)
        try c.encodeIfPresent(displayName, forKey: .displayName)
        try c.encodeIfPresent(bio, forKey: .bio)
        try c.encode(pillarsFollowing.map(\.rawValue), forKey: .pillarsFollowing)
    }
}
