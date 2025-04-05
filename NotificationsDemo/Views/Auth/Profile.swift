//
//  Profile.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI

struct Profile: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingSheet = false
    @State private var showLogoutConfirmation = false
    @State private var navigateToLoadingScreen = false
    
    var body: some View {
        ZStack {
            ColorType.darkBlue.color.opacity(0.05)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header section
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .foregroundColor(ColorType.darkBlue.color)
                            .clipShape(Circle())
                            .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                            .padding(.top, 24)
                        
                        if let userName = authViewModel.currentUser?.fullname {
                            Text(userName)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(authViewModel.currentUser?.email ?? "user@email.com")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else {
                            Text("User")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)
                    
                    // Profile options in cards
                    VStack(spacing: 16) {

                        
                        profileOptionCard(title: "Change Password", icon: "key", action: {
                            print("Change Password selected")
                            showingSheet.toggle()
                        })
                        .sheet(isPresented: $showingSheet) {
                            ResetPasswordForm()
                        }
                        
                        
                        profileOptionCard(title: "Log Out", icon: "arrow.backward", action: {
                            print("Log Out selected")
                            showLogoutConfirmation = true
                        })
                        .foregroundColor(.red)
                        .confirmationDialog("Are you sure you want to log out?",
                                            isPresented: $showLogoutConfirmation) {
                            Button("Log Out", role: .destructive) {
                                authViewModel.signOut()
                                navigateToLoadingScreen = true
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $navigateToLoadingScreen) {
            LoadingScreen()
                .environmentObject(authViewModel)
        }
    }
    
    // Helper function to create consistent profile option cards
    private func profileOptionCard(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        Profile()
            .environmentObject(AuthViewModel())
    }
}


#Preview {
    Profile()
}
