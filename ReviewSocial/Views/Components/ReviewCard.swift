import SwiftUI



struct ReviewCard: View {
    let review: Review
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showingComments = false
    @State private var showingImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var showingEditReview = false
    @State private var showingDeleteAlert = false
    @StateObject private var supabaseService = SupabaseService.shared
    
    init(review: Review) {
        self.review = review
        self._isBookmarked = State(initialValue: review.isBookmarked)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            contentSection
            actionButtons
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showingComments) {
            ReviewDetailView(review: review)
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            ImageViewer(
                imageURLs: review.imageURLs,
                initialIndex: selectedImageIndex,
                isPresented: $showingImageViewer
            )
        }
        .sheet(isPresented: $showingEditReview) {
            NavigationView {
                CreateReviewView(editingReview: review) {
                    // Close the edit sheet when update is successful
                    showingEditReview = false
                }
                .navigationTitle("Edit Review")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingEditReview = false
                        }
                    }
                }
            }
        }
        .alert("Delete Review", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                print("🗑️ User confirmed deletion of review: \(review.id)")
                Task {
                    await deleteReview()
                }
            }
            Button("Cancel", role: .cancel) { 
                print("❌ User cancelled deletion")
            }
        } message: {
            Text("Are you sure you want to delete this review? This action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        HStack {
            NavigationLink(destination: ProfileView(userId: review.userId)) {
                // Profile image
                Group {
                    if let profileImageURL = review.profileImageURL, !profileImageURL.isEmpty {
                        AsyncImage(url: URL(string: profileImageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.6)
                                )
                        }
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text(profileInitials)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    NavigationLink(destination: ProfileView(userId: review.userId)) {
                        Text("@\(review.username ?? "user")")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(timeAgoDisplay)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Text(review.category.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Only show menu button if this is the current user's review
            if supabaseService.currentUser?.id == review.userId {
                Menu {
                    Button(action: {
                        showingEditReview = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        print("🗑️ Delete button tapped for review: \(review.id)")
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
    }
    
    private var profileInitials: String {
        if let displayName = review.displayName, !displayName.isEmpty {
            return String(displayName.prefix(2).uppercased())
        } else if let username = review.username, !username.isEmpty {
            return String(username.prefix(2).uppercased())
        } else {
            return "U"
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(review.title)
                .font(.system(size: 18, weight: .semibold))
                .lineLimit(nil)
            
            starRating
            
            Text(review.content)
                .font(.system(size: 15))
                .lineLimit(nil)
            
            imageCarousel
        }
    }
    
    private var starRating: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { star in
                Image(systemName: starIcon(for: star))
                    .foregroundColor(Color.gray.opacity(0.7))
                    .font(.system(size: 14))
            }
            Text(String(format: "%.1f", review.rating))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var imageCarousel: some View {
        Group {
            if !review.imageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(review.imageURLs.indices, id: \.self) { index in
                            imageView(at: index)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }
    
    private func imageView(at index: Int) -> some View {
        AsyncImage(url: URL(string: review.imageURLs[index])) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 200)
                .clipped()
                .cornerRadius(12)
                .onTapGesture {
                    selectedImageIndex = index
                    showingImageViewer = true
                }
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 200)
                .cornerRadius(12)
                .overlay(
                    ProgressView()
                )
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            likeButton
            commentButton
            shareButton
            bookmarkButton
            Spacer()
        }
        .padding(.top, 4)
    }
    
    private var likeButton: some View {
        Button(action: { isLiked.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : .secondary)
                Text("\(review.likesCount + (isLiked ? 1 : 0))")
                    .foregroundColor(.secondary)
            }
            .font(.system(size: 13))
        }
    }
    
    private var commentButton: some View {
        Button(action: { showingComments = true }) {
            HStack(spacing: 4) {
                Image(systemName: "message")
                    .foregroundColor(.secondary)
                Text("\(review.commentsCount)")
                    .foregroundColor(.secondary)
            }
            .font(.system(size: 13))
        }
    }
    
    private var shareButton: some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.secondary)
                Text("\(review.sharesCount)")
                    .foregroundColor(.secondary)
            }
            .font(.system(size: 13))
        }
    }
    
    private var bookmarkButton: some View {
        Button(action: { 
            isBookmarked.toggle()
        }) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundColor(isBookmarked ? .blue : .secondary)
                .font(.system(size: 13))
        }
    }
    
    private func starIcon(for star: Int) -> String {
        if star < Int(review.rating) {
            return "star.fill"
        } else if star < Int(review.rating) + 1 && review.rating.truncatingRemainder(dividingBy: 1) >= 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
    
    private var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: review.dateCreated, relativeTo: Date())
    }
    
    private func deleteReview() async {
        print("🗑️ deleteReview() called for review: \(review.id)")
        do {
            print("🔄 Calling supabaseService.deleteReview...")
            try await supabaseService.deleteReview(reviewId: review.id)
            print("✅ Review deleted from database successfully")
            
            // Remove from local store
            await MainActor.run {
                ReviewStore.shared.reviews.removeAll { $0.id == review.id }
                print("✅ Review removed from local store")
            }
        } catch {
            print("❌ Failed to delete review: \(error)")
            // You might want to show an error alert here
        }
    }
}

#Preview {
    ScrollView {
        ReviewCard(review: Review.sampleReview)
            .padding()
    }
} 