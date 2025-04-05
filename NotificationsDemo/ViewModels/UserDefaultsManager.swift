//
//  UserDefaultsManager.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let userDefaults = UserDefaults.standard
    private let userIDKey = "userID"
    private let userEmailKey = "userEmail"
    private let userNameKey = "userName"

    
    private init() {}
    
    func saveUserID(_ userID: String) {
        userDefaults.set(userID, forKey: userIDKey)
    }

    func getUserID() -> String? {
        return userDefaults.string(forKey: userIDKey)
    }
    
    func saveUserName(_ userName: String){
        userDefaults.set(userName, forKey: userNameKey)
    }
    
    func getUserName() -> String? {
        return userDefaults.string(forKey: userNameKey)
    }
    
    func getUserEmail() -> String? {
        return userDefaults.string(forKey: userEmailKey)
    }
    
    func saveUserEmail(_ userEmail: String){
         userDefaults.set(userEmail, forKey: userEmailKey)
    }
    
    func clearUserData() {
        userDefaults.removeObject(forKey: userIDKey)
        userDefaults.removeObject(forKey: userEmailKey)
        userDefaults.removeObject(forKey: userNameKey)
    }
    
    func getUserDefaultsValue(forKey key: String) -> Any? {
        return userDefaults.object(forKey: key)
    }
    func setUserDefaultsValue(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
}
