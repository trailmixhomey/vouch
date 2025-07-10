import SwiftUI
import PhotosUI

struct CreateReviewView: View {
    @Binding var selectedTab: Int
    let editingReview: Review?
    let onEditComplete: (() -> Void)?
    @StateObject private var reviewStore = ReviewStore.shared
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var title = ""
    @State private var content = ""
    @State private var rating: Double = 3.0
    @State private var selectedCategory: ReviewCategory? = nil
    @State private var selectedImages: [String] = [] // URLs for uploaded images
    @State private var selectedPhotos: [PhotosPickerItem] = []
        @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var isPosting = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private var isEditing: Bool {
        editingReview != nil
    }
    
    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What are you reviewing? *")
                            .font(.headline)
                        TextField("Restaurant name, movie title, product name...", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Category pills (no header)
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
                    
                    // Your Review (combined rating and content)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Review")
                            .font(.headline)
                        
                        // Rating stars
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: {
                                        rating = Double(star)
                                    }) {
                                        Image(systemName: Double(star) <= rating ? "star.fill" : "star")
                                            .foregroundColor(Color.gray.opacity(0.7))
                                            .font(.system(size: 24))
                                    }
                                }
                            }
                            
                            Text(String(format: "%.0f/5", rating))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        // Review text box
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(minHeight: 120)
                            
                            TextEditor(text: $content)
                                .padding(8)
                                .frame(minHeight: 120)
                            
                            if content.isEmpty {
                                Text("Do tell...")
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
                    
                    // Bottom section with photo icons and post button
                    VStack(spacing: 12) {
                        // Photo icons at bottom left
                        HStack {
                            HStack(spacing: 16) {
                                // Camera icon
                                Button(action: {
                                    if CameraView.isCameraAvailable {
                                        showingCamera = true
                                    }
                                }) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondary)
                                }
                                .disabled(!CameraView.isCameraAvailable)
                                
                                // Photo library icon
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Post button at bottom right
                        HStack {
                            Spacer()
                            
                            Button(action: postReview) {
                                HStack(spacing: 6) {
                                    if isPosting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text(isPosting ? (isEditing ? "Updating..." : "Posting...") : (isEditing ? "Update" : "Post"))
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(canPost ? Color.blue : Color.gray)
                                .cornerRadius(20)
                            }
                            .disabled(!canPost || isPosting)
                        }
                    }
                }
                .padding()
            }
        .navigationTitle(isEditing ? "Edit Review" : "Write Review")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if isEditing {
                populateFieldsForEditing()
            }
        }
        .keyboardToolbar()
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotos, maxSelectionCount: 5, matching: .images)
        .sheet(isPresented: $showingCamera) {
            CameraView(isPresented: $showingCamera, capturedImage: $capturedImage)
        }
        .onChange(of: selectedPhotos) { newPhotos in
            Task {
                await loadSelectedPhotos(newPhotos)
            }
        }
        .onChange(of: capturedImage) { newImage in
            if let image = newImage {
                addCapturedImage(image)
            }
        }

        .alert(isEditing ? "Review Updated!" : "Review Posted!", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(isEditing ? "Your review has been updated successfully." : "Your review has been posted successfully and is now visible on the home feed.")
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
    
    private func addCapturedImage(_ image: UIImage) {
        print("📸 CreateReviewView: Adding captured image...")
        
        // Convert UIImage to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ CreateReviewView: Failed to convert image to JPEG data")
            return
        }
        
        // Create base64 data URL
        let base64String = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64String)"
        
        // Add to selected images
        selectedImages.append(dataURL)
        print("📸 CreateReviewView: Added captured image (\(imageData.count) bytes)")
        
        // Clear the captured image
        capturedImage = nil
    }
    
    private func populateFieldsForEditing() {
        guard let review = editingReview else { return }
        
        title = review.title
        content = review.content
        rating = review.rating
        selectedCategory = review.category
        selectedImages = review.imageURLs
    }
    
    private func postReview() {
        print("📝 CreateReviewView: Starting \(isEditing ? "update" : "post") review process...")
        print("🔍 CreateReviewView: Current user: \(supabaseService.currentUser?.username ?? "nil")")
        print("🔍 CreateReviewView: Is authenticated: \(supabaseService.isAuthenticated)")
        
        guard let category = selectedCategory else { 
            print("❌ CreateReviewView: No category selected")
            return 
        }
        
        print("🔍 CreateReviewView: Category selected: \(category.rawValue)")
        
        isPosting = true
        
        // Create or update review
        let userId = supabaseService.currentUser?.id ?? UUID()
        print("🔍 CreateReviewView: Using user ID: \(userId)")
        
        var reviewToSave = Review(
            userId: userId,
            title: title,
            content: content,
            rating: rating,
            category: category,
            imageURLs: selectedImages
        )
        
        if isEditing, let existingReview = editingReview {
            // Preserve the original ID and date for updates
            reviewToSave.id = existingReview.id
            reviewToSave.dateCreated = existingReview.dateCreated
            reviewToSave.dateModified = Date()
            reviewToSave.isEdited = true
        }
        
        print("🔍 CreateReviewView: Created review object - Title: \(title), Rating: \(rating)")
        
        // Save to database
        Task {
            do {
                if isEditing {
                    print("🔍 CreateReviewView: Calling supabaseService.updateReview...")
                    try await supabaseService.updateReview(reviewToSave)
                } else {
                    print("🔍 CreateReviewView: Calling supabaseService.createReview...")
                    try await supabaseService.createReview(reviewToSave)
                }
                
                print("✅ CreateReviewView: Review \(isEditing ? "updated" : "posted") successfully")
                
                await MainActor.run {
                    if isEditing {
                        // Update in local store
                        if let index = reviewStore.reviews.firstIndex(where: { $0.id == reviewToSave.id }) {
                            reviewStore.reviews[index] = reviewToSave
                        }
                    } else {
                        // Add to local store for immediate UI update
                        reviewStore.addReview(reviewToSave)
                    }
                    
                    // Reset form (only if not editing or when editing is done)
                    if !isEditing {
                        title = ""
                        content = ""
                        rating = 3.0
                        selectedCategory = nil
                        selectedImages = []
                        selectedPhotos = []
                        capturedImage = nil
                        
                        // Navigate to home tab
                        selectedTab = 0
                    }
                    
                    isPosting = false
                    
                    // Show success feedback
                    showingSuccessAlert = true
                    
                    // Call completion for editing if provided
                    if isEditing {
                        onEditComplete?()
                    }
                }
            } catch {
                print("❌ CreateReviewView: Failed to \(isEditing ? "update" : "post") review: \(error)")
                print("❌ CreateReviewView: Error type: \(type(of: error))")
                print("❌ CreateReviewView: Error description: \(error.localizedDescription)")
                
                await MainActor.run {
                    isPosting = false
                    errorMessage = "Failed to \(isEditing ? "update" : "post") review: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Initializers
extension CreateReviewView {
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
        self.editingReview = nil
        self.onEditComplete = nil
    }
    
    init(editingReview: Review, onEditComplete: @escaping () -> Void) {
        self._selectedTab = .constant(0)
        self.editingReview = editingReview
        self.onEditComplete = onEditComplete
    }
}

#Preview {
    CreateReviewView(selectedTab: .constant(1))
} 