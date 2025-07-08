import SwiftUI

// Notification State Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var hasUnreadNotifications: Bool = false
    
    private init() {
        // Start with empty notifications - will be populated from real data
        updateUnreadStatus()
    }
    
    func loadNotifications() {
        // This would load notifications from the database in a real app
        // For now, start with empty notifications
        notifications = []
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
        .navigationTitle("Likes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Mark all notifications as read when the view appears
            notificationManager.markAllAsRead()
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
            return notificationManager.notifications.filter { $0.type == .follow }
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
}

enum NotificationType {
    case like, dislike, comment, follow, mention
}

struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
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
            onTap()
        }
    }
    
    private var iconName: String {
        switch notification.type {
        case .like: return "heart.fill"
        case .dislike: return "heart.slash.fill"
        case .comment: return "message.fill"
        case .follow: return "person.fill.badge.plus"
        case .mention: return "at"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .like: return .red
        case .dislike: return .red
        case .comment: return .blue
        case .follow: return .green
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