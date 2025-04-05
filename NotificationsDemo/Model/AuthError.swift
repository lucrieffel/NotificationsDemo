//
//  AuthError.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//


import Foundation
import Firebase
import FirebaseAuth

//enum AuthError: Error {
//    case invalidEmail
//    case wrongPassword
//    case userNotFound
//    case weakPassword
//    case emailAlreadyInUse
//    case internalError
//    case malformedCredential
//    case childUserLogin
//    case unknown
//    
//    init(authErrorCode: AuthErrorCode.Code) {
//        switch authErrorCode {
//        case .invalidEmail:
//            self = .invalidEmail
//        case .wrongPassword:
//            self = .wrongPassword
//        case .userNotFound:
//            self = .userNotFound
//        case .weakPassword:
//            self = .weakPassword
//        case .emailAlreadyInUse:
//            self = .emailAlreadyInUse
//        case .credentialAlreadyInUse:
//            self = .malformedCredential
//        default:
//            self = .unknown
//        }
//    }
//    
//    var description: String {
//        switch self {
//        case .invalidEmail:
//            return "The email you entered is invalid. Please try again."
//        case .wrongPassword:
//            return "Incorrect password. Please try again."
//        case .userNotFound:
//            return "No account found with this email. Would you like to create a new account?"
//        case .weakPassword:
//            return "Your password must be at least 6 characters in length. Please try again."
//        case .emailAlreadyInUse:
//            return "The email address is already in use. Please use a different email."
//        case .internalError:
//            return "An internal error occurred. Please try again."
//        case .malformedCredential:
//            return "The supplied auth credential is malformed or has expired. Please check your credentials and try again."
//        case .childUserLogin:
//            return "You may not log in as a child user. Please log in as the parent user instead."
//        case .unknown:
//            return "This account does not exist. Please create a new account and try again."
//        }
//    }
//}
