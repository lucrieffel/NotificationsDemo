//
//  NotificationsDemoApp.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//

import SwiftUI
import Firebase

@main
struct NotificationsDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var healthkitManager = HealthKitManager()
    @StateObject private var activityViewModel = ActivityViewModel()
    @StateObject private var moodViewModel = MoodViewModel()

    
    var body: some Scene {
        WindowGroup {
            ZStack{
                LoadingScreen()
                    .environmentObject(authViewModel)
                    .environmentObject(healthkitManager)
                    .environmentObject(activityViewModel)
                    .environmentObject(moodViewModel)
            }
        }
    }
}



//MARK: Firebase app delegate configuration
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}
