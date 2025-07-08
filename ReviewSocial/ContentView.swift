import SwiftUI

struct ContentView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if supabaseService.isAuthenticated {
                VStack {
                    // Debug info at the top
                    VStack {
                        Text("🐛 DEBUG: Authenticated as \(supabaseService.currentUser?.username ?? "Unknown")")
                            .font(.caption)
                            .foregroundColor(.green)
                        Button("Force Sign Out") {
                            supabaseService.forceSignOut()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        Button("Debug Clear State") {
                            supabaseService.debugClearAuthState()
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                    .padding(.top)
                    
                    mainAppInterface
                }
            } else {
                VStack {
                    // Debug info at the top
                    Text("🐛 DEBUG: Not authenticated")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top)
                    
                    AuthenticationView()
                }
            }
        }
        .onAppear {
            print("🖼️ ContentView: View appeared - isAuthenticated: \(supabaseService.isAuthenticated), currentUser: \(supabaseService.currentUser?.username ?? "nil")")
        }
        .onChange(of: supabaseService.isAuthenticated) { isAuth in
            print("🖼️ ContentView: Authentication state changed to: \(isAuth)")
        }
    }
    
    private var mainAppInterface: some View {
            TabView(selection: $selectedTab) {
                NavigationView {
                    FeedView(selectedTab: $selectedTab)
                }
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("Home")
                }
                .tag(0)
                
                NavigationView {
                    CreateReviewView(selectedTab: $selectedTab)
                }
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "plus.app.fill" : "plus.app")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    Text("Create")
                }
                .tag(1)
                
                NavigationView {
                    SearchView()
                }
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(2)
                
                NavigationView {
                    ProfileView()
                }
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.crop.circle.fill" : "person.crop.circle")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                    Text("Profile")
                }
                .tag(3)
            .tint(.primary)
            .onAppear {
                // Customize tab bar appearance
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.systemBackground
                
                // Add subtle shadow
                appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
                appearance.shadowImage = UIImage()
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

#Preview {
    ContentView()
} 