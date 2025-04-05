//
//  MusicChoiceView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI

struct MusicChoiceView: View {
    @EnvironmentObject private var viewModel: CopingActivityViewModel
    @State private var navigateToConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose a Music Service")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Apple Music Button
                Button(action: {
                    openAppleMusic()
                    addMusicActivity(with: "Apple Music")
                }) {
                    HStack {
                        Image("apple-music-logo")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Apple Music")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Spotify Button
                Button(action: {
                    openSpotify()
                    addMusicActivity(with: "Spotify")
                }) {
                    HStack {
                        Image("spotify-logo")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Spotify")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            NavigationLink(
                destination: CopingActivityDetailView(activity: "Listen to Music"),
                isActive: $navigateToConfirmation
            ) {
                EmptyView()
            }
        }
        .padding()
        .navigationTitle("Music")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper functions to launch external apps:
    private func openAppleMusic() {
        if let url = URL(string: "music://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let appStoreURL = URL(string: "https://apps.apple.com/us/app/apple-music/id1108187390") {
                UIApplication.shared.open(appStoreURL)
            }
        }
    }
    
    private func openSpotify() {
        if let url = URL(string: "spotify://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let appStoreURL = URL(string: "https://apps.apple.com/us/app/spotify-music-and-podcasts/id324684580") {
                UIApplication.shared.open(appStoreURL)
            }
        }
    }
    
    // Create and add a CopingActivity document with the selected music service.
    private func addMusicActivity(with service: String) {
        Task {
            let musicActivity = CopingActivity(activityName: "Listen to Music", musicService: service)
            viewModel.addCopingActivity(activity: musicActivity)
            // Once added, navigate to confirmation view.
            navigateToConfirmation = true
        }
    }
}

#Preview {
    NavigationStack {
        MusicChoiceView()
            .environmentObject(CopingActivityViewModel())
    }
}

