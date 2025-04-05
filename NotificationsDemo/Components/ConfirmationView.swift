//
//  ConfirmationView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI
import UIKit

struct ConfirmationView: View {
    let message: String
    let subMessage: String? // New optional sub-message
    let buttonTitle: String
    let buttonAction: () -> Void

    @State private var animateCheckmark = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .scaleEffect(animateCheckmark ? 1.2 : 0.8)
                .opacity(animateCheckmark ? 1 : 0.5)
                .animation(.easeInOut(duration: 0.6).repeatCount(1, autoreverses: true), value: animateCheckmark)
                .onAppear {
                    animateCheckmark = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }

            Text(message)
                .font(.title)
                .multilineTextAlignment(.center)
            
            // If subMessage exists, display it with a smaller font.
            if let subMessage = subMessage {
                Text(subMessage)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: buttonAction) {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
    }
}

//#Preview {
//    ConfirmationView()
//}
