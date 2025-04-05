//
//  AddTaskLoadingView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI

struct AddTaskLoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                .scaleEffect(2)
                .bold()
            Text("Loading...")
                .font(.headline)
                .padding(.top, 8)
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}


#Preview {
    AddTaskLoadingView()
}
