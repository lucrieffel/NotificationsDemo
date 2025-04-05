//
//  HomeItem.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import Foundation
import SwiftUI

struct HomeItem: View {
    var item: HomeItemType
    // Get color scheme based on item type
    private var colorScheme: HomeItemColorScheme {
        item.colorScheme
    }

    var body: some View {
        VStack(spacing: 12) {
            // Icon with background circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [colorScheme.primaryColor, colorScheme.secondaryColor]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: colorScheme.primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
            }
            
            // Text label
            Text(item.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colorScheme.textColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 70)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

// Color scheme for each home item type
struct HomeItemColorScheme {
    let primaryColor: Color
    let secondaryColor: Color
    let textColor: Color
}

enum HomeItemType: CaseIterable {
    case mood, coping
    
    var displayName: String {
        switch self {
        case .mood: return "Mood Check-in"
        case .coping: return "Activity"
//        case .notify: return "Notify \n Ally"
        }
    }
    
    var imageName: String {
        switch self {
        case .mood: return "face.smiling"
        case .coping: return "leaf"
//        case .notify: return "person.2.fill"
        }
    }
    
    var colorScheme: HomeItemColorScheme {
        switch self {
        case .mood:
            return HomeItemColorScheme(
                primaryColor: Color.blue,
                secondaryColor: Color(hex: "4A90E2"),
                textColor: Color.blue
            )
        case .coping:
            return HomeItemColorScheme(
                primaryColor: Color.green,
                secondaryColor: Color(hex: "5CD97D"),
                textColor: Color.green
            )
//        case .notify:
//            return HomeItemColorScheme(
//                primaryColor: Color.purple,
//                secondaryColor: Color(hex: "9B59B6"),
//                textColor: Color.purple
//            )
        }
    }
    
    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .mood: MoodSurvey().environmentObject(MoodViewModel())
        case .coping: CopingActivityView().environmentObject(CopingActivityViewModel())
//        case .notify: AllySelectionView().environmentObject(CommunityViewModel())
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(HomeItemType.allCases, id: \.self) { item in
            HomeItem(item: item)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
