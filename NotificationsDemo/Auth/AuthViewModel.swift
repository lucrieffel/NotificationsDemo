//
//  AuthViewModel.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//

import Foundation
import Firebase
import FirebaseAuth
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
//    @Published var authError: AuthError?
    @Published var isLoading = false
    @Published var showAlert = false
    var isListeningToAuthState = false
    
    private let db = Firestore.firestore()
    
    init() {
        userSession = Auth.auth().currentUser
        if userSession != nil {
            Task {
                await fetchCurrentUser()
            }
        }
    }
    
    // MARK: - Fetch Current User
    func fetchCurrentUser() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user found.")
            return
        }
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            self.currentUser = try snapshot.data(as: User.self)
            if let fullname = self.currentUser?.fullname {
                UserDefaultsManager.shared.saveUserName(fullname)
            }
            
            print("DEBUG: User data fetched successfully for UID: \(uid).")
        } catch {
            print("DEBUG: Failed to fetch user: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch User by ID
    func fetchUser(withID userID: String) async {
        do {
            let snapshot = try await db.collection("users").document(userID).getDocument()
            self.currentUser = try snapshot.data(as: User.self)
            
            // Save user name to UserDefaults
            if let fullname = self.currentUser?.fullname {
                UserDefaultsManager.shared.saveUserName(fullname)
            }
            
            print("DEBUG: User data fetched successfully for user ID: \(userID).")
        } catch {
            print("DEBUG: Failed to fetch user by ID: \(error.localizedDescription)")
        }
    }
    
//    func handleAuthError(_ error: Error) {
//        let nsError = error as NSError
//        if let errorCode = AuthErrorCode.Code(rawValue: nsError.code) {
//            self.authError = AuthError(authErrorCode: errorCode)
//            print("DEBUG: Auth error code: \(errorCode.rawValue), description: \(nsError.localizedDescription)")
//        } else {
//            self.authError = .unknown
//            print("DEBUG: Unknown auth error: \(nsError.localizedDescription)")
//        }
//    }
    
    // MARK: - Sign In
    func signIn(withEmail email: String, password: String) async throws {
        isLoading = true
        print("DEBUG: Signing in with email: \(email)")
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            UserDefaultsManager.shared.saveUserID(result.user.uid)
            UserDefaultsManager.shared.saveUserEmail(email)
            
            // Fetch user details
            await fetchUser(withID: result.user.uid)

            // Ensure full name is stored after fetch
            if let fullname = self.currentUser?.fullname {
                UserDefaultsManager.shared.saveUserName(fullname)
            }

            print("DEBUG: Sign-in successful, user ID: \(result.user.uid)")
        }
//        catch {
//            print("DEBUG: Failed to sign in: \(error.localizedDescription)")
//            handleAuthError(error)
//            throw error
//        }
        
        isLoading = false
    }
    
    // MARK: - Create User
    func createUser(withEmail email: String, password: String, fullname: String) async throws {
        isLoading = true
        print("DEBUG: Creating user with email: \(email)")

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let userID = result.user.uid

            let newUser = User(
                userID: userID,
                fullname: fullname,
                email: email,
                dateCreated: Timestamp()
            )

            let userData: [String: Any] = [
                "userID": newUser.userID,
                "fullname": newUser.fullname,
                "email": newUser.email,
                "dateCreated": newUser.dateCreated
            ]

            try await db.collection("users").document(userID).setData(userData)
            print("DEBUG: User document successfully created in Firestore.")

            // Update the model state in the proper order
            self.currentUser = newUser
            self.userSession = result.user
            
            // Save user data to UserDefaults
            UserDefaultsManager.shared.saveUserID(userID)
            UserDefaultsManager.shared.saveUserEmail(email)
            UserDefaultsManager.shared.saveUserName(fullname)

            print("DEBUG: User created and session initialized.")
        } catch {
            print("DEBUG: Failed to create user: \(error.localizedDescription)")
            isLoading = false
            throw error
        }
        
        // Ensure loading state is properly reset
        isLoading = false
    }
    
    // MARK: - Save User Data
    func saveUserData(_ user: User) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            try db.collection("users").document(uid).setData(from: user)
            print("DEBUG: User data successfully saved for UID: \(uid).")
        } catch {
            print("DEBUG: Failed to save user data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(emailAddress: String) async throws {
        guard !emailAddress.isEmpty, emailAddress.contains("@") else {
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address."])
        }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: emailAddress)
            print("DEBUG: Password reset email sent to \(emailAddress).")
        } catch {
            print("DEBUG: Failed to send reset email: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Update Password
    func updatePassword(newPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }
        
        do {
            try await user.updatePassword(to: newPassword)
            print("DEBUG: Password successfully updated.")
        } catch {
            print("DEBUG: Failed to update password: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            UserDefaultsManager.shared.clearUserData()
            print("DEBUG: User signed out successfully.")
        } catch {
            print("DEBUG: Failed to sign out: \(error.localizedDescription)")
        }
    }
}

protocol AuthenticationFormProtocol {
    var formIsValid: Bool { get }
}
