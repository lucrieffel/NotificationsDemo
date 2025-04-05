//
//  ResetPasswordForm.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI

struct ResetPasswordForm: View {
    @State private var email: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading: Bool = false

    @EnvironmentObject private var authModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Enter your email, and we’ll send you instructions on how to reset your password.")) {
                    InputView(text: $email, type: .email)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                }
                
                Section(footer: Text("Once sent, check your email to reset your password.")) {
                    Button(action: {
                        Task {
                            await sendResetInstructions()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Send me reset instructions").bold()
                        }
                    }
                    .disabled(email.isEmpty || isLoading)
                }
            }
            .background(.white)
            .navigationTitle("Password Reset")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Password Reset"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    if alertMessage == "Reset instructions sent successfully." {
                        presentationMode.wrappedValue.dismiss()
                    }
                })
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func sendResetInstructions() async {
        guard email.contains("@") else {
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }
        
        isLoading = true
        do {
            try await authModel.resetPassword(emailAddress: email)
            alertMessage = "Reset instructions sent successfully."
        } catch {
            alertMessage = error.localizedDescription
        }
        isLoading = false
        showAlert = true
    }
}

#Preview {
    ResetPasswordForm().environmentObject(AuthViewModel())
}
