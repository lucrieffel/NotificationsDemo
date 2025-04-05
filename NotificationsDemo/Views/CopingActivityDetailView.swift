//
//  CopingActivityDetailView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI
import UIKit

struct CopingActivityDetailView: View {
    let activity: String
    @State private var navigateToRoot = false

    var body: some View {
        VStack {
            ConfirmationView(
                message: "Do: \(activity).",
                subMessage: "We will check back in later.",
                buttonTitle: "Close",
                buttonAction: {
                    navigateToRoot = true
                }
            )
            
            //go back to content view
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
        .navigationTitle("Coping Activity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CopingActivityDetailView(activity: "Meditate")
    }
}
