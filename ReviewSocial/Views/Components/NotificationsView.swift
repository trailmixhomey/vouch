import SwiftUI

// Notification State Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var hasUnreadNotifications: Bool = false
    @Published var followRequests: [FollowRequest] = []
    
    private let supabaseService = SupabaseService.shared
    
    private init() {
        // Start with empty notifications - will be populated from real data
        updateUnreadStatus()
    }
    
    func loadNotifications() {
        // Load regular notifications and follow requests
        loadFollowRequests()
        updateUnreadStatus()
    }
    
    func loadFollowRequests() {
        Task {
            do {
                let requests = try await supabaseService.getPendingFollowRequests()
                await MainActor.run {
                    self.followRequests = requests
                    self.convertFollowRequestsToNotifications()
                }
            } catch {
                print("Failed to load follow requests: \(error)")
            }
        }
    }
    
    private func convertFollowRequestsToNotifications() {
        // Convert follow requests to notifications
        let requestNotifications = followRequests.map { request in
            AppNotification(
                id: request.id,
                type: .followRequest,
                title: "Follow Request",
                message: "@\(request.requesterUsername ?? "User") wants to follow you",
                timestamp: request.createdAt,
                isRead: false,
                actionUserId: request.requesterId,
                relatedReviewId: nil,
                followRequest: request
            )
        }
        
        // Remove old follow request notifications and add new ones
        notifications = notifications.filter { $0.type != .followRequest }
        notifications.append(contentsOf: requestNotifications)
        notifications.sort { $0.timestamp > $1.timestamp }
        updateUnreadStatus()
    }
    
    func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        updateUnreadStatus()
    }
    
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            updateUnreadStatus()
        }
    }
    
    private func updateUnreadStatus() {
        hasUnreadNotifications = notifications.contains { !$0.isRead }
    }
}

struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var selectedFilter = NotificationFilter.all
    
    var body: some View {
        VStack(spacing: 0) {
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(NotificationFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
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
                .padding(.vertical)
                
                // Notifications List
                if filteredNotifications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No notifications")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("We'll notify you when there's something new")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredNotifications) { notification in
                                NotificationRow(
                                    notification: notification,
                                    onTap: {
                                        notificationManager.markAsRead(notification)
                                    }
                                )
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Load notifications when the view appears
            notificationManager.loadNotifications()
        }
    }
    
    private var filteredNotifications: [AppNotification] {
        switch selectedFilter {
        case .all:
            return notificationManager.notifications
        case .likes:
            return notificationManager.notifications.filter { $0.type == .like || $0.type == .dislike }
        case .comments:
            return notificationManager.notifications.filter { $0.type == .comment }
        case .follows:
            return notificationManager.notifications.filter { $0.type == .follow || $0.type == .followRequest }
        }
    }
}

enum NotificationFilter: String, CaseIterable {
    case all = "All"
    case likes = "Likes"
    case comments = "Comments"  
    case follows = "Follows"
}

struct AppNotification: Identifiable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let actionUserId: UUID?
    let relatedReviewId: UUID?
    let followRequest: FollowRequest?
    
    init(id: UUID, type: NotificationType, title: String, message: String, timestamp: Date, isRead: Bool, actionUserId: UUID?, relatedReviewId: UUID?, followRequest: FollowRequest? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.actionUserId = actionUserId
        self.relatedReviewId = relatedReviewId
        self.followRequest = followRequest
    }
}

enum NotificationType {
    case like, dislike, comment, follow, followRequest, mention
}

struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                        .font(.system(size: 18))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(notification.isRead ? .secondary : .primary)
                
                Text(notification.message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(timeAgoDisplay)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                // Follow request action buttons
                if notification.type == .followRequest, let followRequest = notification.followRequest {
                    HStack(spacing: 8) {
                        Button("Accept") {
                            handleFollowRequest(followRequest, accept: true)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(isProcessing)
                        
                        Button("Decline") {
                            handleFollowRequest(followRequest, accept: false)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .disabled(isProcessing)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.02))
        .contentShape(Rectangle())
        .onTapGesture {
            if notification.type != .followRequest {
                onTap()
            }
        }
    }
    
    private func handleFollowRequest(_ followRequest: FollowRequest, accept: Bool) {
        isProcessing = true
        
        Task {
            do {
                if accept {
                    try await SupabaseService.shared.approveFollowRequest(requestId: followRequest.id, requesterId: followRequest.requesterId)
                } else {
                    try await SupabaseService.shared.denyFollowRequest(requestId: followRequest.id)
                }
                
                // Refresh notifications
                await MainActor.run {
                    NotificationManager.shared.loadFollowRequests()
                    isProcessing = false
                }
            } catch {
                print("Failed to handle follow request: \(error)")
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
    
    private var iconName: String {
        switch notification.type {
        case .like: return "heart.fill"
        case .dislike: return "heart.slash.fill"
        case .comment: return "message.fill"
        case .follow: return "person.fill.badge.plus"
        case .followRequest: return "person.fill.questionmark"
        case .mention: return "at"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .like: return .red
        case .dislike: return .red
        case .comment: return .blue
        case .follow: return .green
        case .followRequest: return .orange
        case .mention: return .orange
        }
    }
    
    private var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.timestamp, relativeTo: Date())
    }
}

#Preview {
    NotificationsView()
} 