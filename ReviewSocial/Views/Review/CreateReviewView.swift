import SwiftUI
import PhotosUI

struct CreateReviewView: View {
    @Binding var selectedTab: Int
    @StateObject private var reviewStore = ReviewStore.shared
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var title = ""
    @State private var content = ""
    @State private var rating: Double = 3.0
    @State private var selectedCategory: ReviewCategory? = nil
    @State private var selectedImages: [String] = [] // URLs for uploaded images
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var showingCameraActionSheet = false
    @State private var isPosting = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ReviewCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                    }) {
                                        Text(category.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(selectedCategory == category ? .white : .primary)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What are you reviewing? *")
                            .font(.headline)
                        TextField("Restaurant name, movie title, product name...", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: {
                                        rating = Double(star)
                                    }) {
                                        Image(systemName: Double(star) <= rating ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 24))
                                    }
                                }
                            }
                            
                            Text(String(format: "%.0f/5", rating))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Review")
                            .font(.headline)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(minHeight: 120)
                            
                            TextEditor(text: $content)
                                .padding(8)
                                .frame(minHeight: 120)
                            
                            if content.isEmpty {
                                Text("Share your experience in detail...")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                    // Selected Images Preview
                    if !selectedImages.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photos")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selectedImages.indices, id: \.self) { index in
                                        ZStack(alignment: .topTrailing) {
                                            if selectedImages[index].hasPrefix("data:image") {
                                                // Handle base64 data URLs
                                                if let data = Data(base64Encoded: String(selectedImages[index].dropFirst(23))), // Remove "data:image/jpeg;base64,"
                                                   let uiImage = UIImage(data: data) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .aspectRatio(4/3, contentMode: .fill)
                                                        .frame(width: 120, height: 90)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                } else {
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(width: 120, height: 90)
                                                        .cornerRadius(8)
                                                }
                                            } else {
                                                // Handle regular URLs
                                                AsyncImage(url: URL(string: selectedImages[index])) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(4/3, contentMode: .fill)
                                                        .frame(width: 120, height: 90)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                } placeholder: {
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(width: 120, height: 90)
                                                        .cornerRadius(8)
                                                }
                                            }
                                            
                                            Button(action: {
                                                selectedImages.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white)
                                                    .clipShape(Circle())
                                            }
                                            .padding(4)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Add Photos Button
                    Button(action: {
                        showingCameraActionSheet = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text(selectedImages.isEmpty ? "Add Photos" : "Add More Photos")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Post Button
                    Button(action: postReview) {
                        HStack {
                            if isPosting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isPosting ? "Posting..." : "Post Review")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(canPost ? Color.blue : Color.gray)
                        .cornerRadius(8)
                    }
                    .disabled(!canPost || isPosting)
                }
                .padding()
            }
        .navigationTitle("Write Review")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotos, maxSelectionCount: 5, matching: .images)
        .onChange(of: selectedPhotos) { newPhotos in
            Task {
                await loadSelectedPhotos(newPhotos)
            }
        }
        .confirmationDialog("Add Photos", isPresented: $showingCameraActionSheet) {
            Button("Camera") {
                // For now, we'll use PhotosPicker. Camera integration would require additional setup
                showingImagePicker = true
            }
            Button("Photo Library") {
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how you'd like to add photos to your review")
        }
        .alert("Review Posted!", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Your review has been posted successfully and is now visible on the home feed.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCategory != nil
    }
    
    private func loadSelectedPhotos(_ newPhotos: [PhotosPickerItem]) async {
        print("📸 CreateReviewView: Loading \(newPhotos.count) selected photos...")
        
        var newImageURLs: [String] = []
        
        for photo in newPhotos {
            if let data = try? await photo.loadTransferable(type: Data.self) {
                // For now, we'll create a placeholder URL
                // In a real app, you'd upload this data to your storage service
                let placeholderURL = "data:image/jpeg;base64,\(data.base64EncodedString())"
                newImageURLs.append(placeholderURL)
                print("📸 CreateReviewView: Loaded photo data (\(data.count) bytes)")
            }
        }
        
        await MainActor.run {
            selectedImages = newImageURLs
            print("📸 CreateReviewView: Updated selectedImages with \(newImageURLs.count) photos")
        }
    }
    
    private func postReview() {
        print("📝 CreateReviewView: Starting post review process...")
        print("🔍 CreateReviewView: Current user: \(supabaseService.currentUser?.username ?? "nil")")
        print("🔍 CreateReviewView: Is authenticated: \(supabaseService.isAuthenticated)")
        
        guard let category = selectedCategory else { 
            print("❌ CreateReviewView: No category selected")
            return 
        }
        
        print("🔍 CreateReviewView: Category selected: \(category.rawValue)")
        
        isPosting = true
        
        // Create new review
        let userId = supabaseService.currentUser?.id ?? UUID()
        print("🔍 CreateReviewView: Using user ID: \(userId)")
        
        let newReview = Review(
            userId: userId,
            title: title,
            content: content,
            rating: rating,
            category: category,
            imageURLs: selectedImages
        )
        
        print("🔍 CreateReviewView: Created review object - Title: \(title), Rating: \(rating)")
        
        // Save to database
        Task {
            do {
                print("🔍 CreateReviewView: Calling supabaseService.createReview...")
                try await supabaseService.createReview(newReview)
                
                print("✅ CreateReviewView: Review posted successfully")
                
                await MainActor.run {
                    // Also add to local store for immediate UI update
                    reviewStore.addReview(newReview)
                    
                    // Reset form
                    title = ""
                    content = ""
                    rating = 3.0
                    selectedCategory = nil
                    selectedImages = []
                    selectedPhotos = []
                    isPosting = false
                    
                    // Navigate to home tab
                    selectedTab = 0
                    
                    // Show success feedback
                    showingSuccessAlert = true
                }
            } catch {
                print("❌ CreateReviewView: Failed to post review: \(error)")
                print("❌ CreateReviewView: Error type: \(type(of: error))")
                print("❌ CreateReviewView: Error description: \(error.localizedDescription)")
                
                await MainActor.run {
                    isPosting = false
                    errorMessage = "Failed to post review: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    CreateReviewView(selectedTab: .constant(1))
} 