import Foundation
import Supabase
import SwiftUI

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        print("🔧 SupabaseService: Initializing...")
        let url = URL(string: Config.supabaseURL)!
        let key = Config.supabaseAnonKey
        
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        
        // Start with unauthenticated state
        isAuthenticated = false
        currentUser = nil
        print("🔧 SupabaseService: Initial state set - isAuthenticated: \(isAuthenticated), currentUser: \(currentUser?.username ?? "nil")")
        
        // Check if user is already authenticated
        checkAuthState()
    }
    
    private func checkAuthState() {
        print("🔍 SupabaseService: Starting checkAuthState...")
        Task {
            do {
                print("🔍 SupabaseService: Attempting to get current user...")
                // Try to get the current user - this will throw if no valid session
                let user = try await client.auth.user()
                print("✅ SupabaseService: Got user from auth - ID: \(user.id), Email: \(user.email ?? "nil")")
                
                print("🔍 SupabaseService: Fetching user profile from database...")
                // Try to fetch user profile from database to ensure the user still exists
                let userProfileResponse: [[String: AnyJSON]] = try await client
                    .from("users")
                    .select("*")
                    .eq("id", value: user.id.uuidString)
                    .execute()
                    .value
                
                print("🔍 SupabaseService: Database query returned \(userProfileResponse.count) user records")
                
                let userProfile: [String: AnyJSON]
                
                if userProfileResponse.isEmpty {
                    print("⚠️ SupabaseService: No user record in database, creating new one...")
                    // No user record exists, create one
                    let username = user.userMetadata["username"]?.stringValue ?? user.email?.components(separatedBy: "@").first ?? "user"
                    let displayName = user.userMetadata["display_name"]?.stringValue ?? username
                    
                    let newUserData: [String: AnyJSON] = [
                        "id": .string(user.id.uuidString),
                        "username": .string(username),
                        "display_name": .string(displayName),
                        "bio": .string(""),
                        "avatar_url": .null,
                        "is_private": .bool(true)
                    ]
                    
                    try await client
                        .from("users")
                        .insert(newUserData)
                        .execute()
                    
                    print("✅ SupabaseService: Created new user record for \(username)")
                    userProfile = newUserData
                } else {
                    // User record exists, use it
                    userProfile = userProfileResponse[0]
                    print("✅ SupabaseService: Found existing user record for \(userProfile["username"]?.stringValue ?? "unknown")")
                }
                
                await MainActor.run {
                    print("🔄 SupabaseService: Setting authenticated state to TRUE")
                    self.isAuthenticated = true
                    self.currentUser = User(
                        id: user.id, // CRITICAL: Use the auth user's ID
                        username: userProfile["username"]?.stringValue ?? user.email ?? "Unknown",
                        displayName: userProfile["display_name"]?.stringValue ?? "",
                        email: user.email ?? "",
                        bio: userProfile["bio"]?.stringValue ?? "",
                        profileImageURL: userProfile["avatar_url"]?.stringValue,
                        isPrivate: (userProfile["is_private"]?.boolValue) ?? true
                    )
                    print("✅ SupabaseService: Authentication successful - User: \(self.currentUser?.username ?? "nil"), isAuthenticated: \(self.isAuthenticated)")
                    print("🔍 SupabaseService: User ID set to auth ID: \(user.id)")
                }
            } catch {
                // Any error means the user is not properly authenticated
                print("❌ SupabaseService: Authentication check failed - Error: \(error)")
                await MainActor.run {
                    print("🔄 SupabaseService: Setting authenticated state to FALSE")
                    self.isAuthenticated = false
                    self.currentUser = nil
                    print("✅ SupabaseService: Set to unauthenticated state - isAuthenticated: \(self.isAuthenticated)")
                }
            }
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, username: String, displayName: String) async throws {
        print("📝 SupabaseService: Starting sign up for email: \(email), username: \(username)")
        let metadata: [String: AnyJSON] = [
            "username": .string(username),
            "display_name": .string(displayName)
        ]
        
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: metadata
        )
        
        print("✅ SupabaseService: Sign up response received - User ID: \(response.user.id)")
        
        // Create user record in users table (in case trigger doesn't work)
        let user = response.user
        if true { // response.user is never nil in successful signup
            print("🔍 SupabaseService: Creating user record in database...")
            let userData: [String: AnyJSON] = [
                "id": .string(user.id.uuidString),
                "username": .string(username),
                "display_name": .string(displayName),
                "bio": .string(""),
                "avatar_url": .null,
                "is_private": .bool(true)
            ]
            
            // Use upsert to avoid conflicts if trigger already created the record
            try await client
                .from("users")
                .upsert(userData)
                .execute()
            print("✅ SupabaseService: User record created/updated in database")
        }
        
        await MainActor.run {
            print("🔄 SupabaseService: Setting authenticated state after sign up")
            self.currentUser = User(
                id: user.id, // CRITICAL: Use the auth user's ID
                username: username,
                displayName: displayName,
                email: email,
                isPrivate: true // Default to private for new users
            )
            self.isAuthenticated = true
            print("✅ SupabaseService: Sign up complete - isAuthenticated: \(self.isAuthenticated), User: \(self.currentUser?.username ?? "nil")")
            print("🔍 SupabaseService: User ID set to auth ID: \(user.id)")
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("🔐 SupabaseService: Starting sign in for email: \(email)")
        let response = try await client.auth.signIn(email: email, password: password)
        
        let user = response.user
        print("✅ SupabaseService: Sign in response received - User ID: \(user.id)")
        
        print("🔍 SupabaseService: Fetching user profile from database...")
        // Try to fetch user profile from database
        let userProfileResponse: [[String: AnyJSON]] = try await client
            .from("users")
            .select("*")
            .eq("id", value: user.id.uuidString)
            .execute()
            .value
        
        print("🔍 SupabaseService: Database query returned \(userProfileResponse.count) user records")
        
        let userProfile: [String: AnyJSON]
        
        if userProfileResponse.isEmpty {
            print("⚠️ SupabaseService: No user record in database, creating new one...")
            // No user record exists, create one
            let username = user.userMetadata["username"]?.stringValue ?? user.email?.components(separatedBy: "@").first ?? "user"
            let displayName = user.userMetadata["display_name"]?.stringValue ?? username
            
            let newUserData: [String: AnyJSON] = [
                "id": .string(user.id.uuidString),
                "username": .string(username),
                "display_name": .string(displayName),
                "bio": .string(""),
                "avatar_url": .null,
                "is_private": .bool(true)
            ]
            
            try await client
                .from("users")
                .insert(newUserData)
                .execute()
            
            print("✅ SupabaseService: Created new user record for \(username)")
            userProfile = newUserData
        } else {
            // User record exists, use it
            userProfile = userProfileResponse[0]
            print("✅ SupabaseService: Found existing user record for \(userProfile["username"]?.stringValue ?? "unknown")")
        }
        
        await MainActor.run {
            print("🔄 SupabaseService: Setting authenticated state after sign in")
            self.currentUser = User(
                id: user.id, // CRITICAL: Use the auth user's ID
                username: userProfile["username"]?.stringValue ?? user.email ?? "Unknown",
                displayName: userProfile["display_name"]?.stringValue ?? "",
                email: user.email ?? "",
                bio: userProfile["bio"]?.stringValue ?? "",
                profileImageURL: userProfile["avatar_url"]?.stringValue,
                isPrivate: (userProfile["is_private"]?.boolValue) ?? true
            )
            self.isAuthenticated = true
            print("✅ SupabaseService: Sign in complete - isAuthenticated: \(self.isAuthenticated), User: \(self.currentUser?.username ?? "nil")")
            print("🔍 SupabaseService: User ID set to auth ID: \(user.id)")
        }
    }
    
    func signOut() async throws {
        print("🚪 SupabaseService: Starting sign out...")
        try await client.auth.signOut()
        await MainActor.run {
            print("🔄 SupabaseService: Clearing authenticated state")
            self.currentUser = nil
            self.isAuthenticated = false
            print("✅ SupabaseService: Sign out complete - isAuthenticated: \(self.isAuthenticated)")
        }
    }
    
    func forceSignOut() {
        print("🚨 SupabaseService: Force sign out called")
        Task {
            do {
                try await client.auth.signOut()
                print("✅ SupabaseService: Force sign out - auth.signOut() successful")
            } catch {
                print("⚠️ SupabaseService: Force sign out - auth.signOut() failed: \(error)")
                // Ignore errors, we're forcing sign out
            }
            
            await MainActor.run {
                print("🔄 SupabaseService: Force clearing all authentication state")
                self.currentUser = nil
                self.isAuthenticated = false
                print("✅ SupabaseService: Force sign out complete - isAuthenticated: \(self.isAuthenticated)")
            }
        }
    }
    
    // Debug method to clear all state immediately
    func debugClearAuthState() {
        print("🐛 SupabaseService: DEBUG - Clearing auth state immediately")
        isAuthenticated = false
        currentUser = nil
        print("🐛 SupabaseService: DEBUG - Auth state cleared - isAuthenticated: \(isAuthenticated)")
    }
    
    // MARK: - Reviews
    
    func createReview(_ review: Review) async throws {
        print("📝 SupabaseService: Starting createReview...")
        
        guard let currentUser = currentUser else { 
            print("❌ SupabaseService: createReview failed - User not authenticated")
            throw SupabaseError.unauthenticated 
        }
        
        print("🔍 SupabaseService: Creating review for user - ID: \(currentUser.id), Username: \(currentUser.username)")
        
        // Debug: Check current auth state
        do {
            let authUser = try await client.auth.user()
            print("🔍 SupabaseService: Auth user ID: \(authUser.id)")
            print("🔍 SupabaseService: Current user ID: \(currentUser.id)")
            print("🔍 SupabaseService: IDs match: \(authUser.id == currentUser.id)")
        } catch {
            print("⚠️ SupabaseService: Could not verify auth user: \(error)")
        }
        
        // Get the actual authenticated user ID to ensure RLS compatibility
        let authUser = try await client.auth.user()
        let actualUserId = authUser.id.uuidString
        
        print("🔍 SupabaseService: Using actual auth user ID: \(actualUserId)")
        
        let reviewData: [String: AnyJSON] = [
            "user_id": .string(actualUserId),
            "title": .string(review.title),
            "content": .string(review.content),
            "rating": .double(review.rating),
            "category": .string(review.category.rawValue),
            "image_urls": .array(review.imageURLs.map { .string($0) }),
            "created_at": .string(ISO8601DateFormatter().string(from: review.dateCreated))
        ]
        
        print("🔍 SupabaseService: Review data to insert:")
        print("   - user_id: \(currentUser.id.uuidString)")
        print("   - title: \(review.title)")
        print("   - rating: \(review.rating)")
        print("   - category: \(review.category.rawValue)")
        
        do {
            let result = try await client
                .from("reviews")
                .insert(reviewData)
                .execute()
            print("✅ SupabaseService: Review created successfully")
            print("🔍 SupabaseService: Insert result: \(result)")
        } catch {
            print("❌ SupabaseService: Review creation failed with error: \(error)")
            print("❌ SupabaseService: Error type: \(type(of: error))")
            print("❌ SupabaseService: Error details: \(String(describing: error))")
            if let postgrestError = error as? PostgrestError {
                print("❌ SupabaseService: PostgREST Error - Code: \(postgrestError.code ?? "nil"), Message: \(postgrestError.message)")
                print("❌ SupabaseService: PostgREST Error - Detail: \(postgrestError.detail ?? "nil"), Hint: \(postgrestError.hint ?? "nil")")
            }
            throw error
        }
    }
    
    func fetchReviews() async throws -> [Review] {
        print("📖 SupabaseService: Starting fetchReviews...")
        
        do {
            let response: [[String: AnyJSON]] = try await client
                .from("reviews_with_details")
                .select("*")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ SupabaseService: Successfully fetched \(response.count) reviews from database")
            
            // Debug: Print the raw data
            if let firstReview = response.first {
                print("🔍 SupabaseService: Raw review data:")
                for (key, value) in firstReview {
                    print("   \(key): \(value) (type: \(type(of: value)))")
                }
            }
            
            let reviews: [Review] = response.compactMap { reviewData in
            print("🔍 SupabaseService: Parsing review data...")
            
            guard let idString = reviewData["id"]?.stringValue else {
                print("❌ SupabaseService: Failed to parse id: \(reviewData["id"] ?? .null)")
                return nil
            }
            guard let id = UUID(uuidString: idString) else {
                print("❌ SupabaseService: Failed to parse UUID from: \(idString)")
                return nil
            }
            guard let userIdString = reviewData["user_id"]?.stringValue else {
                print("❌ SupabaseService: Failed to parse user_id: \(reviewData["user_id"] ?? .null)")
                return nil
            }
            guard let userId = UUID(uuidString: userIdString) else {
                print("❌ SupabaseService: Failed to parse UUID from: \(userIdString)")
                return nil
            }
            guard let title = reviewData["title"]?.stringValue else {
                print("❌ SupabaseService: Failed to parse title: \(reviewData["title"] ?? .null)")
                return nil
            }
            guard let content = reviewData["content"]?.stringValue else {
                print("❌ SupabaseService: Failed to parse content: \(reviewData["content"] ?? .null)")
                return nil
            }
            // Handle rating as either integer or double
            let rating: Double
            if let doubleRating = reviewData["rating"]?.doubleValue {
                rating = doubleRating
            } else if let intRating = reviewData["rating"]?.intValue {
                rating = Double(intRating)
            } else {
                print("❌ SupabaseService: Failed to parse rating: \(reviewData["rating"] ?? .null)")
                return nil
            }
            guard let categoryString = reviewData["category"]?.stringValue else {
                print("❌ SupabaseService: Failed to parse category: \(reviewData["category"] ?? .null)")
                return nil
            }
            guard let category = ReviewCategory(rawValue: categoryString) else {
                print("❌ SupabaseService: Failed to parse ReviewCategory from: \(categoryString)")
                return nil
            }
            guard let createdAtString = reviewData["created_at"]?.stringValue else {
                print("❌ SupabaseService: Failed to parse created_at: \(reviewData["created_at"] ?? .null)")
                return nil
            }
            guard let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
                print("❌ SupabaseService: Failed to parse date from: \(createdAtString)")
                return nil
            }
            
            print("✅ SupabaseService: Successfully parsed review: \(title)")
            
            let imageURLs = reviewData["image_urls"]?.arrayValue?.compactMap { $0.stringValue } ?? []
            
            // Parse aggregated counts from the view
            let likesCount = reviewData["likes_count"]?.intValue ?? 0
            let commentsCount = reviewData["comments_count"]?.intValue ?? 0
            
            var review = Review(
                userId: userId,
                title: title,
                content: content,
                rating: rating,
                category: category,
                imageURLs: imageURLs
            )
            
            // Set the actual ID and date from database
            review.id = id
            review.dateCreated = createdAt
            
            // Set the aggregated counts
            review.likesCount = likesCount
            review.commentsCount = commentsCount
            // Note: sharesCount is not tracked in the database yet, keeping default 0
            
            print("🔍 SupabaseService: Review '\(title)' has \(commentsCount) comments, \(likesCount) likes")
            
            return review
        }
        
        print("📖 SupabaseService: Processed \(reviews.count) valid reviews")
        return reviews
        
        } catch {
            print("❌ SupabaseService: fetchReviews failed with error: \(error)")
            print("❌ SupabaseService: Error type: \(type(of: error))")
            if let postgrestError = error as? PostgrestError {
                print("❌ SupabaseService: PostgREST Error - Code: \(postgrestError.code ?? "nil"), Message: \(postgrestError.message)")
                print("❌ SupabaseService: PostgREST Error - Detail: \(postgrestError.detail ?? "nil"), Hint: \(postgrestError.hint ?? "nil")")
            }
            throw error
        }
    }
    
    // MARK: - Likes
    
    func likeReview(reviewId: UUID) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        let likeData: [String: AnyJSON] = [
            "review_id": .string(reviewId.uuidString),
            "user_id": .string(currentUser.id.uuidString)
        ]
        
        try await client
            .from("likes")
            .insert(likeData)
            .execute()
    }
    
    func unlikeReview(reviewId: UUID) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        try await client
            .from("likes")
            .delete()
            .eq("review_id", value: reviewId.uuidString)
            .eq("user_id", value: currentUser.id.uuidString)
            .execute()
    }
    
    // MARK: - Bookmarks
    
    func bookmarkReview(reviewId: UUID) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        let bookmarkData: [String: AnyJSON] = [
            "review_id": .string(reviewId.uuidString),
            "user_id": .string(currentUser.id.uuidString)
        ]
        
        try await client
            .from("bookmarks")
            .insert(bookmarkData)
            .execute()
    }
    
    func unbookmarkReview(reviewId: UUID) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        try await client
            .from("bookmarks")
            .delete()
            .eq("review_id", value: reviewId.uuidString)
            .eq("user_id", value: currentUser.id.uuidString)
            .execute()
    }
    
    // MARK: - Comments
    
    func addComment(reviewId: UUID, content: String) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        let commentData: [String: AnyJSON] = [
            "review_id": .string(reviewId.uuidString),
            "user_id": .string(currentUser.id.uuidString),
            "content": .string(content),
            "created_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await client
            .from("comments")
            .insert(commentData)
            .execute()
    }
    
    func fetchComments(for reviewId: UUID) async throws -> [Comment] {
        print("🔍 SupabaseService: Fetching comments for review: \(reviewId)")
        
        let response: [[String: AnyJSON]] = try await client
            .from("comments_with_users")
            .select("*")
            .eq("review_id", value: reviewId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        print("🔍 SupabaseService: Fetched \(response.count) comments")
        
        let comments = response.compactMap { commentData -> Comment? in
            guard let idString = commentData["id"]?.stringValue,
                  let id = UUID(uuidString: idString),
                  let reviewIdString = commentData["review_id"]?.stringValue,
                  let reviewId = UUID(uuidString: reviewIdString),
                  let userIdString = commentData["user_id"]?.stringValue,
                  let userId = UUID(uuidString: userIdString),
                  let content = commentData["content"]?.stringValue,
                  let createdAtString = commentData["created_at"]?.stringValue else {
                print("❌ SupabaseService: Failed to parse comment data: \(commentData)")
                return nil
            }
            
            let dateFormatter = ISO8601DateFormatter()
            let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
            
            // Parse user data directly from the view
            let username = commentData["username"]?.stringValue ?? "Unknown"
            let displayName = commentData["display_name"]?.stringValue
            let avatarURL = commentData["avatar_url"]?.stringValue
            
            return Comment(
                id: id,
                reviewId: reviewId,
                userId: userId,
                content: content,
                dateCreated: createdAt,
                username: username,
                displayName: displayName,
                avatarURL: avatarURL
            )
        }
        
        return comments
    }
    
    // MARK: - User Profile
    
    func updateProfile(displayName: String? = nil, bio: String? = nil, avatarURL: String? = nil) async throws {
        guard currentUser != nil else { throw SupabaseError.unauthenticated }
        
        var updateData: [String: AnyJSON] = [:]
        
        if let displayName = displayName {
            updateData["display_name"] = .string(displayName)
        }
        if let bio = bio {
            updateData["bio"] = .string(bio)
        }
        if let avatarURL = avatarURL {
            updateData["avatar_url"] = .string(avatarURL)
        }
        
        try await client.auth.update(user: UserAttributes(data: updateData))
        
        // Update local user
        await MainActor.run {
            if let displayName = displayName {
                self.currentUser?.displayName = displayName
            }
            if let bio = bio {
                self.currentUser?.bio = bio
            }
            if let avatarURL = avatarURL {
                self.currentUser?.profileImageURL = avatarURL
            }
        }
    }
    
    func updatePrivacySettings(isPrivate: Bool) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        let updateData: [String: AnyJSON] = [
            "is_private": .bool(isPrivate)
        ]
        
        try await client
            .from("users")
            .update(updateData)
            .eq("id", value: currentUser.id.uuidString)
            .execute()
        
        // Update local user
        await MainActor.run {
            self.currentUser?.isPrivate = isPrivate
        }
    }
    
    // MARK: - Follow System
    
    func getFollowStatus(for userId: UUID) async throws -> FollowRequestStatus {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        // Check if already following
        let followResponse = try await client
            .from("follows")
            .select()
            .eq("follower_id", value: currentUser.id.uuidString)
            .eq("following_id", value: userId.uuidString)
            .execute()
        
        if !followResponse.data.isEmpty {
            return .following
        }
        
        // Check if there's a pending request
        let requestResponse = try await client
            .from("follow_requests")
            .select()
            .eq("requester_id", value: currentUser.id.uuidString)
            .eq("requested_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .execute()
        
        if !requestResponse.data.isEmpty {
            return .pending
        }
        
        return .none
    }
    
    func followUser(userId: UUID) async throws {
        guard currentUser != nil else { throw SupabaseError.unauthenticated }
        
        // Get target user's privacy settings
        let userResponse: [String: AnyJSON] = try await client
            .from("users")
            .select("is_private")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        let userData = userResponse
        let isPrivate = userData["is_private"]?.boolValue ?? true
        
        if isPrivate {
            // Send follow request
            try await sendFollowRequest(to: userId)
        } else {
            // Follow directly
            try await followUserDirectly(userId: userId)
        }
    }
    
    private func sendFollowRequest(to userId: UUID) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        let requestData: [String: AnyJSON] = [
            "requester_id": .string(currentUser.id.uuidString),
            "requested_id": .string(userId.uuidString),
            "status": .string("pending")
        ]
        
        try await client
            .from("follow_requests")
            .insert(requestData)
            .execute()
    }
    
    private func followUserDirectly(userId: UUID) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        let followData: [String: AnyJSON] = [
            "follower_id": .string(currentUser.id.uuidString),
            "following_id": .string(userId.uuidString)
        ]
        
        try await client
            .from("follows")
            .insert(followData)
            .execute()
    }
    
    func unfollowUser(userId: UUID) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        try await client
            .from("follows")
            .delete()
            .eq("follower_id", value: currentUser.id.uuidString)
            .eq("following_id", value: userId.uuidString)
            .execute()
    }
    
    func cancelFollowRequest(userId: UUID) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        try await client
            .from("follow_requests")
            .delete()
            .eq("requester_id", value: currentUser.id.uuidString)
            .eq("requested_id", value: userId.uuidString)
            .execute()
    }
    
    // MARK: - Follow Request Management
    
    func getPendingFollowRequests() async throws -> [FollowRequest] {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        // Join follow_requests with users table to get requester info
        let response: [[String: AnyJSON]] = try await client
            .from("follow_requests")
            .select("""
                *,
                requester:users!requester_id(
                    username,
                    display_name,
                    avatar_url
                )
            """)
            .eq("requested_id", value: currentUser.id.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
        
        let requestsData = response
        var requests: [FollowRequest] = []
        
        for requestData in requestsData {
            if let id = requestData["id"]?.stringValue,
               let requesterId = requestData["requester_id"]?.stringValue,
               let requestedId = requestData["requested_id"]?.stringValue,
               let status = requestData["status"]?.stringValue,
               let createdAt = requestData["created_at"]?.stringValue,
               let updatedAt = requestData["updated_at"]?.stringValue {
                
                let dateFormatter = ISO8601DateFormatter()
                let requestStatus = FollowRequestStatus(rawValue: status) ?? .pending
                let requestId = UUID(uuidString: id) ?? UUID()
                let parsedRequesterId = UUID(uuidString: requesterId) ?? UUID()
                let parsedRequestedId = UUID(uuidString: requestedId) ?? UUID()
                let parsedCreatedAt = dateFormatter.date(from: createdAt) ?? Date()
                let parsedUpdatedAt = dateFormatter.date(from: updatedAt) ?? Date()
                
                var request = FollowRequest(
                    id: requestId,
                    requesterId: parsedRequesterId,
                    requestedId: parsedRequestedId,
                    status: requestStatus,
                    createdAt: parsedCreatedAt,
                    updatedAt: parsedUpdatedAt
                )
                request.id = requestId
                
                // Extract requester info if available
                if let requesterAnyJSON = requestData["requester"],
                   case .object(let requesterData) = requesterAnyJSON {
                    request.requesterUsername = requesterData["username"]?.stringValue
                    request.requesterDisplayName = requesterData["display_name"]?.stringValue
                    request.requesterAvatarURL = requesterData["avatar_url"]?.stringValue
                }
                
                requests.append(request)
            }
        }
        
        return requests
    }
    
    func approveFollowRequest(requestId: UUID, requesterId: UUID) async throws {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        // Update request status to approved
        let updateData: [String: AnyJSON] = [
            "status": .string("approved"),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await client
            .from("follow_requests")
            .update(updateData)
            .eq("id", value: requestId.uuidString)
            .execute()
        
        // Create follow relationship
        let followData: [String: AnyJSON] = [
            "follower_id": .string(requesterId.uuidString),
            "following_id": .string(currentUser.id.uuidString)
        ]
        
        try await client
            .from("follows")
            .insert(followData)
            .execute()
        
        // Delete the request
        try await client
            .from("follow_requests")
            .delete()
            .eq("id", value: requestId.uuidString)
            .execute()
    }
    
    func denyFollowRequest(requestId: UUID) async throws {
        // Update request status to denied
        let updateData: [String: AnyJSON] = [
            "status": .string("denied"),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await client
            .from("follow_requests")
            .update(updateData)
            .eq("id", value: requestId.uuidString)
            .execute()
        
        // Delete the request after a short delay (so user can see it was denied)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task {
                try? await self.client
                    .from("follow_requests")
                    .delete()
                    .eq("id", value: requestId.uuidString)
                    .execute()
            }
        }
    }
    
    func getFollowersCount(for userId: UUID) async throws -> Int {
        let response = try await client
            .from("follows")
            .select("id", count: .exact)
            .eq("following_id", value: userId.uuidString)
            .execute()
        
        return response.count ?? 0
    }
    
    func getFollowingCount(for userId: UUID) async throws -> Int {
        let response = try await client
            .from("follows")
            .select("id", count: .exact)
            .eq("follower_id", value: userId.uuidString)
            .execute()
        
        return response.count ?? 0
    }
    
    func getPendingFollowRequestsCount() async throws -> Int {
        guard let currentUser = currentUser else { throw SupabaseError.unauthenticated }
        
        let response = try await client
            .from("follow_requests")
            .select("id", count: .exact)
            .eq("requested_id", value: currentUser.id.uuidString)
            .eq("status", value: "pending")
            .execute()
        
        return response.count ?? 0
    }

    // MARK: - File Upload
    
    func uploadAvatar(imageData: Data) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let filePath = "avatars/\(fileName)"
        
        try await client.storage
            .from("avatars")
            .upload(filePath, data: imageData)
        
        let publicURL = try client.storage
            .from("avatars")
            .getPublicURL(path: filePath)
        
        return publicURL.absoluteString
    }
}

// MARK: - Errors

enum SupabaseError: Error {
    case unauthenticated
    case networkError
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .unauthenticated:
            return "User is not authenticated"
        case .networkError:
            return "Network error occurred"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

// MARK: - Helper Extensions

extension AnyJSON {
    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }
    
    var boolValue: Bool? {
        switch self {
        case .bool(let value):
            return value
        default:
            return nil
        }
    }
}

// MARK: - ReviewStore

class ReviewStore: ObservableObject {
    @Published var reviews: [Review] = []
    
    static let shared = ReviewStore()
    
    private init() {
        // Start with empty reviews - data will be loaded from database
    }
    
    func addReview(_ review: Review) {
        // Insert at the beginning to show newest first
        reviews.insert(review, at: 0)
    }
    
    func refreshReviews() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In a real app, this would fetch from API
        // For now, just re-sort existing reviews
        DispatchQueue.main.async {
            self.reviews.sort { $0.dateCreated > $1.dateCreated }
        }
    }
} 