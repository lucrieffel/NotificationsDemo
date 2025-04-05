//
//  ReportUtilities.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import Foundation
import SwiftUI
import UIKit

struct ReportUtilities {
    // MARK: - Capture Content as UIImage
    @MainActor
    static func captureContent<Content: View>(_ content: Content, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        return renderer.uiImage
    }
    
    
    // MARK: - Save Image to Temporary File
    static func saveImageToTemporaryFile(image: UIImage, fileName: String, completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = image.jpegData(compressionQuality: 0.9) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try data.write(to: fileURL)
                DispatchQueue.main.async {
                    completion(fileURL)
                }
            } catch {
                print("Error saving image: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Present Share Sheet
    static func presentShareSheet(for fileURL: URL, completion: (() -> Void)? = nil) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            // Clean up temporary file after sharing
            try? FileManager.default.removeItem(at: fileURL)
            completion?()
        }
        
        rootViewController.present(activityViewController, animated: true)
    }
}

// MARK: - Identifiable Wrapper for UIImage
struct SharedImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

