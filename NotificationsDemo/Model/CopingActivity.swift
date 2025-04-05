//
//  CopingActivity.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import Foundation


struct CopingActivity: Identifiable, Codable, Hashable {
    var copingActivityID: UUID
    var activityName: String
    var timestamp: Date
    var healthData: [String]?
    var locationData: [String]?
    var musicService: String?

    var id: UUID { copingActivityID }
    
    init(
        copingActivityID: UUID = UUID(),
        activityName: String,
        timestamp: Date = Date(),
        healthData: [String]? = nil,
        locationData: [String]? = nil,
        musicService: String? = nil
    ) {
        self.copingActivityID = copingActivityID
        self.activityName = activityName
        self.timestamp = timestamp
        self.healthData = healthData
        self.locationData = locationData
        self.musicService = musicService
    }
}


struct HealthData: Codable {
    var heartRateValue: Double?
    var heartRateStart: Date?
    var heartRateEnd: Date?
    var noiseLevelValue: Double?
    var noiseLevelStart: Date?
    var noiseLevelEnd: Date?
}

struct LocationData: Codable {
    var latitude: Double?
    var longitude: Double?
    var address: String?
}
