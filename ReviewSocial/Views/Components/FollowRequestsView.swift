import SwiftUI

struct FollowRequestsView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var followRequests: [FollowRequest] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading requests...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if followRequests.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Follow Requests")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text("When people request to follow you, they'll appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(followRequests) { request in
                            FollowRequestRow(
                                request: request,
                                onApprove: { approveRequest(request) },
                                onDeny: { denyRequest(request) }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Follow Requests")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadFollowRequests()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadFollowRequests() {
        isLoading = true
        Task {
            do {
                let requests = try await supabaseService.getPendingFollowRequests()
                await MainActor.run {
                    self.followRequests = requests
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func approveRequest(_ request: FollowRequest) {
        Task {
            do {
                try await supabaseService.approveFollowRequest(
                    requestId: request.id,
                    requesterId: request.requesterId
                )
                await MainActor.run {
                    followRequests.removeAll { $0.id == request.id }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    private func denyRequest(_ request: FollowRequest) {
        Task {
            do {
                try await supabaseService.denyFollowRequest(requestId: request.id)
                await MainActor.run {
                    followRequests.removeAll { $0.id == request.id }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

struct FollowRequestRow: View {
    let request: FollowRequest
    let onApprove: () -> Void
    let onDeny: () -> Void
    
    var body: some View {
        HStack {
            // Profile Image
            AsyncImage(url: URL(string: request.requesterAvatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .overlay(
                        Text(String(request.requesterDisplayName?.first ?? request.requesterUsername?.first ?? "U").uppercased())
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.requesterDisplayName ?? request.requesterUsername ?? "Unknown User")
                    .font(.system(size: 16, weight: .medium))
                Text("wants to follow you")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text(request.createdAt, style: .relative)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Deny") {
                    onDeny()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(16)
                
                Button("Accept") {
                    onApprove()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    FollowRequestsView()
} 