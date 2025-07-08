import SwiftUI

struct ProfileView: View {
    @StateObject private var reviewStore = ReviewStore.shared
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var followStatus: FollowRequestStatus = .none
    @State private var isLoadingFollow = false
    @State private var showingFollowRequests = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var pendingRequestsCount = 0
    
    let userId: UUID? // Optional userId for viewing other profiles
    
    private var isOwnProfile: Bool {
        userId == nil || userId == supabaseService.currentUser?.id
    }
    
    private var user: User {
        // Use current user from service or create a default user
        if let currentUser = supabaseService.currentUser {
            return currentUser
        } else {
            // Return a default user if no authenticated user
            return User(
                username: "user",
                displayName: "User",
                email: "user@example.com",
                bio: "Welcome to ReviewSocial!"
            )
        }
    }
    
    private var userReviews: [Review] {
        reviewStore.reviews.filter { $0.userId == user.id }
            .sorted { $0.dateCreated > $1.dateCreated }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(user.displayName.prefix(2).uppercased())
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        // User Info
                        VStack(spacing: 4) {
                            HStack {
                                Text(user.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if user.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16))
                                }
                            }
                            
                            Text("@\(user.username)")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            if !user.bio.isEmpty {
                                Text(user.bio)
                                    .font(.system(size: 15))
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }
                        }
                        
                        // Stats
                        HStack(spacing: 32) {
                            VStack {
                                Text("\(userReviews.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Reviews")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(user.followersCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(user.followingCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            if isOwnProfile {
                                Button("Edit Profile") {
                                    // Edit profile action
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                
                                Button(action: {
                                    showingFollowRequests = true
                                }) {
                                    HStack(spacing: 6) {
                                        Text("Follow Requests")
                                        if pendingRequestsCount > 0 {
                                            Text("\(pendingRequestsCount)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.red)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(20)
                            } else {
                                followButton
                                
                                Button("Share Profile") {
                                    // Share profile action
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    
                    // Tab Selection
                    HStack(spacing: 0) {
                        Button("Reviews") {
                            selectedTab = 0
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == 0 ? Color.blue.opacity(0.1) : Color.clear)
                        .foregroundColor(selectedTab == 0 ? .blue : .secondary)
                        
                        Button("Liked") {
                            selectedTab = 1
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == 1 ? Color.blue.opacity(0.1) : Color.clear)
                        .foregroundColor(selectedTab == 1 ? .blue : .secondary)
                    }
                    .background(Color(UIColor.systemBackground))
                    
                    Divider()
                    
                    // Content
                    if selectedTab == 0 {
                        // User's Reviews
                        LazyVStack(spacing: 0) {
                            ForEach(userReviews) { review in
                                ReviewCard(review: review)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        // Liked Reviews
                        VStack(spacing: 20) {
                            Image(systemName: "heart")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No liked reviews yet")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text("Reviews you like will appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    }
                }
            }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                Text("Settings Coming Soon")
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingSettings = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingFollowRequests) {
            FollowRequestsView()
        }
        .onAppear {
            loadFollowStatus()
            if isOwnProfile {
                loadPendingRequestsCount()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var followButton: some View {
        Button(action: {
            handleFollowAction()
        }) {
            HStack {
                if isLoadingFollow {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Text(followButtonText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(followButtonColor)
            .foregroundColor(followButtonTextColor)
            .cornerRadius(20)
        }
        .disabled(isLoadingFollow)
    }
    
    private var followButtonText: String {
        switch followStatus {
        case .none:
            return user.isPrivate ? "Request to Follow" : "Follow"
        case .pending:
            return "Requested"
        case .following:
            return "Following"
        case .requested:
            return "Requested"
        }
    }
    
    private var followButtonColor: Color {
        switch followStatus {
        case .none:
            return .blue
        case .pending, .requested:
            return .gray.opacity(0.3)
        case .following:
            return .green
        }
    }
    
    private var followButtonTextColor: Color {
        switch followStatus {
        case .none, .following:
            return .white
        case .pending, .requested:
            return .primary
        }
    }
    
    private func loadFollowStatus() {
        guard !isOwnProfile, let targetUserId = userId else { return }
        
        Task {
            do {
                let status = try await supabaseService.getFollowStatus(for: targetUserId)
                await MainActor.run {
                    self.followStatus = status
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    private func handleFollowAction() {
        guard !isOwnProfile, let targetUserId = userId else { return }
        
        isLoadingFollow = true
        
        Task {
            do {
                switch followStatus {
                case .none:
                    try await supabaseService.followUser(userId: targetUserId)
                    await MainActor.run {
                        self.followStatus = user.isPrivate ? .pending : .following
                    }
                case .following:
                    try await supabaseService.unfollowUser(userId: targetUserId)
                    await MainActor.run {
                        self.followStatus = .none
                    }
                case .pending, .requested:
                    try await supabaseService.cancelFollowRequest(userId: targetUserId)
                    await MainActor.run {
                        self.followStatus = .none
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
            
            await MainActor.run {
                self.isLoadingFollow = false
            }
        }
    }
    
    private func loadPendingRequestsCount() {
        Task {
            do {
                let count = try await supabaseService.getPendingFollowRequestsCount()
                await MainActor.run {
                    self.pendingRequestsCount = count
                }
            } catch {
                // Silently fail for count loading
                await MainActor.run {
                    self.pendingRequestsCount = 0
                }
            }
        }
    }
}

// MARK: - Initializers
extension ProfileView {
    init() {
        self.userId = nil
    }
    
    init(userId: UUID) {
        self.userId = userId
    }
}

#Preview {
    ProfileView()
} 