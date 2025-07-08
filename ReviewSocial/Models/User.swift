import Foundation

struct User: Identifiable, Codable {
    var id = UUID()
    var username: String
    var displayName: String
    var email: String
    var bio: String
    var profileImageURL: String?
    var followersCount: Int
    var followingCount: Int
    var reviewsCount: Int
    var dateJoined: Date
    var isVerified: Bool
    var isPrivate: Bool
    
    init(id: UUID = UUID(), username: String, displayName: String, email: String, bio: String = "", profileImageURL: String? = nil, isPrivate: Bool = true) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.email = email
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.followersCount = 0
        self.followingCount = 0
        self.reviewsCount = 0
        self.dateJoined = Date()
        self.isVerified = false
        self.isPrivate = isPrivate
    }
}



extension User {
    // Sample user for SwiftUI previews only
    static let sampleUser = User(
        username: "preview_user",
        displayName: "Preview User",
        email: "preview@example.com",
        bio: "This is a preview user for SwiftUI previews only",
        isPrivate: false
    )
} 