//
//  CustomTextField.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//

import SwiftUI
import Foundation

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var autocapitalization: TextInputAutocapitalization = .never
    var capitalizeWords: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(.placeholderText))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
            }
            if isSecure {
                SecureField("", text: $text)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .textInputAutocapitalization(autocapitalization)
            } else {
                TextField("", text: $text)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .textInputAutocapitalization(autocapitalization)
                    .onChange(of: text) { newValue in
                        // Apply capitalization only when `capitalizeWords` is true
                        if capitalizeWords {
                            text = newValue.capitalizedWords()
                        }
                    }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 0.5))
        .frame(width: UIScreen.main.bounds.width - 32, height: 40)
    }
}

extension String {
    func capitalizedWords() -> String {
        return self.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
    }
}


//#Preview {
//    CustomTextField()
//}
