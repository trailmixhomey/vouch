import Foundation

struct FollowRequest: Identifiable, Codable {
    var id: UUID
    let requesterId: UUID
    let requestedId: UUID
    let status: FollowRequestStatus
    let createdAt: Date
    let updatedAt: Date
    
    // Additional user info for display
    var requesterUsername: String?
    var requesterDisplayName: String?
    var requesterAvatarURL: String?
    

}

enum FollowRequestStatus: String, Codable, CaseIterable {
    case none = "none"
    case pending = "pending"
    case following = "following"
    case requested = "requested"
}

// Sample data for SwiftUI previews only
extension FollowRequest {
    static let sampleRequest = FollowRequest(
        id: UUID(),
        requesterId: UUID(),
        requestedId: UUID(),
        status: .pending,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let sampleRequests = [
        FollowRequest(id: UUID(), requesterId: UUID(), requestedId: UUID(), status: .pending, createdAt: Date(), updatedAt: Date()),
        FollowRequest(id: UUID(), requesterId: UUID(), requestedId: UUID(), status: .pending, createdAt: Date(), updatedAt: Date()),
        FollowRequest(id: UUID(), requesterId: UUID(), requestedId: UUID(), status: .pending, createdAt: Date(), updatedAt: Date())
    ]
} 