//
//  User.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//

import Firebase
import FirebaseFirestore
import Foundation

struct User: Identifiable, Codable {
    var id: String { userID }
    let userID: String
    let fullname: String
    let email: String
    
    let dateCreated: Timestamp?
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullname) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
    
    init(userID: String, fullname: String, email: String, dateCreated: Timestamp) {
        self.userID = userID
        self.fullname = fullname
        self.email = email
        self.dateCreated  = dateCreated
    }
    
    init(from data: [String: Any]) throws {
        guard
            let userID = data["userID"] as? String,
            let fullname = data["fullname"] as? String,
            let email = data["email"] as? String,
            let dateCreated = data["dateCreated"] as? Timestamp
        else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"])
        }
        self.userID = userID
        self.fullname = fullname
        self.email = email
        self.dateCreated = dateCreated
    }
}
