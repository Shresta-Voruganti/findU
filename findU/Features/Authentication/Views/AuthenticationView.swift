import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and Welcome Text
                VStack(spacing: 10) {
                    Image("app-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    
                    Text("Welcome to findU")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Discover and share your fashion style")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                // Sign In Form
                if !isShowingSignUp {
                    SignInForm(viewModel: viewModel)
                } else {
                    SignUpForm(viewModel: viewModel)
                }
                
                // Social Sign In Buttons
                VStack(spacing: 15) {
                    Button(action: { viewModel.signInWithGoogle() }) {
                        HStack {
                            Image("google-logo")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Continue with Google")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    Button(action: { viewModel.signInWithInstagram() }) {
                        HStack {
                            Image("instagram-logo")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Continue with Instagram")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Toggle between Sign In and Sign Up
                Button(action: {
                    withAnimation {
                        isShowingSignUp.toggle()
                    }
                }) {
                    Text(isShowingSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.accentColor)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
}

struct SignInForm: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)
            
            Button(action: { viewModel.signIn() }) {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isLoading)
            
            if viewModel.isLoading {
                ProgressView()
            }
            
            Button("Forgot Password?") {
                viewModel.resetPassword()
            }
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

struct SignUpForm: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.username)
                .autocapitalization(.none)
            
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)
            
            Picker("Country", selection: $viewModel.country) {
                ForEach(viewModel.countries, id: \.self) { country in
                    Text(country).tag(country)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            Button(action: { viewModel.signUp() }) {
                Text("Create Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isLoading)
            
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    AuthenticationView()
} 