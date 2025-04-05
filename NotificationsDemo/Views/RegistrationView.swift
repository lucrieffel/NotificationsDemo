//
//  RegistrationView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//

import SwiftUI
import Foundation
import Firebase
import FirebaseAuth

struct Registration: View {
    @State private var email = ""
    @State private var password = ""
    @State private var fullname = ""
    @State private var confirmPassword = ""
    @EnvironmentObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    Image("logo-placeholder")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 100)
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ZStack(alignment: .trailing) {
                                CustomTextField(placeholder: "name@example.com", text: $email, autocapitalization: .never)
                                
                                if !email.isEmpty {
                                    Image(systemName: isValidEmail(email) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isValidEmail(email) ? .green : .red)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ZStack(alignment: .trailing) {
                                CustomTextField(placeholder: "Enter your full name", text: $fullname, autocapitalization: .words, capitalizeWords: false)
                                
                                if !fullname.isEmpty {
                                    Image(systemName: isValidFullName(fullname) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isValidFullName(fullname) ? .green : .red)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ZStack(alignment: .trailing) {
                                CustomTextField(placeholder: "Enter your password", text: $password, isSecure: true, autocapitalization: .never)
                                
                                if !password.isEmpty {
                                    Image(systemName: isValidPassword(password) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isValidPassword(password) ? .green : .red)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ZStack(alignment: .trailing) {
                                CustomTextField(placeholder: "Confirm your password", text: $confirmPassword, isSecure: true, autocapitalization: .never)
                                
                                if !confirmPassword.isEmpty {
                                    Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(password == confirmPassword ? .green : .red)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Button {
                        Task {
                            do {
                                viewModel.isLoading = true
                                // Trim spaces only for the email field
                                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                                try await viewModel.createUser(withEmail: trimmedEmail, password: password, fullname: fullname)
                                // Let the authentication flow handle the navigation
                                dismiss()
                            }
//                            catch {
//                                if let nsError = error as NSError? {
//                                    if let errorCode = AuthErrorCode.Code(rawValue: nsError.code) {
//                                        viewModel.authError = AuthError(authErrorCode: errorCode)
//                                    } else {
//                                        viewModel.authError = .unknown
//                                    }
//                                } else {
//                                    viewModel.authError = .unknown
//                                }
//                                viewModel.showAlert = true
//                                print("DEBUG: Error creating user: \(viewModel.authError?.description ?? "Unknown error")")
//                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.isLoading ? "CREATING ACCOUNT..." : "SIGN UP")
                                .fontWeight(.semibold)
                            if !viewModel.isLoading {
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(width: UIScreen.main.bounds.width - 32, height: 40)
                    }
                    .background(Color(.systemBlue))
                    .disabled(!formIsValid || viewModel.isLoading)
                    .opacity((formIsValid && !viewModel.isLoading) ? 1.0 : 0.5)
                    .cornerRadius(10)
                    .padding(.top)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 2) {
                            Text("Already have an account?")
                            Text("Sign In")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                    }
                }
            }
            if viewModel.isLoading {
                AddTaskLoadingView()
            }
        }
//        .alert(isPresented: $viewModel.showAlert) {
//            Alert(title: Text("Error"),
//                  message: Text(viewModel.authError?.description ?? ""))
//        }
    }
}

// MARK: - AuthenticationFormProtocol
extension Registration: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
        && !password.isEmpty
        && !fullname.isEmpty
        && password == confirmPassword
        && password.count > 5
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        Registration()
            .environmentObject(AuthViewModel())
    }
}

private func isValidEmail(_ email: String) -> Bool {
    // Basic email validation logic
    return email.contains("@") && email.contains(".")
}

private func isValidPassword(_ password: String) -> Bool {
    // Password should be at least 6 characters long
    return password.count >= 6
}

private func isValidFullName(_ name: String) -> Bool {
    // Full name should contain at least two words
    return name.split(separator: " ").count >= 2
}
