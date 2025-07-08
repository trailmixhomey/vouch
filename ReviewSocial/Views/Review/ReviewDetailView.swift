import SwiftUI

struct ReviewDetailView: View {
    let review: Review
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showingImageViewer = false
    @State private var selectedImageIndex = 0
    @Environment(\.dismiss) private var dismiss
    
    init(review: Review) {
        self.review = review
        self._isBookmarked = State(initialValue: review.isBookmarked)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Review Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Review Card (expanded version)
                        VStack(alignment: .leading, spacing: 12) {
                            // Header
                            HStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text("AR")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Alex Review")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    HStack {
                                        Text("@reviewmaster")
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)
                                        
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        
                                        Text(timeAgoDisplay)
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Category
                            Text(review.category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            
                            // Title
                            Text(review.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(nil)
                            

                            
                            // Rating
                            HStack(spacing: 4) {
                                ForEach(0..<5) { star in
                                    Image(systemName: star < Int(review.rating) ? "star.fill" : (star < Int(review.rating) + 1 && review.rating.truncatingRemainder(dividingBy: 1) >= 0.5 ? "star.leadinghalf.filled" : "star"))
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 18))
                                }
                                Text(String(format: "%.1f", review.rating))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Content
                            Text(review.content)
                                .font(.system(size: 16))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Image carousel
                            if !review.imageURLs.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(review.imageURLs.indices, id: \.self) { index in
                                            AsyncImage(url: URL(string: review.imageURLs[index])) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(4/3, contentMode: .fill)
                                                    .frame(width: 300, height: 225)
                                                    .clipped()
                                                                                                         .cornerRadius(12)
                                                     .onTapGesture {
                                                         selectedImageIndex = index
                                                         showingImageViewer = true
                                                     }
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 300, height: 225)
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        ProgressView()
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 1)
                                }
                            }
                            
                            // Action buttons
                            HStack(spacing: 16) {
                                Button(action: { isLiked.toggle() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isLiked ? "heart.fill" : "heart")
                                            .foregroundColor(isLiked ? .red : .secondary)
                                        Text("\(review.likesCount + (isLiked ? 1 : 0))")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.system(size: 15))
                                }
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "message")
                                        .foregroundColor(.secondary)
                                    Text("\(comments.count)")
                                        .foregroundColor(.secondary)
                                }
                                .font(.system(size: 15))
                                
                                Button(action: {}) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(.secondary)
                                        Text("\(review.sharesCount)")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.system(size: 15))
                                }
                                
                                Button(action: { isBookmarked.toggle() }) {
                                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                        .foregroundColor(isBookmarked ? .blue : .secondary)
                                        .font(.system(size: 15))
                                }
                                
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        
                        Divider()
                        
                        // Comments Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Comments (\(comments.count))")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if comments.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "message")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray)
                                    Text("No comments yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Be the first to share your thoughts!")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 20)
                            } else {
                                ForEach(comments) { comment in
                                    CommentRow(comment: comment)
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                
                // Comment Input
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("AR")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .lineLimit(1...4)
                        
                        Button("Post") {
                            postComment()
                        }
                        .foregroundColor(.blue)
                        .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                loadComments()
            }
            .fullScreenCover(isPresented: $showingImageViewer) {
                ImageViewer(
                    imageURLs: review.imageURLs,
                    initialIndex: selectedImageIndex,
                    isPresented: $showingImageViewer
                )
            }
        }
    }
    
    private var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: review.dateCreated, relativeTo: Date())
    }
    
    private func loadComments() {
        // Start with empty comments - would load from database in real app
        comments = []
    }
    
    private func postComment() {
        let trimmedComment = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { return }
        
        let newComment = Comment(
            reviewId: review.id,
            userId: supabaseService.currentUser?.id ?? UUID(),
            content: trimmedComment
        )
        
        comments.append(newComment)
        newCommentText = ""
    }
}

struct CommentRow: View {
    let comment: Comment
    @State private var isLiked = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(
                    Text("U")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("@user")
                        .font(.system(size: 15, weight: .medium))
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(timeAgoDisplay)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.system(size: 15))
                    .lineLimit(nil)
                
                HStack(spacing: 16) {
                    Button(action: { isLiked.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .secondary)
                            Text("\(comment.likesCount + (isLiked ? 1 : 0))")
                                .foregroundColor(.secondary)
                        }
                        .font(.system(size: 13))
                    }
                    
                    Button("Reply") {
                        // Reply action
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: comment.dateCreated, relativeTo: Date())
    }
}

#Preview {
    ReviewDetailView(review: Review.sampleReview)
} 