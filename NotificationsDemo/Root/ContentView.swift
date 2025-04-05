//
//  ContentView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//

import SwiftUI
import HealthKit
import HealthKitUI

struct ContentView: View {
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @EnvironmentObject private var authViewModel: AuthViewModel
//    @EnvironmentObject private var communityViewModel: CommunityViewModel
    @State private var trigger = false
    @State private var authenticated = false
    
    @State private var dateSelected: DateComponents? = nil
    @State private var displayEvents = false
    let calendarInterval = DateInterval(start: Date().addingTimeInterval(-7 * 60 * 24), end: Date().addingTimeInterval(7 * 60 * 24))
    
    var body: some View {
        NavigationStack {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Dashboard", systemImage: "list.bullet")
                    }

                
                CalendarView(
                    interval: calendarInterval,
                    dateSelected: $dateSelected,
                    displayEvents: $displayEvents
                )
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                
//                EmptyView()
//                    .tabItem{
//                        Label("Blank tab", systemImage: "paper")
//                    }
 
                //MARK: this view shows the authenticated user, login info, change password form, and sign out
                Profile()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
            }
            .toolbarBackground(.visible, for: .tabBar)
            .onAppear {
                if HKHealthStore.isHealthDataAvailable() &&
                   healthKitManager.healthAuthorizationStatus != .sharingAuthorized &&
                   !authenticated && !trigger {
                    trigger.toggle()
                } else if healthKitManager.healthAuthorizationStatus == .sharingAuthorized {
                    authenticated = true
                    Task {
                        await healthKitManager.fetchHealthKitData()
                    }
                }
            }
            .healthDataAccessRequest(
                store: healthKitManager.healthStore,
                shareTypes: [],
                readTypes: healthKitManager.allTypesToRead,
                trigger: trigger
            ) { result in
                switch result {
                case .success:
                    authenticated = true
                    DispatchQueue.main.async {
                        healthKitManager.isAuthorized = true
                        healthKitManager.healthAuthorizationStatus = .sharingAuthorized
                    }
                case .failure(let error):
                    fatalError("*** An error occurred: \(error.localizedDescription) ***")
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .environmentObject(AuthViewModel())
            .environmentObject(HealthKitManager())
    }
}
