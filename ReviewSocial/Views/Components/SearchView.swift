import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedFilter = SearchFilter.all
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var recentSearches: [String] = ["coffee shops", "movie reviews", "tech products"]
    
    var body: some View {
        VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search reviews, users, or businesses...", text: $searchText)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    
                    if !searchText.isEmpty {
                        Button("Search") {
                            performSearch()
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(SearchFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                                if !searchText.isEmpty {
                                    performSearch()
                                }
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 15, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedFilter == filter ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Content
                ScrollView {
                    if searchText.isEmpty {
                        // Recent searches and trending
                        VStack(alignment: .leading, spacing: 20) {
                            if !recentSearches.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recent Searches")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(recentSearches, id: \.self) { search in
                                        Button(action: {
                                            searchText = search
                                            performSearch()
                                        }) {
                                            HStack {
                                                Image(systemName: "clock")
                                                    .foregroundColor(.secondary)
                                                Text(search)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Image(systemName: "arrow.up.left")
                                                    .foregroundColor(.secondary)
                                                    .font(.system(size: 12))
                                            }
                                            .padding()
                                            .background(Color.gray.opacity(0.05))
                                        }
                                    }
                                }
                            }
                            
                            // Trending Categories
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Trending Categories")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(ReviewCategory.allCases.prefix(6), id: \.self) { category in
                                        Button(action: {
                                            searchText = category.rawValue.lowercased()
                                            performSearch()
                                        }) {
                                            HStack {
                                                Text(category.rawValue)
                                                    .font(.system(size: 15, weight: .medium))
                                                Spacer()
                                            }
                                            .padding()
                                            .background(Color.gray.opacity(0.05))
                                            .cornerRadius(12)
                                            .foregroundColor(.primary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    } else if isSearching {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Searching...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else if searchResults.isEmpty {
                        // No results
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No results found")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text("Try different keywords or check your spelling")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    } else {
                        // Search results
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults) { result in
                                SearchResultRow(result: result)
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .keyboardToolbar()
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        
        // Add to recent searches if not already there
        if !recentSearches.contains(searchText) {
            recentSearches.insert(searchText, at: 0)
            if recentSearches.count > 5 {
                recentSearches = Array(recentSearches.prefix(5))
            }
        }
        
        // Simulate search delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Mock search results
            searchResults = generateMockResults()
            isSearching = false
        }
    }
    
    private func generateMockResults() -> [SearchResult] {
        return [
            SearchResult(
                id: UUID(),
                type: .review,
                title: "Amazing Coffee Experience",
                subtitle: "Brew & Bean Coffee Co. • 4.5 ⭐",
                content: "Just discovered this hidden gem downtown...",
                imageURL: nil
            ),
            SearchResult(
                id: UUID(),
                type: .user,
                title: "@reviewmaster",
                subtitle: "Alex Review • 127 reviews",
                content: "Love sharing my thoughts on everything! 📝✨",
                imageURL: nil
            ),
            SearchResult(
                id: UUID(),
                type: .business,
                title: "Downtown Coffee Roasters",
                subtitle: "Coffee Shop • Downtown",
                content: "Highly rated by 89 reviewers",
                imageURL: nil
            )
        ]
    }
}

enum SearchFilter: String, CaseIterable {
    case all = "All"
    case reviews = "Reviews"
    case users = "Users"
    case businesses = "Places"
}

struct SearchResult: Identifiable {
    let id: UUID
    let type: SearchResultType
    let title: String
    let subtitle: String
    let content: String
    let imageURL: String?
}

enum SearchResultType {
    case review, user, business
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon/Image
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconName)
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                
                Text(result.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if !result.content.isEmpty {
                    Text(result.content)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            // Handle tap
        }
    }
    
    private var iconName: String {
        switch result.type {
        case .review: return "star.bubble"
        case .user: return "person"
        case .business: return "building.2"
        }
    }
}

#Preview {
    SearchView()
} 