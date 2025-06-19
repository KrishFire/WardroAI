import SwiftUI
import AuthenticationServices // Import for Sign in with Apple

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingForgotPasswordSheet = false // State for presenting the sheet

    // State to control navigation to SignUpView
    @Binding var showingSignUpView: Bool

    var body: some View {
        NavigationView { // Or NavigationStack for iOS 16+
            VStack(spacing: 20) {
                Text("Welcome Back!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Image(systemName: "person.circle.fill") // Placeholder for app logo or relevant image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.bottom, 20)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Button(action: {
                        authViewModel.signInWithEmail(email: email, password: password)
                    }) {
                        Text("Login")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor) // Use the project's accent color
                            .cornerRadius(10)
                    }
                }

                // Divider for visual separation
                HStack {
                    VStack { Divider() }
                    Text("OR")
                        .foregroundColor(.gray)
                    VStack { Divider() }
                }
                .padding(.vertical, 10)

                // Sign in with Apple Button
                SignInWithAppleButton(
                    .signIn, // Can be .signIn or .signUp
                    onRequest: { request in
                        // Generate and store nonce, then set it on the request
                        let nonce = authViewModel.generateAndStoreNonce()
                        request.nonce = nonce
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        // Handle the result (success or failure)
                        authViewModel.handleSignInWithApple(result: result)
                    }
                )
                .signInWithAppleButtonStyle(.black) // Or .white, .whiteOutline
                .frame(height: 50) // Standard height
                .cornerRadius(10)

                // Forgot Password Button
                Button(action: {
                    showingForgotPasswordSheet = true
                }) {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .foregroundColor(Color.accentColor)
                }
                .padding(.top, -10) // Adjust spacing slightly
                .padding(.bottom, 10)

                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    showingSignUpView = true
                }) {
                    Text("Don't have an account? Sign Up")
                        .foregroundColor(Color.accentColor)
                }

                Spacer()
            }
            .padding()
            //.navigationTitle("Login") // Keep it clean, title is prominent
            //.navigationBarHidden(true) // Often auth screens hide the nav bar
        }
        .onAppear {
            authViewModel.errorMessage = nil // Clear previous errors when view appears
        }
        .sheet(isPresented: $showingForgotPasswordSheet) { // Sheet modifier
            ForgotPasswordView()
                .environmentObject(authViewModel) // Pass the view model
        }
    }
}

// Preview requires a binding and environment object
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(showingSignUpView: .constant(false))
            .environmentObject(AuthViewModel()) // Provide a dummy for preview
    }
} 