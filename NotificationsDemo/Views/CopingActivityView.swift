//
//  CopingActivityView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI

struct CopingActivityView: View {
    @EnvironmentObject private var viewModel: CopingActivityViewModel
    @State private var customActivityText: String = ""
    @State private var showCustomActivityError: Bool = false
    @State private var isOtherSelected: Bool = false

    let suggestedActivities = [
        CopingActivity(activityName: "Calm App"),
        CopingActivity(activityName: "Listen to Music"),
        CopingActivity(activityName: "Take a walk"),
        CopingActivity(activityName: "Meditate"),
        CopingActivity(activityName: "Play games"),
        CopingActivity(activityName: "Read")
    ]
    
    var body: some View {
        ZStack {
            ColorType.darkBlue.color.opacity(0.05)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose an activity to help you.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Suggested")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(suggestedActivities, id: \.activityName) { activity in
                            NavigationLink(destination: destinationForActivity(activity)) {
                                HStack {
                                    if activity.activityName == "Calm App" {
                                        Image("calm_app")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    } else {
                                        Image(systemName: iconForActivity(activity.activityName))
                                            .font(.system(size: 22))
                                            .foregroundColor(colorForActivity(activity.activityName))
                                            .frame(width: 30, height: 30)
                                    }
                                    
                                    Text(activity.activityName)
                                        .font(.headline)
                                        .padding(.leading, 8)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: Color.primary.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .simultaneousGesture(TapGesture().onEnded {
                                if activity.activityName != "Listen to Music" {
                                    viewModel.addCopingActivity(activity: activity)
                                }
                            })
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Other section
                    Text("Other")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                    
                    Button {
                        isOtherSelected.toggle()
                        if !isOtherSelected {
                            customActivityText = ""
                            showCustomActivityError = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.indigo)
                                .frame(width: 30, height: 30)
                            
                            Text("Other")
                                .font(.headline)
                                .padding(.leading, 8)
                            
                            Spacer()
                            
                            Image(systemName: isOtherSelected ? "chevron.down" : "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.primary.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if isOtherSelected {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Enter your own coping activity")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            TextField("Describe your activity...", text: $customActivityText)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(showCustomActivityError ? Color.red : Color.primary.opacity(0.1), lineWidth: showCustomActivityError ? 2 : 1)
                                )
                                .onChange(of: customActivityText) { _ in
                                    if !customActivityText.isEmpty {
                                        showCustomActivityError = false
                                    }
                                }
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.none)
                            
                            // Error message when custom activity is empty
                            if showCustomActivityError {
                                Text("Please describe your activity")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, -8)
                                    .padding(.leading, 4)
                            }
                            
                            // Character limit indicator
                            HStack {
                                Spacer()
                                Text("\(customActivityText.count)/50 characters")
                                    .font(.caption)
                                    .foregroundColor(customActivityText.count > 50 ? .red : .gray)
                            }
                            
                            // Submit custom activity button
                            Button {
                                if customActivityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    withAnimation {
                                        showCustomActivityError = true
                                    }
                                } else {
                                    let customActivity = CopingActivity(activityName: customActivityText)
                                    viewModel.addCopingActivity(activity: customActivity)
                                    
                                    // Reset UI state
                                    isOtherSelected = false
                                    customActivityText = ""
                                }
                            } label: {
                                NavigationLink(destination: CopingActivityDetailView(activity: customActivityText)) {
                                    HStack {
                                        Text("Submit")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [ColorType.blue1.color, ColorType.blue2.color]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: ColorType.blue1.color.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                            }
                            .padding(.top, 8)
                            .disabled(customActivityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Add space at the bottom
                    Spacer()
                        .frame(height: 20)
                }
            }
            .padding()
            .animation(.spring(response: 0.3), value: isOtherSelected)
        }
        .navigationTitle("Coping Activities")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startTrackingLocation()
        }
        // Add NavigationLink for custom activity
        .navigationDestination(for: String.self) { customActivity in
            CopingActivityDetailView(activity: customActivity)
        }
    }
    
    // Decide which view to show for each activity
    @ViewBuilder
    private func destinationForActivity(_ activity: CopingActivity) -> some View {
        switch activity.activityName {
        case "Calm App":
            CalmActivityView()
        case "Listen to Music":
            MusicChoiceView()
                .environmentObject(CopingActivityViewModel())
        default:
            CopingActivityDetailView(activity: activity.activityName)
        }
    }
    
    // Map activity names to icons
    private func iconForActivity(_ activity: String) -> String {
        switch activity {
        case "Calm App": return "cloud.sun"
        case "Listen to Music": return "music.note"
        case "Take a walk": return "figure.walk"
        case "Meditate": return "brain.head.profile"
        case "Play games": return "gamecontroller"
        case "Read": return "book"
        default: return "peacesign"
        }
    }
    
    private func colorForActivity(_ activity: String) -> Color {
        switch activity {
        case "Calm App": return .blue
        case "Listen to Music": return .purple
        case "Take a walk": return .green
        case "Meditate": return .orange
        case "Play games": return .pink
        case "Read": return .teal
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        CopingActivityView()
            .environmentObject(CopingActivityViewModel())
    }
}
