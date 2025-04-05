//
//  MoodViewModel.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import HealthKit
import CoreLocation

class MoodViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
//    @EnvironmentObject private var communityViewModel: CommunityViewModel
    @Published var moods = [Mood]()
    @Published var dailyMoodCounts: [DailyMoodCount] = []
    @Published var latestMood: Mood?
    @Published var currentLocation: CLLocationCoordinate2D?
    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()
    private let healthKitManager = HealthKitManager.shared
    
    private var moodReference: CollectionReference? {
        guard let userID = Auth.auth().currentUser?.uid else { return nil }
        return Firestore.firestore().collection("users").document(userID).collection("Moods")
    }
    
    override init() {
        super.init()
        setupLocationManager()
        startTrackingLocation()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Add Mood
    func addMood(mood: Mood) {
        guard let moodRef = moodReference else {
            print("DEBUG: User not authenticated.")
            return
        }
        
        Task {
            var moodWithData = mood
            
            // Fetch health data if available
            let healthData = await fetchHealthData()
            moodWithData.healthData = healthData
            
            // Fetch location data if available
            if let locationData = await fetchLocationData() {
                moodWithData.locationData = locationData
            }
            
            do {
                _ = try moodRef.addDocument(from: moodWithData)
                print("DEBUG: Mood successfully added with health and location data.")
                
                // Post notification that mood was saved
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("MoodSaved"), object: nil)
                    print("DEBUG: Posted MoodSaved notification")
                }
            } catch {
                print("DEBUG: Failed to add mood: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Health Data Functions
    
    /// Fetches the most recent heart rate sample
    private func fetchLatestHeartRate() async -> (startDate: Date, endDate: Date, value: Double)? {
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

    /// Fetches the most recent noise level sample
    private func fetchLatestNoiseLevel() async -> (startDate: Date, endDate: Date, decibels: Double)? {
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
    
    /// Fetches all available health data and returns a HealthData object
    private func fetchHealthData() async -> HealthData {
        var healthData = HealthData()
        
        // Fetch heart rate data
        if let heartRateData = await fetchLatestHeartRate() {
            healthData.heartRateValue = heartRateData.value
            healthData.heartRateStart = heartRateData.startDate
            healthData.heartRateEnd = heartRateData.endDate
        }
        
        // Fetch noise level data
        if let noiseData = await fetchLatestNoiseLevel() {
            healthData.noiseLevelValue = noiseData.decibels
            healthData.noiseLevelStart = noiseData.startDate
            healthData.noiseLevelEnd = noiseData.endDate
        }
        
        return healthData
    }
    
    // MARK: - Location Functions
    
    func startTrackingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    private func fetchLocationData() async -> LocationData? {
        guard let location = currentLocation else { return nil }
        
        var locationData = LocationData()
        locationData.latitude = location.latitude
        locationData.longitude = location.longitude
        
        // Get address if available
        locationData.address = await fetchAddress(for: location)
        
        return locationData
    }
    
    private func fetchAddress(for coordinate: CLLocationCoordinate2D) async -> String? {
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
    
    // MARK: - Fetch Latest Mood
    func fetchLatestMood() {
        guard let moodReference else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date()) // Get today's start time
        let startOfDayTimestamp = Timestamp(date: startOfDay) // Convert to Firestore Timestamp
        
        moodReference
            .whereField("date", isGreaterThanOrEqualTo: startOfDayTimestamp) // Fetch only today's moods
            .order(by: "date", descending: true) // Get the latest one
            .limit(to: 1)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("DEBUG: Error fetching latest mood: \(error.localizedDescription)")
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    print("DEBUG: No mood found for today.")
                    self.latestMood = Mood(mood: .empty, intensity: 0, journalText: nil, date: Date()) // Return empty mood
                    return
                }
                
                self.latestMood = try? document.data(as: Mood.self)
                if let mood = self.latestMood {
                    print("DEBUG: Latest mood fetched: \(mood.mood?.name ?? "Unknown")")
                    
                    // Start tracking location for the next mood entry
                    self.startTrackingLocation()
                }
            }
    }
    
    // MARK: - Fetch All Moods
    func fetchMoods() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("DEBUG: No user logged in. Cannot fetch moods.")
            return
        }
        
        db.collection("users")
            .document(userID)
            .collection("Moods")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("DEBUG: Error fetching moods: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No mood documents found.")
                    return
                }
                
                // Decode Firestore docs into `[Mood]`.
                let fetchedMoods = documents.compactMap { doc -> Mood? in
                    do {
                        var mood = try doc.data(as: Mood.self)
                        // Ensure healthData and locationData are properly loaded from the document
                        // This handling is useful for backward compatibility with existing data
                        return mood
                    } catch {
                        print("DEBUG: Error decoding mood: \(error.localizedDescription)")
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    self.moods = fetchedMoods
                    // Example: automatically process last 30 days
                    self.processMoodCounts(forLast: 30)
                    
                    // Start tracking location for the next mood entry
                    self.startTrackingLocation()
                }
            }
    }
    
    // MARK: - Group and Process for Charting
    
    /// Group & count moods for the past `days` days.
    func processMoodCounts(forLast days: Int) {
        let recentMoods = moodsFilteredByDays(moods, days: days)
        calculateDailyMoodCounts(for: recentMoods)
    }
    
    /// Group & count moods in a custom date range.
    func processMoodCounts(forStartDate startDate: Date, endDate: Date) {
        let rangeMoods = moodsFilteredByDateRange(moods, startDate: startDate, endDate: endDate)
        calculateDailyMoodCounts(for: rangeMoods)
    }
    
    /// Actually calculates `[DailyMoodCount]` by day+color (just like your old logic).
    private func calculateDailyMoodCounts(for filteredMoods: [Mood]) {
        var dailyCounts: [DailyMoodCount] = []
        
        // Group by day
        let groupedByDay = Dictionary(grouping: filteredMoods) {
            Calendar.current.startOfDay(for: $0.date)
        }
        
        // Then group within each day by mood color
        for (day, moodsOnDate) in groupedByDay {
            let moodTypeCounts = Dictionary(grouping: moodsOnDate) { $0.mood?.colorName ?? "unknown" }
            
            for (moodColor, moods) in moodTypeCounts {
                dailyCounts.append(DailyMoodCount(
                    date: day,
                    count: moods.count,
                    moodColor: moodColor
                ))
            }
        }
        
        // Sort by ascending date
        dailyCounts.sort { $0.date < $1.date }
        self.dailyMoodCounts = dailyCounts
    }
    
    // MARK: - Helper Filters
    
    /// Return only moods within last `days` from *today* (inclusive).
    private func moodsFilteredByDays(_ moods: [Mood], days: Int) -> [Mood] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        return moods.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    /// Return only moods in a custom date range.
    private func moodsFilteredByDateRange(_ moods: [Mood], startDate: Date, endDate: Date) -> [Mood] {
        moods.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    
    //fetch moods for a given date(to populate calendar view)
    func fetchMoods(for date: Date) async -> [Mood] {
        guard let userID = Auth.auth().currentUser?.uid else { return [] }
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        let startTimestamp = Timestamp(date: startDate)
        let endTimestamp = Timestamp(date: endDate)
        
        return await withCheckedContinuation { continuation in
            db.collection("users")
                .document(userID)
                .collection("Moods")
                .whereField("date", isGreaterThanOrEqualTo: startTimestamp)
                .whereField("date", isLessThan: endTimestamp)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("DEBUG: Error fetching moods for day: \(error.localizedDescription)")
                        continuation.resume(returning: [])
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        continuation.resume(returning: [])
                        return
                    }
                    let fetchedMoods = documents.compactMap { doc -> Mood? in
                        do {
                            let mood = try doc.data(as: Mood.self)
                            return mood
                        } catch {
                            print("DEBUG: Error decoding mood: \(error.localizedDescription)")
                            return nil
                        }
                    }
                    continuation.resume(returning: fetchedMoods)
                }
        }
    }
    
    // MARK: - Location Manager Delegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("DEBUG: Location manager failed with error: \(error.localizedDescription)")
    }
}
