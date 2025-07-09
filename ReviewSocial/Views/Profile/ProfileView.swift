import SwiftUI
import PhotosUI

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
    @State private var viewedUser: User? = nil
    @State private var isLoadingUser = false
    @State private var showingImagePicker = false
    @State private var selectedImageItem: PhotosPickerItem? = nil
    @State private var isUploadingImage = false
    
    let userId: UUID? // Optional userId for viewing other profiles
    
    private var isOwnProfile: Bool {
        userId == nil || userId == supabaseService.currentUser?.id
    }
    
    private var user: User {
        if isOwnProfile {
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
        } else {
            // Use the fetched user for other profiles
            return viewedUser ?? User(
                username: "loading",
                displayName: "Loading...",
                email: "loading@example.com",
                bio: "Loading user information..."
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
                        Button(action: {
                            if isOwnProfile {
                                showingImagePicker = true
                            }
                        }) {
                            ZStack {
                                Group {
                                    if let profileImageURL = user.profileImageURL, !profileImageURL.isEmpty {
                                        AsyncImage(url: URL(string: profileImageURL)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Circle()
                                                .fill(Color.blue.opacity(0.3))
                                                .overlay(
                                                    ProgressView()
                                                        .scaleEffect(0.8)
                                                )
                                        }
                                    } else {
                                        Circle()
                                            .fill(Color.blue.opacity(0.3))
                                            .overlay(
                                                Text(user.displayName.prefix(2).uppercased())
                                                    .font(.system(size: 28, weight: .medium))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                
                                // Show upload indicator when uploading
                                if isUploadingImage {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        )
                                }
                                
                                // Show edit indicator for own profile
                                if isOwnProfile && !isUploadingImage {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Image(systemName: "camera.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white)
                                                )
                                                .offset(x: -4, y: -4)
                                        }
                                    }
                                }
                            }
                        }
                        .disabled(!isOwnProfile || isUploadingImage)
                        .buttonStyle(PlainButtonStyle())
                        
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
            } else if let userId = userId {
                // Fetch user data for other profiles
                Task {
                    await fetchUserData(userId: userId)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedImageItem, matching: .images)
        .onChange(of: selectedImageItem) { newItem in
            if let newItem = newItem {
                Task {
                    await handleImageSelection(newItem)
                }
            }
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
    
    private func fetchUserData(userId: UUID) async {
        isLoadingUser = true
        
        do {
            let fetchedUser = try await supabaseService.fetchUser(by: userId)
            await MainActor.run {
                viewedUser = fetchedUser
                isLoadingUser = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load user profile: \(error.localizedDescription)"
                showError = true
                isLoadingUser = false
            }
        }
    }
    
    private func handleImageSelection(_ item: PhotosPickerItem) async {
        print("📸 ProfileView: Starting image selection handling...")
        
        await MainActor.run {
            isUploadingImage = true
        }
        
        do {
            print("📸 ProfileView: Loading image data from PhotosPickerItem...")
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                print("❌ ProfileView: Failed to load image data from PhotosPickerItem")
                throw SupabaseError.invalidData
            }
            
            print("📸 ProfileView: Original image data size: \(imageData.count) bytes")
            
            // Compress image if needed
            print("📸 ProfileView: Compressing image...")
            let compressedData = await compressImageData(imageData)
            print("📸 ProfileView: Compressed image data size: \(compressedData.count) bytes")
            
            // Upload to Supabase Storage
            print("📸 ProfileView: Uploading to Supabase Storage...")
            let imageURL = try await supabaseService.uploadProfileImage(imageData: compressedData)
            print("📸 ProfileView: Upload successful! Image URL: \(imageURL)")
            
            // Update user profile with new image URL
            print("📸 ProfileView: Updating user profile with new image URL...")
            try await supabaseService.updateUserProfileImage(imageURL: imageURL)
            print("📸 ProfileView: Profile updated successfully!")
            
            await MainActor.run {
                isUploadingImage = false
                selectedImageItem = nil // Reset selection
            }
            
            print("✅ ProfileView: Image upload and profile update completed successfully!")
            
        } catch {
            print("❌ ProfileView: Image upload failed with error: \(error)")
            print("❌ ProfileView: Error type: \(type(of: error))")
            print("❌ ProfileView: Error description: \(error.localizedDescription)")
            
            await MainActor.run {
                errorMessage = "Failed to upload profile image: \(error.localizedDescription)"
                showError = true
                isUploadingImage = false
                selectedImageItem = nil // Reset selection
            }
        }
    }
    
    private func compressImageData(_ data: Data) async -> Data {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = UIImage(data: data) else {
                    continuation.resume(returning: data)
                    return
                }
                
                // Resize to reasonable dimensions (max 512x512)
                let maxDimension: CGFloat = 512
                let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
                let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                // Compress to JPEG with 0.8 quality
                let compressedData = resizedImage?.jpegData(compressionQuality: 0.8) ?? data
                continuation.resume(returning: compressedData)
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