//
//  CopingActivityViewModel.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import Foundation
import SwiftUI
import HealthKit
import CoreLocation
import Firebase

class ActivityViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    
    // Use the shared HealthKitManager instance???
    private let healthKitManager = HealthKitManager.shared

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Location
    func startTrackingLocation() {
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }

    func fetchAddress(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                var addressComponents: [String] = []
                if let subThoroughfare = placemark.subThoroughfare { addressComponents.append(subThoroughfare) }
                if let thoroughfare = placemark.thoroughfare { addressComponents.append(thoroughfare) }
                if let locality = placemark.locality { addressComponents.append(locality) }
                if let administrativeArea = placemark.administrativeArea { addressComponents.append(administrativeArea) }
                if let postalCode = placemark.postalCode { addressComponents.append(postalCode) }
                if let country = placemark.country { addressComponents.append(country) }
                return addressComponents.joined(separator: ", ")
            }
        } catch {
            print("DEBUG: Reverse geocode failed with error: \(error.localizedDescription)")
        }
        return nil
    }

    // MARK: - Fetch Latest HealthKit Data

    /// Fetches the most recent heart rate sample, returning the raw Date range and value.
    func fetchLatestHeartRate() async -> (startDate: Date, endDate: Date, value: Double)? {
        let sampleType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: now, options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                guard
                    error == nil,
                    let sample = samples?.first as? HKQuantitySample
                else {
                    print("DEBUG: No heart rate data or failed query.")
                    continuation.resume(returning: nil)
                    return
                }

                let heartRateValue = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: (sample.startDate, sample.endDate, heartRateValue))
            }
            healthKitManager.healthStore.execute(query)
        }
    }

    /// Fetches the most recent noise level sample, returning the raw Date range and value.
    func fetchLatestNoiseLevel() async -> (startDate: Date, endDate: Date, decibels: Double)? {
        let sampleType = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)!
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: now, options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                guard
                    error == nil,
                    let sample = samples?.first as? HKQuantitySample
                else {
                    print("DEBUG: No noise level data or failed query.")
                    continuation.resume(returning: nil)
                    return
                }

                let decibelValue = sample.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel())
                continuation.resume(returning: (sample.startDate, sample.endDate, decibelValue))
            }
            healthKitManager.healthStore.execute(query)
        }
    }

    // MARK: - Convert Dates to Firestore Timestamps
    private func localTimestamp(for date: Date) -> Timestamp {
        // 1. Create an ISO8601DateFormatter that uses the current device time zone
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone.current
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // 2. Convert the raw Date to a local-time string
        let localString = isoFormatter.string(from: date)

        // 3. Convert that string back to a Date
        //    (This ensures the Date has the local offset baked in.)
        guard let localDate = isoFormatter.date(from: localString) else {
            // Fallback: if parsing fails, just return the raw date
            return Timestamp(date: date)
        }
        return Timestamp(date: localDate)
    }

    // MARK: - Fetch & Return a Dictionary of Health Data
    /// Fetches the latest heart rate/noise and returns a dictionary with raw Date values.
    /// We'll handle converting them to Timestamps in `addCopingActivity`.
    func fetchHealthData() async -> [String: Any] {
        var healthData: [String: Any] = [:]

        // ---- Heart Rate ----
        if let heartRateData = await fetchLatestHeartRate() {
            healthData["heartRateValue"] = heartRateData.value
            healthData["heartRateStart"] = heartRateData.startDate
            healthData["heartRateEnd"]   = heartRateData.endDate
        }

        // ---- Noise Level ----
        if let noiseData = await fetchLatestNoiseLevel() {
            healthData["noiseLevelValue"] = noiseData.decibels
            healthData["noiseLevelStart"] = noiseData.startDate
            healthData["noiseLevelEnd"]   = noiseData.endDate
        }

        print("DEBUG: Fetched Health Data -> \(healthData)")
        return healthData
    }

    // MARK: - Navigation
    @Published var customActivityToNavigateTo: String?
    
    func navigateToCustomActivity(activity: String) {
        customActivityToNavigateTo = activity
    }

    // MARK: - Firebase Reference
    private var copingActivityReference: CollectionReference? {
        guard let userID = UserDefaultsManager.shared.getUserID() else { return nil }
        return Firestore.firestore().collection("users").document(userID).collection("CopingActivities")
    }

    // MARK: - Save Coping Activity
    /// Fetches latest HealthKit data and writes it as Timestamps in local time.
    /// Converts `UUID` -> `String` to avoid the Firestore "Unsupported type" error.
    func addCopingActivity(activity: CopingActivity) {
        guard let activityRef = copingActivityReference else {
            print("DEBUG: User not authenticated.")
            return
        }

        Task {
            // 1. Fetch raw HealthKit data (heart rate/noise, with Dates)
            let healthDataDict = await fetchHealthData()

            // 2. Convert them to Firestore Timestamps, preserving local time
            var finalHealthData = [String: Any]()

            if let hrValue = healthDataDict["heartRateValue"] as? Double {
                finalHealthData["heartRateValue"] = hrValue
            }
            if let hrStart = healthDataDict["heartRateStart"] as? Date {
                finalHealthData["heartRateStart"] = localTimestamp(for: hrStart)
            }
            if let hrEnd = healthDataDict["heartRateEnd"] as? Date {
                finalHealthData["heartRateEnd"] = localTimestamp(for: hrEnd)
            }

            if let noiseValue = healthDataDict["noiseLevelValue"] as? Double {
                finalHealthData["noiseLevelValue"] = noiseValue
            }
            if let noiseStart = healthDataDict["noiseLevelStart"] as? Date {
                finalHealthData["noiseLevelStart"] = localTimestamp(for: noiseStart)
            }
            if let noiseEnd = healthDataDict["noiseLevelEnd"] as? Date {
                finalHealthData["noiseLevelEnd"] = localTimestamp(for: noiseEnd)
            }

            // 3. Build location data
            var finalLocationData = [String: Any]()
            if let currentLoc = currentLocation {
                finalLocationData["latitude"] = currentLoc.latitude
                finalLocationData["longitude"] = currentLoc.longitude

                if let address = await fetchAddress(for: currentLoc) {
                    finalLocationData["address"] = address
                }
            }

            // 4. Convert any UUID to string to avoid Firestore errors.
            let copingActivityIDString: String
            if let uuid = activity.copingActivityID as? UUID {
                copingActivityIDString = uuid.uuidString
            } else if let str = activity.copingActivityID as? String {
                copingActivityIDString = str
            } else {
                copingActivityIDString = String(describing: activity.copingActivityID)
            }

            // 5. Build the top-level dictionary
            var docData: [String: Any] = [
                "activityName": activity.activityName,
                "copingActivityID": copingActivityIDString,
                "timestamp": localTimestamp(for: Date()),
                "healthData": finalHealthData,
                "locationData": finalLocationData
            ]

            // Add musicService if provided
            if let musicService = activity.musicService {
                docData["musicService"] = musicService
            }

            // 6. Write the document to Firestore
            do {
                _ = try await activityRef.addDocument(data: docData)
                print("DEBUG: Coping activity successfully added.")
                
                // 7. Schedule follow-up notification for mood check-in after activity
//                scheduleMoodCheckInAfterActivity(activityName: activity.activityName)
                
            } catch {
                print("DEBUG: Error adding coping activity: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Schedule Mood Check-In Notification
    /// Schedule a follow-up notification 15 minutes after completing a coping activity
//    private func scheduleMoodCheckInAfterActivity(activityName: String) {
//        if let appDelegate = AppDelegate.appInstance?.delegate {
//            appDelegate.scheduleCopingActivityFollowUp(activityName: activityName)
//        }
//    }
}

extension ActivityViewModel {
    func logMusicSelection(service: String) async {
        guard let userID = UserDefaultsManager.shared.getUserID() else { return }
        
        let docData: [String: Any] = [
            "musicServiceSelected": service,
            "timestamp": Date()
        ]
        
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(userID)
                .collection("CopingActivities")
                .addDocument(data: docData)
            print("DEBUG: Logged music selection: \(service)")
        } catch {
            print("DEBUG: Failed to log music selection: \(error.localizedDescription)")
        }
    }
}
