import SwiftUI



struct ReviewCard: View {
    let review: Review
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showingComments = false
    @State private var showingImageViewer = false
    @State private var selectedImageIndex = 0
    
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
    }
    
    private var headerSection: some View {
        HStack {
            // Profile image placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("AR")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("@reviewmaster")
                        .font(.system(size: 15, weight: .medium))
                    
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
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
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
                    .foregroundColor(.yellow)
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
}

#Preview {
    ScrollView {
        ReviewCard(review: Review.sampleReview)
            .padding()
    }
} 