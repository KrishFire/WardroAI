import SwiftUI
import AuthenticationServices // Import for Sign in with Apple

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // State to control navigation back to LoginView
    @Binding var showingSignUpView: Bool

    var body: some View {
        NavigationView { // Or NavigationStack for iOS 16+
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Image(systemName: "person.badge.plus") // Placeholder image
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
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Button(action: {
                        if password == confirmPassword {
                            authViewModel.signUpWithEmail(email: email, password: password)
                        } else {
                            authViewModel.errorMessage = "Passwords do not match."
                        }
                    }) {
                        Text("Sign Up")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
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
                    .signUp, // Use .signUp here
                    onRequest: { request in
                        // Generate and store nonce, then set it on the request
                        let nonce = authViewModel.generateAndStoreNonce()
                        request.nonce = nonce
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        authViewModel.handleSignInWithApple(result: result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(10)

                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    showingSignUpView = false // Go back to LoginView
                }) {
                    Text("Already have an account? Login")
                        .foregroundColor(Color.accentColor)
                }
                
                Spacer()
            }
            .padding()
            //.navigationTitle("Sign Up")
            //.navigationBarHidden(true)
        }
        .onAppear {
            authViewModel.errorMessage = nil // Clear previous errors
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(showingSignUpView: .constant(true))
            .environmentObject(AuthViewModel())
    }
} 