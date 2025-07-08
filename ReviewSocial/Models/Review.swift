import Foundation

struct Review: Identifiable, Codable {
    var id = UUID()
    let userId: UUID
    var title: String // Name of the thing being reviewed (restaurant name, movie title, etc.)
    var content: String
    var rating: Double // 1.0 to 5.0
    var category: ReviewCategory
    var imageURLs: [String]
    var likesCount: Int
    var dislikesCount: Int
    var commentsCount: Int
    var sharesCount: Int
    var isBookmarked: Bool = false
    var dateCreated: Date
    var dateModified: Date?
    var isEdited: Bool
    
    init(userId: UUID, title: String, content: String, rating: Double, category: ReviewCategory, imageURLs: [String] = []) {
        self.userId = userId
        self.title = title
        self.content = content
        self.rating = max(1.0, min(5.0, rating)) // Clamp between 1.0 and 5.0
        self.category = category
        self.imageURLs = imageURLs
        self.likesCount = 0
        self.dislikesCount = 0
        self.commentsCount = 0
        self.sharesCount = 0
        self.dateCreated = Date()
        self.dateModified = nil
        self.isEdited = false
    }
}

enum ReviewCategory: String, CaseIterable, Codable {
    case restaurant = "Restaurant"
    case movie = "Movie"
    case book = "Book"
    case product = "Product"
    case service = "Service"
    case travel = "Travel"
    case entertainment = "Entertainment"
    case technology = "Technology"
    case health = "Health"
    case other = "Other"
}

extension Review {
    // Sample review for SwiftUI previews only
    static let sampleReview = Review(
        userId: User.sampleUser.id,
        title: "Preview Review",
        content: "This is a sample review for SwiftUI previews only. It demonstrates the review card layout and functionality.",
        rating: 4.0,
        category: .restaurant,
        imageURLs: []
    )
} 