//
//  MoodSurveyView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/4/25.
//

import SwiftUI
import Firebase

struct MoodSurvey: View {
    @Environment(\.dismiss) private var dismiss
    
    let columnLayout = Array(repeating: GridItem(), count: 3)
    @State private var selectedMood: MoodType = .happy
    @State private var intensity: Double = 5.0
    @State private var isEditing = false
    @State private var journalText: String = ""
    @State private var showConfirmation = false
    @State private var customMoodText: String = ""
    @State private var showCustomMoodError: Bool = false
    
    @EnvironmentObject private var viewModel: MoodViewModel
    
    let moods: [MoodType] = [
        .happy,
        .sad,
        .stressed,
        .anxious,
        .angry,
        .neutral
    ]
    
    var body: some View {
        ZStack {
            // Background color from HomeView
            ColorType2.darkBlue.color.opacity(0.05)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Mood Selection Section
                    moodSelectionSection
                    
                    // Mood Intensity Section
                    intensitySection
                    
                    // Journal Section
                    journalSection
                    
                    // Save Button
                    saveButton
                    
                    // Navigation link to confirmation view
                    NavigationLink(destination: MoodSavedConfirmationView(), isActive: $showConfirmation) {
                        EmptyView()
                    }
                    .hidden()
                }
                .padding(.vertical)
            }
        }
        .onAppear{
            print("Mood survey appeared")
        }
        .navigationTitle("Mood Check-In")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - View Components
    
    private var moodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling?")
                .font(.title3)
                .fontWeight(.semibold)
            
            // Standard mood options in a grid
            LazyVGrid(columns: columnLayout, spacing: 16) {
                ForEach(moods, id: \.name) { mood in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMood = mood
                            intensity = 5
                        }
                    }) {
                        moodButton(for: mood)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Other mood option (full width)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedMood = .other
                    intensity = 5
                }
            }) {
                otherMoodButton
            }
            .buttonStyle(PlainButtonStyle())
            
            // Custom mood input field when Other is selected
            if selectedMood == .other {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Describe your mood")
                        .font(.headline)
                        .foregroundColor(ColorType.blue1.color)
                        .padding(.top, 8)
                    
                    ZStack(alignment: .leading) {
                        if customMoodText.isEmpty {
                            Text("Enter your mood...")
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        
                        TextField("", text: $customMoodText)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(showCustomMoodError ? Color.red : ColorType.blue1.color.opacity(0.5), lineWidth: showCustomMoodError ? 2 : 1)
                            )
                            .onChange(of: customMoodText) { _ in
                                if !customMoodText.isEmpty {
                                    showCustomMoodError = false
                                }
                            }
                            .disableAutocorrection(true)
                    }
                    
                    // Error message when custom mood is empty
                    if showCustomMoodError {
                        Text("Please describe your mood")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, -8)
                            .padding(.leading, 4)
                    }
                    
                    // Character limit indicator
                    HStack {
                        Spacer()
                        Text("\(customMoodText.count)/50 characters")
                            .font(.caption)
                            .foregroundColor(customMoodText.count > 50 ? .red : .gray)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
        .padding(.horizontal)
        .animation(.spring(response: 0.3), value: selectedMood == .other)
    }
    
    private var otherMoodButton: some View {
        VStack(spacing: 8) {
            Text(MoodType.other.imgURL)
                .font(.system(size: 32))
            
            Text(MoodType.other.name)
                .font(.headline)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .foregroundColor(selectedMood == .other ? .white : .primary)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    selectedMood == .other ?
                    AnyShapeStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [ColorType.blue1.color, ColorType.blue2.color]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ) : AnyShapeStyle(Color(.systemBackground))
                )
                .shadow(
                    color: Color.primary.opacity(selectedMood == .other ? 0.15 : 0.05),
                    radius: selectedMood == .other ? 8.0 : 4.0,
                    x: 0,
                    y: selectedMood == .other ? 4.0 : 2.0
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: selectedMood == .other ? 0 : 1)
        )
        .scaleEffect(selectedMood == .other ? 1.05 : 1.0)
        .padding(.horizontal, 8)
    }
    
    private func moodButton(for mood: MoodType) -> some View {
        let isSelected = selectedMood == mood
        
        let backgroundFill: AnyShapeStyle = isSelected ?
            AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [ColorType.blue1.color, ColorType.blue2.color]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) : AnyShapeStyle(Color(.systemBackground))
        
        let shadowOpacity = isSelected ? 0.15 : 0.05
        let shadowRadius = isSelected ? 8.0 : 4.0
        let shadowY = isSelected ? 4.0 : 2.0
        
        return MoodDetail(mood: mood)
            .padding()
            .foregroundColor(isSelected ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundFill)
                    .shadow(color: Color.primary.opacity(shadowOpacity),
                            radius: shadowRadius,
                            x: 0,
                            y: shadowY)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.1), lineWidth: isSelected ? 0 : 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
    }
    
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("How intense is your feeling?")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(intensity))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ColorType.blue1.color)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.primary.opacity(0.1), radius: 3, x: 0, y: 2)
                    )
            }
            
            intensitySlider
            
            // Visual intensity indicator
            intensityIndicator
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
        .padding(.horizontal)
    }
    
    private var intensitySlider: some View {
        HStack {
            Text(selectedMood.imgURL)
                .font(.footnote)
                .fontWeight(.light)
            
            Slider(
                value: $intensity,
                in: 1...10,
                step: 1
            ) {
                Text("Intensity")
            } onEditingChanged: { editing in
                isEditing = editing
            }
            .accentColor(ColorType.blue1.color)
            
            Text(selectedMood.imgURL)
                .font(.title)
                .fontWeight(.bold)
        }
    }
    
    private var intensityIndicator: some View {
        HStack(spacing: 0) {
            ForEach(1...10, id: \.self) { level in
                Rectangle()
                    .fill(level <= Int(intensity) ?
                          ColorType.blue1.color.opacity(Double(level) / 10) :
                          Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
            }
        }
        .padding(.top, -8)
    }
    
    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's on your mind?")
                .font(.title3)
                .fontWeight(.semibold)
            
            journalEditor
            
            // Character count
            HStack {
                Spacer()
                Text("\(journalText.count)/200 characters")
                    .font(.caption)
                    .foregroundColor(journalText.count > 200 ? .red : .gray)
            }
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
        .padding(.horizontal)
    }
    
    private var journalEditor: some View {
        ZStack(alignment: .topLeading) {
            if journalText.isEmpty {
                Text("Write your thoughts here...")
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
            
            TextEditor(text: $journalText)
                .padding(4)
                .frame(minHeight: 150)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ColorType.blue1.color.opacity(0.5), lineWidth: 1)
                )
        }
    }
    
    private var saveButton: some View {
        Button {
            Task {
                // Validate custom mood input if "Other" is selected
                if selectedMood == .other && customMoodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    withAnimation {
                        showCustomMoodError = true
                    }
                    return
                }
                
                let mood = Mood(
                    mood: selectedMood,
                    intensity: Int(intensity),
                    journalText: journalText,
                    customMoodText: selectedMood == .other ? customMoodText : nil,
                    date: Date()
                )
                
                self.viewModel.addMood(mood: mood)
                selectedMood = .happy
                intensity = 5
                journalText = ""
                customMoodText = ""
                showCustomMoodError = false
                
                // Set showConfirmation to trigger navigation
                showConfirmation = true
            }
        } label: {
            HStack {
                Text("Save Mood")
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
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

#Preview {
    NavigationStack {
        MoodSurvey()
            .environmentObject(MoodViewModel())
    }
}
//
//#Preview {
//    MoodSurveyView()
//}
