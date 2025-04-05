//
//  Mood.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI

struct Mood: Codable {
    @DocumentID var id: String?
    var mood: MoodType?
    var intensity: Int
    var journalText: String?
    var customMoodText: String?
    let date: Date
    var healthData: HealthData?
    var locationData: LocationData?
}

enum MoodType: String, Codable, CaseIterable {
    case happy, sad, stressed, anxious, angry, neutral, other, empty
   
    var imgURL: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "🙁"
        case .stressed: return "😰"
        case .anxious: return "😩"
        case .angry: return "😡"
        case .neutral: return "😐"
        case .other: return "✨"
        case .empty: return ""
        }
    }
    
    var colorName: String {
        switch self {
        case .happy:
            return "green"
        case .sad:
            return "blue"
        case .stressed, .anxious, .angry:
            return "red"
        case .neutral, .other, .empty:
            return "gray"
        }
    }
    
    var color: Color {
        switch self {
        case .happy:
            return .green
        case .sad:
            return .blue
        case .stressed, .anxious, .angry:
            return .red
        case .neutral, .other, .empty:
            return .gray
        }
    }
    
    var name: String {
        switch self {
        case .happy, .sad, .stressed, .anxious, .angry, .neutral:
            return rawValue.capitalized
        case .other:
            return "Other"
        case .empty:
            return "No Mood"
        }
    }
}

struct DailyMoodCount: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let count: Int
    let moodColor: String
}


struct MoodTimeDistribution: Identifiable, Hashable {
    let id = UUID()
    let timeOfDay: String
    let moodColor: String
    let count: Int
}

struct MoodDetail: View {
    var mood: MoodType
    
    var body: some View {
        Label{
            Text(mood.name)
                .font(.caption)
                .fontWeight(.bold)
        } icon:{
            Text(mood.imgURL)
                .font(.largeTitle)
        }
        .labelStyle(VerticalIconLabelStyle())
    }
}

#Preview {
    MoodDetail(mood: .happy)
}

struct VerticalIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == VerticalIconLabelStyle {
    static var verticalIcon: Self { Self() }
}
