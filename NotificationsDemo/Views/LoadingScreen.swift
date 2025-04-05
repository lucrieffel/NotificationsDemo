//
//  LoadingScreen.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI
import FirebaseAuth

struct LoadingScreen: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var isLoading = true
    @State private var scale: CGFloat = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    // Background Gradient
                    LinearGradient(gradient: Gradient(colors:
                                                        [.white,
                                                         ColorType.blue2.color, ColorType.blue1.color]),
                                   startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(.all)
                    
                    LogoImage()
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .onAppear {
                            withAnimation(.easeIn(duration: 1.2)){
                                self.scale = 1.0
                                self.opacity = 1.0
                            }
                        }
                }
                .onAppear {
                    // Give the animation time to complete before checking auth
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        checkUserSession()
                    }
                }
            } else {
                // User is authenticated and data is loaded
                if authViewModel.userSession != nil && authViewModel.currentUser != nil {
                    ContentView() //tabview & navigation stack here
                } else {
                    LoginView()
                }
            }
        }
    }
    
    private func checkUserSession() {
        // Single place to check auth state
        if Auth.auth().currentUser != nil {
            // Only fetch if needed
            if authViewModel.currentUser == nil {
                Task {
                    print("Loading user data...")
                    await authViewModel.fetchCurrentUser()
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            } else {
                // Already have the user data
                self.isLoading = false
                print("already have user data")
            }
        } else {
            // No user logged in
            self.isLoading = false
            print("not logged in")
        }
    }
}

#Preview {
    LoadingScreen()
        .environmentObject(AuthViewModel())
}
