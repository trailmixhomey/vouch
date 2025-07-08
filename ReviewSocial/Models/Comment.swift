import Foundation

struct Comment: Identifiable, Codable {
    var id = UUID()
    let reviewId: UUID
    let userId: UUID
    var content: String
    var likesCount: Int
    let dateCreated: Date
    var dateModified: Date?
    var isEdited: Bool
    let parentCommentId: UUID? // For reply threading
    var repliesCount: Int
    
    init(reviewId: UUID, userId: UUID, content: String, parentCommentId: UUID? = nil) {
        self.reviewId = reviewId
        self.userId = userId
        self.content = content
        self.likesCount = 0
        self.dateCreated = Date()
        self.dateModified = nil
        self.isEdited = false
        self.parentCommentId = parentCommentId
        self.repliesCount = 0
    }
}

extension Comment {
    // Sample comment for SwiftUI previews only
    static let sampleComment = Comment(
        reviewId: Review.sampleReview.id,
        userId: User.sampleUser.id,
        content: "This is a sample comment for SwiftUI previews only."
    )
} 