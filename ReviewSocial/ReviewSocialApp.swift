import SwiftUI

// MARK: - Keyboard Toolbar Modifier
struct KeyboardToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarRole(.editor)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .foregroundColor(.blue)
                }
            }
    }
}

extension View {
    func keyboardToolbar() -> some View {
        self.modifier(KeyboardToolbar())
    }
}

@main
struct ReviewSocialApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 