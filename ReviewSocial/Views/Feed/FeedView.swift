import SwiftUI

struct FeedView: View {
    @Binding var selectedTab: Int
    @StateObject private var reviewStore = ReviewStore.shared
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isRefreshing = false
    @State private var showingNotifications = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(reviewStore.reviews) { review in
                    ReviewCard(review: review)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle("ReviewSocial")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNotifications = true
                }) {
                    ZStack {
                        Image(systemName: "heart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        
                        // Notification badge - only show when there are unread notifications
                        if notificationManager.hasUnreadNotifications {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
        }
        .refreshable {
            await refreshFeed()
        }
        .onAppear {
            setupNavigationAppearance()
            Task {
                await loadReviews()
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NavigationView {
                NotificationsView()
                    .navigationTitle("Likes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingNotifications = false
                            }
                        }
                    }
            }
        }
    }
    
    private func setupNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        // Title styling
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    
    private func refreshFeed() async {
        isRefreshing = true
        await loadReviews()
        isRefreshing = false
    }
    
    private func loadReviews() async {
        do {
            let reviews = try await supabaseService.fetchReviews()
            await MainActor.run {
                reviewStore.reviews = reviews
            }
        } catch {
            print("Failed to load reviews: \(error)")
            // Fall back to local reviews if database fetch fails
            await reviewStore.refreshReviews()
        }
    }
}

#Preview {
    NavigationView {
        FeedView(selectedTab: .constant(0))
    }
} 