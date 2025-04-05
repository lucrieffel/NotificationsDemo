//
//  HealthkitManager.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import Foundation
import HealthKit
import Firebase

class HealthKitManager: ObservableObject {
    var healthStore = HKHealthStore() // HealthKit store object
    
    // Published Variables for ActivityReviewView
    @Published var averageNoiseLevel: Double? = nil
    @Published var averageHeartRate: Double? = nil
    @Published var noiseLevelData: [HealthDataPoint] = []
    @Published var heartRateData: [HealthDataPoint] = []
    @Published var isAuthorized = false
    
    // HealthKit Data Types to Read
    let allTypesToRead: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature)!,
        HKCategoryType.categoryType(forIdentifier: .mindfulSession)!,
        HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKQuantityType.quantityType(forIdentifier: .appleMoveTime)!,
        HKCategoryType.categoryType(forIdentifier: .appleStandHour)!,
        HKQuantityType.quantityType(forIdentifier: .appleStandTime)!,
        HKQuantityType.quantityType(forIdentifier: .vo2Max)!,
        
        HKQuantityType.quantityType(forIdentifier: .timeInDaylight)!,
        HKCategoryType.categoryType(forIdentifier: .lowCardioFitnessEvent)!,
        HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)!,
        HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure)!,
        HKCategoryType.categoryType(forIdentifier: .environmentalAudioExposureEvent)!,
        HKCategoryType.categoryType(forIdentifier: .toothbrushingEvent)!,
        HKCategoryType.categoryType(forIdentifier: .handwashingEvent)!,
        HKCategoryType.categoryType(forIdentifier: .lowHeartRateEvent)!,
        HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
        HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKCategoryType.categoryType(forIdentifier: .lowHeartRateEvent)!,
        HKCategoryType.categoryType(forIdentifier: .highHeartRateEvent)!,
        HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!,
        HKQuantityType.quantityType(forIdentifier: .uvExposure)!,
        HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
        HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage)!,
        HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature)!,
    ]
    
    // Shared HealthKit manager to handle HealthKit authorization changes
    static let shared: HealthKitManager = {
        // Use a separate private initializer to prevent recursion
        let instance = HealthKitManager(isSharedInstance: true)
        return instance
    }()
    
    @Published var healthAuthorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // Private flag to break the initialization cycle
    private var isInitializing = false
    
    // Secondary initializer for shared instance
    private init(isSharedInstance: Bool) {
        // Minimal initialization for shared instance
        let status = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRate)!)
        self.healthAuthorizationStatus = status
        self.isAuthorized = (status == .sharingAuthorized)
    }
    
    // Main initializer
    init() {
        // Check authorization status first rather than immediately requesting
        let status = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRate)!)
        healthAuthorizationStatus = status
        
        // Skip shared instance sync to prevent recursion
        if self !== HealthKitManager.shared {
            // Only fetch data if we already have authorization
            if status == .sharingAuthorized {
                isAuthorized = true
                Task {
                    await fetchHealthKitData()
                }
            } else if status == .notDetermined {
                Task {
                    await requestAuthorizationAndFetchData()
                }
            }
        }
    }
    
//    @MainActor
    private func requestAuthorizationAndFetchData() async {
        print("DEBUG: Requesting HealthKit authorization...")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("ERROR: Health data is not available on this device.")
            return
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: allTypesToRead)
            isAuthorized = true
            healthAuthorizationStatus = .sharingAuthorized
            print("DEBUG: HealthKit authorization successful.")
            await fetchHealthKitData()
        } catch {
            print("ERROR: HealthKit Authorization Failed - \(error.localizedDescription)")
        }
    }
    
    // ✅ Fetch Noise Level & Heart Rate for Averages & Time-Series Data
    func fetchHealthKitData() async {
        // Double-check authorization status here instead of just relying on isAuthorized flag
        let status = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRate)!)
        
        if status != .sharingAuthorized {
            // Only print this message if the status is truly denied, not just when data isn't available
            if status == .sharingDenied {
                print("Not authorized for HealthKit data.")
            }
            return
        }
        
        // Ensure isAuthorized is set to true if we got here
        if !isAuthorized {
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
        }
        
        async let noiseAvg = fetchAverageNoiseLevel()
        async let heartAvg = fetchAverageHeartRate()
        async let noiseDetail = fetchNoiseLevelData()
        async let heartDetail = fetchHeartRateData()
        
        let noise = await noiseAvg
        let heart = await heartAvg
        let noisePoints = await noiseDetail
        let heartPoints = await heartDetail
        
        DispatchQueue.main.async {
            self.averageNoiseLevel = noise
            self.averageHeartRate = heart
            self.noiseLevelData = noisePoints
            self.heartRateData = heartPoints
        }
    }
    
    // ✅ Fetch **Average Noise Level** using the default decibel unit (no conversion)
    private func fetchAverageNoiseLevel() async -> Double? {
        let sampleType = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)!
        let startDate = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        return await fetchAverage(for: sampleType, unit: HKUnit.decibelAWeightedSoundPressureLevel(), predicate: predicate)
    }
    
    // ✅ Fetch **Average Heart Rate** (BPM)
    private func fetchAverageHeartRate() async -> Double? {
        let sampleType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let startDate = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        return await fetchAverage(for: sampleType, unit: HKUnit.count().unitDivided(by: HKUnit.minute()), predicate: predicate)
    }
    
    // ✅ Fetch **Time-Series Noise Level Data** using the default decibel unit
    private func fetchNoiseLevelData() async -> [HealthDataPoint] {
        let sampleType = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)!
        let startDate = Calendar.current.startOfDay(for: Date())
        
        return await fetchTimeSeries(for: sampleType, unit: HKUnit.decibelAWeightedSoundPressureLevel(), startDate: startDate)
    }
    
    // ✅ Fetch **Time-Series Heart Rate Data**
    private func fetchHeartRateData() async -> [HealthDataPoint] {
        let sampleType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let startDate = Calendar.current.startOfDay(for: Date())
        
        return await fetchTimeSeries(for: sampleType, unit: HKUnit.count().unitDivided(by: HKUnit.minute()), startDate: startDate)
    }
    
    // ✅ Generic function to fetch **average** values from HealthKit
    private func fetchAverage(for sampleType: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: sampleType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                guard let quantity = result?.averageQuantity() else {
                    print("DEBUG: No data found for \(sampleType.identifier)")
                    continuation.resume(returning: nil)
                    return
                }
                let value = quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
    
    // ✅ Generic function to fetch **time-series** HealthKit data
    private func fetchTimeSeries(for sampleType: HKQuantityType, unit: HKUnit, startDate: Date) async -> [HealthDataPoint] {
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            
            let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                
                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    print("DEBUG: No time-series data found for \(sampleType.identifier)")
                    continuation.resume(returning: [])
                    return
                }
                
                let dataPoints = quantitySamples.map { sample in
                    HealthDataPoint(time: sample.startDate, value: sample.quantity.doubleValue(for: unit))
                }
                
                continuation.resume(returning: dataPoints)
            }
            
            healthStore.execute(query)
        }
    }
    
    //fetch heart rate and noise data for a given date (calendar view)
    func fetchHeartRateData(for date: Date) async -> [HealthDataPoint] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let sampleType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let query = HKSampleQuery(sampleType: sampleType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                let dataPoints = quantitySamples.map { sample in
                    HealthDataPoint(time: sample.startDate,
                                    value: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                }
                continuation.resume(returning: dataPoints)
            }
            healthStore.execute(query)
        }
    }

    func fetchNoiseLevelData(for date: Date) async -> [HealthDataPoint] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let sampleType = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)!
            let query = HKSampleQuery(sampleType: sampleType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                let dataPoints = quantitySamples.map { sample in
                    HealthDataPoint(time: sample.startDate,
                                    value: sample.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel()))
                }
                continuation.resume(returning: dataPoints)
            }
            healthStore.execute(query)
        }
    }
    
    // Method to check and request HealthKit authorization
    func checkAndRequestHealthKitAuthorizationIfNeeded() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("ERROR: Health data is not available on this device.")
            return
        }
        
        let status = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRate)!)
        healthAuthorizationStatus = status
        
        switch status {
        case .notDetermined:
            // Only request if we haven't already started the authorization process
            if healthAuthorizationStatus == .notDetermined {
                Task {
                    await requestAuthorizationAndFetchData()
                }
            }
        case .sharingDenied:
            print("HealthKit access is restricted. Please enable HealthKit access in Settings.")
        case .sharingAuthorized:
            isAuthorized = true
            if !isAuthorized {
                Task {
                    await fetchHealthKitData()
                }
            }
        @unknown default:
            break
        }
    }
}

struct HealthDataPoint: Identifiable {
    let id = UUID()
    let time: Date
//    let Timestamp: Timestamp?
    let value: Double
}
