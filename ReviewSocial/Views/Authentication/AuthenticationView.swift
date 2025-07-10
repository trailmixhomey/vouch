import SwiftUI

struct AuthenticationView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 8) {
                Image(systemName: "star.bubble")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("ReviewSocial")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Share your experiences with the world")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Form
            VStack(spacing: 16) {
                if isSignUp {
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(AuthTextFieldStyle())
                    
                    TextField("Username", text: $username)
                        .textFieldStyle(AuthTextFieldStyle())
                        .autocapitalization(.none)
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(AuthTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(AuthTextFieldStyle())
                
                if isSignUp {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(AuthTextFieldStyle())
                }
            }
            
            // Action Button
            Button(action: authenticate) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    Text(isSignUp ? (isLoading ? "Creating Account..." : "Sign Up") : (isLoading ? "Signing In..." : "Sign In"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canProceed ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canProceed || isLoading)
            
            // Toggle between Sign In/Sign Up
            Button(action: {
                isSignUp.toggle()
                clearFields()
            }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Terms and Privacy
            VStack(spacing: 4) {
                Text("By continuing, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Button("Terms of Service") {
                        // Terms action
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Text("and")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Privacy Policy") {
                        // Privacy action
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            print("🔐 AuthenticationView: View appeared")
        }
        .keyboardToolbar()
    }
    
    private var canProceed: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && 
                   !username.isEmpty && !displayName.isEmpty && password == confirmPassword
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func authenticate() {
        print("🔐 AuthenticationView: Starting authentication - isSignUp: \(isSignUp), email: \(email)")
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if isSignUp {
                    print("🔐 AuthenticationView: Calling signUp")
                    try await supabaseService.signUp(
                        email: email,
                        password: password,
                        username: username,
                        displayName: displayName
                    )
                } else {
                    print("🔐 AuthenticationView: Calling signIn")
                    try await supabaseService.signIn(
                        email: email,
                        password: password
                    )
                }
                
                await MainActor.run {
                    print("🔐 AuthenticationView: Authentication successful")
                    isLoading = false
                    clearFields()
                }
            } catch {
                await MainActor.run {
                    print("🔐 AuthenticationView: Authentication failed - \(error)")
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        username = ""
        displayName = ""
    }
}

struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}

#Preview {
    AuthenticationView()
} 