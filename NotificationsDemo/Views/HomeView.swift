//
//  HomeView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: MoodViewModel
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var isLoading = true
    
    private let gridItems = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            ColorType.darkBlue.color.opacity(0.05)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(
                            "Hi \(authVM.currentUser?.fullname.split(separator: " ").first ?? "Buddy"),"
                        )
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        
                        Text("What do you want to do?")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    //MARK: Home action buttons(mood, coping activity, notify ally)
                    homeActionButtons
                    
                }
                .padding(.vertical)
            }
        }
        .navigationDestination(for: String.self) { activity in
            ActivityDetailView(activity: activity)
        }
        .onAppear {
            Task {
                // Load HealthKit data - use the proper date-specific methods like GraphsView does
                let today = Date()
                let hrData = await healthKitManager.fetchHeartRateData(for: today)
                let noiseData = await healthKitManager.fetchNoiseLevelData(for: today)
                
                // Update the HealthKit manager data on the main thread
                await MainActor.run {
                    healthKitManager.heartRateData = hrData
                    healthKitManager.noiseLevelData = noiseData
                    
                    // Calculate averages
                    healthKitManager.averageHeartRate = hrData.map(\.value).average
                    healthKitManager.averageNoiseLevel = noiseData.map(\.value).average
                }
                
                // Fetch mood data
                viewModel.fetchLatestMood() // only fetch the latest mood from today otherwise empty mood
                
                // Show content after loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Components
    
    // Home action buttons in a responsive grid
    private var homeActionButtons: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
//            let itemWidth = (width - 32 - 32) / 3 // Account for padding and spacing
            
            LazyVGrid(columns: gridItems, spacing: 16) {
                ForEach(HomeItemType.allCases, id: \.self) { item in
                    NavigationLink(destination: item.destinationView) {
                        HomeItem(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 120) // Fixed height for the grid section
    }
    
    private var loadingView: some View {
        VStack {
            HStack(spacing: 24) {
                ForEach(0..<3) { _ in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 20)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 20)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 10)
                    }
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var activityReviewContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Noise Level
                metricCard(
                    title: "Noise Level",
                    value: "\(healthKitManager.averageNoiseLevel?.formatted(.number.precision(.fractionLength(1))) ?? "N/A")",
                    unit: "Decibels",
                    color: .orange
                )
                
                // Heart Rate
                metricCard(
                    title: "Heart Rate",
                    value: "\(healthKitManager.averageHeartRate?.formatted(.number.precision(.fractionLength(0))) ?? "N/A")",
                    unit: "BPM",
                    color: .red
                )
                
                // Mood
                let latestMood = viewModel.latestMood?.mood ?? .empty
                metricCard(
                    title: "Mood",
                    value: latestMood.imgURL.isEmpty ? "N/A" : latestMood.imgURL,
                    unit: latestMood.name.isEmpty ? "N/A" : latestMood.name,
                    color: .blue
                )
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(.systemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            
            // text
            Text("""
            The activity review is an average of the noise around you, your heart rate, and your mood for today. Intensity indicates how strong your mood is. Tap the area to see a more detailed view.
            """)
            .font(.footnote)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
        }
    }
    
    // Helper function to create consistent metric cards
    private func metricCard(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(unit)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// Add this extension for loading/ effect
extension View {
    func shimmering() -> some View {
        self.overlay(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.secondary.opacity(0.2),
                    Color.secondary.opacity(0.5),
                    Color.secondary.opacity(0.2)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .animation(
                Animation.linear(duration: 2.0)
                    .repeatForever(autoreverses: true)
            )
        )
    }
}

// Extension to calculate average
extension Collection where Element: BinaryFloatingPoint {
    var average: Element? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Element(count)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
        .environmentObject(MoodViewModel())
        .environmentObject(HealthKitManager())
}

