//
//  LoginView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject private var authViewModel: AuthViewModel
//    @EnvironmentObject private var communityViewModel: CommunityViewModel
//    @EnvironmentObject var moodViewModel: MoodViewModel
    @State private var showRegistration = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack {
                Image("logo-placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 120)
                    .padding(.vertical, 32)

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        CustomTextField(placeholder: "name@example.com", text: $email, autocapitalization: .never)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        CustomTextField(placeholder: "Enter your password", text: $password, isSecure: true, autocapitalization: .never)
                        
                        HStack {
                            Spacer()
                            NavigationLink(destination: ResetPasswordView(
                                email: email,
                                backButtonText: "Back to Login",
                                showBackButton: true,
                                resetContext: ""
                            )) {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Button {
                    isLoading = true
                    Task {
                        do {
                            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                            try await authViewModel.signIn(withEmail: trimmedEmail, password: password)

                            // Add a slight delay for a smooth transition
                            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds delay
                        }
//                        catch {
//                            if let nsError = error as NSError? {
//                                if let errorCode = AuthErrorCode.Code(rawValue: nsError.code) {
//                                    authViewModel.authError = AuthError(authErrorCode: errorCode)
//                                } else {
//                                    authViewModel.authError = .unknown
//                                }
//                            } else {
//                                authViewModel.authError = .unknown
//                            }
//                            authViewModel.showAlert = true
//                        }
                        isLoading = false
                    }
                } label: {
                    HStack {
                        Text("SIGN IN")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 32, height: 40)
                }
                .background(Color(.systemBlue))
                .cornerRadius(10)
                .padding(.top, 24)

                Spacer()

                NavigationLink {
                    Registration()
                        .environmentObject(authViewModel)
                } label: {
                    HStack {
                        Text("Don't have an account?")
                        Text("Sign up")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14))
                }
            }
            
            .overlay(
                Group {
                    if isLoading {
                        AddTaskLoadingView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.5))
                    }
                }
            )
            
        }
    }
}

