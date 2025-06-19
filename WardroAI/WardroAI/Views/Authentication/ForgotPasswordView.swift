import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView { // Or NavigationStack
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Button(action: {
                        authViewModel.sendPasswordReset(email: email) {
                            // This closure will be called after the reset attempt
                            // We'll use it to show a confirmation or error alert
                            if authViewModel.errorMessage == nil {
                                self.alertMessage = "If an account exists for \(email), a password reset link has been sent."
                            } else {
                                self.alertMessage = authViewModel.errorMessage ?? "An unknown error occurred."
                            }
                            self.showingAlert = true
                        }
                    }) {
                        Text("Send Reset Link")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(authViewModel.errorMessage == nil ? "Check Your Email" : "Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) { 
                        if authViewModel.errorMessage == nil { // If successful, dismiss the view
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(Color.accentColor)
            })
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                authViewModel.errorMessage = nil // Clear previous errors
            }
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
            .environmentObject(AuthViewModel())
    }
} 