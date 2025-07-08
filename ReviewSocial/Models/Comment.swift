import Foundation

struct Comment: Identifiable, Codable {
    let id: UUID
    let reviewId: UUID
    let userId: UUID
    let content: String
    let dateCreated: Date
    let dateModified: Date?
    let username: String
    let displayName: String?
    let avatarURL: String?
    
    // For local initialization (creating new comments)
    init(reviewId: UUID, userId: UUID, content: String, parentCommentId: UUID? = nil) {
        self.id = UUID()
        self.reviewId = reviewId
        self.userId = userId
        self.content = content
        self.dateCreated = Date()
        self.dateModified = nil
        self.username = "You"
        self.displayName = nil
        self.avatarURL = nil
    }
    
    // For database initialization (fetched comments)
    init(id: UUID, reviewId: UUID, userId: UUID, content: String, dateCreated: Date, username: String, displayName: String?, avatarURL: String?) {
        self.id = id
        self.reviewId = reviewId
        self.userId = userId
        self.content = content
        self.dateCreated = dateCreated
        self.dateModified = nil
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
    
    var displayUsername: String {
        return displayName ?? username
    }
}

extension Comment {
    // Sample comment for SwiftUI previews only
    static let sampleComment = Comment(
        id: UUID(),
        reviewId: Review.sampleReview.id,
        userId: User.sampleUser.id,
        content: "This is a sample comment for SwiftUI previews only.",
        dateCreated: Date().addingTimeInterval(-3600), // 1 hour ago
        username: "sampleuser",
        displayName: "Sample User",
        avatarURL: nil
    )
} 