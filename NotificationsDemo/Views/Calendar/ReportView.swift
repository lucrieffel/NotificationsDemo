//
//  ReportView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var startDate = Date().addingTimeInterval(-7*24*60*60) // Default to 1 week ago
    @State private var endDate = Date()
    @State private var selectedReportTypes = Set<ReportType>([.heartRate, .noise, .mood]) // Default all selected
    @State private var isGenerating = false
    @State private var showConfirmation = false
    
    enum ReportType: String, CaseIterable, Identifiable {
        case heartRate = "Heart Rate"
        case noise = "Noise Exposure"
        case mood = "Mood Data"
        case activity = "Activity"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .noise: return "ear.fill"
            case .mood: return "face.smiling.fill"
            case .activity: return "figure.walk"
            }
        }
        
        var color: Color {
            switch self {
            case .heartRate: return .red
            case .noise: return .purple
            case .mood: return .orange
            case .activity: return .green
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health Report Generator")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Create comprehensive health reports from your data")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Date Range Section
                            reportSection(title: "Date Range", icon: "calendar") {
                                VStack(spacing: 12) {
                                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                    
                                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                            }
                            
                            // Report Types Section
                            reportSection(title: "Report Content", icon: "doc.text") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Select data to include:")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                        ForEach(ReportType.allCases) { type in
                                            reportTypeButton(type)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                            }
                            
                            // Generate Button
                            Button(action: generateReport) {
                                HStack {
                                    Image(systemName: "doc.text.below.ecg")
                                        .font(.headline)
                                    Text(isGenerating ? "Generating..." : "Generate Report")
                                        .font(.headline)
                                    
                                    if isGenerating {
                                        Spacer()
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.3), radius: 3)
                            }
                            .disabled(selectedReportTypes.isEmpty || isGenerating || startDate > endDate)
                            .padding(.horizontal)
                            .opacity(selectedReportTypes.isEmpty || startDate > endDate ? 0.6 : 1.0)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                }
            }
            .alert("Report Generated", isPresented: $showConfirmation) {
                Button("View Report", role: .none) { /* Navigate to view report */ }
                Button("Close", role: .cancel) { }
            } message: {
                Text("Your health report has been successfully generated.")
            }
        }
    }
    
    private func reportSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            content()
        }
        .padding(.horizontal)
    }
    
    private func reportTypeButton(_ type: ReportType) -> some View {
        Button(action: {
            if selectedReportTypes.contains(type) {
                selectedReportTypes.remove(type)
            } else {
                selectedReportTypes.insert(type)
            }
        }) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(selectedReportTypes.contains(type) ? .white : type.color)
                Text(type.rawValue)
                    .fontWeight(.medium)
                Spacer()
                if selectedReportTypes.contains(type) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedReportTypes.contains(type) ? type.color : type.color.opacity(0.1))
            )
            .foregroundColor(selectedReportTypes.contains(type) ? .white : .primary)
        }
    }
    
    private func generateReport() {
        // Date validation
        guard startDate <= endDate else { return }
        guard !selectedReportTypes.isEmpty else { return }
        
        isGenerating = true
        
        // Simulate report generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isGenerating = false
            showConfirmation = true
            
            // Here you would actually generate the report with the selected parameters
            print("Generating report from \(startDate.formatted(date: .numeric, time: .omitted)) to \(endDate.formatted(date: .numeric, time: .omitted))")
            print("Selected data types: \(selectedReportTypes.map { $0.rawValue }.joined(separator: ", "))")
        }
    }
}

#Preview {
    ReportView()
}
