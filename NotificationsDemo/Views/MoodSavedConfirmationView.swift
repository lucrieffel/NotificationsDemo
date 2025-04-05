//
//  MoodSavedConfirmationView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI
import UIKit

struct MoodSavedConfirmationView: View {
    @State private var navigateToRoot = false

    var body: some View {
        VStack {
            // Use the reusable component.
            ConfirmationView(
                message: "Mood successfully saved!",
                subMessage: "",
                buttonTitle: "Go Home",
                buttonAction: {
                    navigateToRoot = true
                }
            )
            // Hidden NavigationLink to navigate back to ContentView.
            NavigationLink(
                destination: ContentView()
                    .environmentObject(AuthViewModel())
                    .environmentObject(MoodViewModel())
                    .environmentObject(HealthKitManager())
                ,
                isActive: $navigateToRoot
            ) {
                EmptyView()
            }
            .hidden()
        }
    }
}

#Preview {
    NavigationStack {
        MoodSavedConfirmationView()
            .environmentObject(AuthViewModel())
            .environmentObject(MoodViewModel())
            .environmentObject(HealthKitManager())
    }
}
