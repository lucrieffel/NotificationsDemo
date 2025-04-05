//
//  ColorType.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import Foundation
import SwiftUI


enum ColorType {
    case dodgerBlue
    case darkBlue
    case blue1
    case blue2
    case mood
    
    var color: Color {
        switch self {
        case .dodgerBlue:
            return Color(hex: "#18A0FB")
        case .darkBlue:
            return Color(hex: "#18A0FB")
        case .blue1:
            return Color(hex: "#0096C9")
        case .blue2:
            return Color(hex: "#00C6FC")
        case .mood:
            return Color(hex: "#00C6FC")
            
        }
    }
}

// MARK: - Color Types
enum ColorType2 {
    case darkBlue
    case blue1
    case blue2
    
    var color: Color {
        switch self {
        case .darkBlue:
            return Color(red: 0.1, green: 0.2, blue: 0.45)
        case .blue1:
            return Color(red: 0.0, green: 0.48, blue: 0.8)
        case .blue2:
            return Color(red: 0.0, green: 0.6, blue: 0.9)
        }
    }
}

extension Color {
    init(hex: String) {
        var cleanHexCode = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHexCode = cleanHexCode.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        
        Scanner(string: cleanHexCode).scanHexInt64(&rgb)
        
        let redValue = Double((rgb >> 16) & 0xFF) / 255.0
        let greenValue = Double((rgb >> 8) & 0xFF) / 255.0
        let blueValue = Double(rgb & 0xFF) / 255.0
        self.init(red: redValue, green: greenValue, blue: blueValue)
    }
}
