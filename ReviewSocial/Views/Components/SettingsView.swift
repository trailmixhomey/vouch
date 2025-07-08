import SwiftUI

struct SettingsView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var showingSignOutAlert = false
    @State private var isPrivateAccount = true
    @State private var pushNotifications = true
    @State private var emailNotifications = false
    @State private var showingDeleteAccountAlert = false
    @State private var isPrivateProfile = true
    @State private var isUpdatingPrivacy = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    private var user: User {
        // Use current user from service or create a default user
        if let currentUser = supabaseService.currentUser {
            return currentUser
        } else {
            // Return a default user if no authenticated user
            return User(
                username: "user",
                displayName: "User",
                email: "user@example.com",
                bio: "Welcome to ReviewSocial!"
            )
        }
    }
    
    var body: some View {
        List {
            // Profile Section
            Section {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(user.displayName.prefix(2).uppercased())
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("@\(user.username)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("View your profile")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            
            // Your Content Section
            Section("Your Content") {
                SettingsRow(
                    icon: "bookmark.fill",
                    iconColor: .orange,
                    title: "Bookmarked Reviews",
                    subtitle: "Reviews you've saved"
                )
                
                SettingsRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Liked Reviews",
                    subtitle: "Reviews you've liked"
                )
                
                SettingsRow(
                    icon: "clock.arrow.circlepath",
                    iconColor: .blue,
                    title: "Review History",
                    subtitle: "Your review activity"
                )
            }
            
            // Privacy Section
            Section("Privacy") {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Private Profile")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Require approval for new followers")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isUpdatingPrivacy {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Toggle("", isOn: $isPrivateProfile)
                            .onChange(of: isPrivateProfile) { _, newValue in
                                updatePrivacySettings(newValue)
                            }
                    }
                }
            }
            
            // Account Section
            Section("Account") {
                SettingsRow(
                    icon: "person.circle.fill",
                    iconColor: .gray,
                    title: "Account Settings",
                    subtitle: "Privacy, security, data"
                )
                
                SettingsRow(
                    icon: "bell.fill",
                    iconColor: .purple,
                    title: "Notifications",
                    subtitle: "Push notifications, email"
                )
                
                SettingsRow(
                    icon: "shield.fill",
                    iconColor: .green,
                    title: "Privacy & Safety",
                    subtitle: "Blocked accounts, content"
                )
            }
            
            // Support Section
            Section("Support") {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .blue,
                    title: "Help Center",
                    subtitle: "Get help and support"
                )
                
                SettingsRow(
                    icon: "flag.fill",
                    iconColor: .red,
                    title: "Report a Problem",
                    subtitle: "Something isn't working"
                )
                
                SettingsRow(
                    icon: "info.circle.fill",
                    iconColor: .gray,
                    title: "About",
                    subtitle: "Version, terms, policies"
                )
            }
            
            // Logout Section
            Section {
                Button(action: {
                    signOut()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        Text("Log Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadCurrentSettings() {
        if let currentUser = supabaseService.currentUser {
            isPrivateProfile = currentUser.isPrivate
        }
    }
    
    private func updatePrivacySettings(_ isPrivate: Bool) {
        isUpdatingPrivacy = true
        
        Task {
            do {
                try await supabaseService.updatePrivacySettings(isPrivate: isPrivate)
            } catch {
                await MainActor.run {
                    // Revert toggle if update failed
                    self.isPrivateProfile = !isPrivate
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
            
            await MainActor.run {
                self.isUpdatingPrivacy = false
            }
        }
    }
    
    private func signOut() {
        Task {
            do {
                try await supabaseService.signOut()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        Button(action: {
            // Handle navigation to specific settings
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
} 