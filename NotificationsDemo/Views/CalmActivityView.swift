//
//  CalmActivityView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI

struct CalmActivityView: View {
    @State private var navigateToConfirmation = false
    
    var body: some View {
        VStack {
            Text("Launching Calm...")
                .font(.headline)
                .padding()
            
            NavigationLink(
                destination: CopingActivityDetailView(activity: "Calm App"),
                isActive: $navigateToConfirmation
            ) {
                EmptyView()
            }
            .hidden()
        }
        .onAppear {
            openCalmApp()
        }
    }
    
    private func openCalmApp() {
        guard let calmUrl = URL(string: "calm://") else { return }
        if UIApplication.shared.canOpenURL(calmUrl) {
            UIApplication.shared.open(calmUrl) { _ in
                // After opening Calm, go to confirmation screen
                navigateToConfirmation = true
            }
        } else {
            // If Calm not installed, open App Store
            if let appStoreURL = URL(string: "https://apps.apple.com/us/app/calm/id571800810") {
                UIApplication.shared.open(appStoreURL) { _ in
                    navigateToConfirmation = true
                }
            }
        }
    }
}

#Preview {
    CalmActivityView()
}
