//
//  CalendarView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var moodViewModel: MoodViewModel

    let interval: DateInterval
    @Binding var dateSelected: DateComponents?
    @Binding var displayEvents: Bool

    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var navigateToGraphs: Bool = false
    @State private var navigateToReport: Bool = false
    @State private var tappedDate: Date = Date()
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var slideDirection: Int = 0 // -1 for left, 1 for right
    @State private var isAnimating: Bool = false

    private let monthSymbols = Calendar.current.monthSymbols
    private var yearRange: [Int] {
        // Dynamic year range from 2024 to current year
        return Array(2024...Calendar.current.component(.year, from: Date()))
    }
    
    private var isAtCurrentMonth: Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        return selectedYear == currentYear && selectedMonth == currentMonth
    }

    var body: some View {
        ZStack {
            ColorType2.darkBlue.color.opacity(0.05)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Activity Calendar")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                // Calendar content
                ScrollView {
                    VStack(spacing: 16) {
                        // Month navigation and selector
                        HStack {
                            Button(action: {
                                withAnimation {
                                    previousMonth()
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .imageScale(.medium)
                                    .frame(width: 38, height: 38)
                                    .background(ColorType.blue1.color)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            // Month and Year display
                            HStack(spacing: 10) {
                                Menu {
                                    Picker("Month", selection: $selectedMonth) {
                                        ForEach(getAvailableMonths(), id: \.self) { monthIndex in
                                            Text(monthSymbols[monthIndex - 1])
                                                .tag(monthIndex)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(monthSymbols[selectedMonth - 1])
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                            .frame(minWidth: 75, alignment: .leading)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(ColorType.blue1.color)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(color: Color.primary.opacity(0.1), radius: 3, x: 0, y: 1)
                                }
                                .onChange(of: selectedMonth) { _ in
                                    validateSelection()
                                }

                                Menu {
                                    Picker("Year", selection: $selectedYear) {
                                        ForEach(yearRange, id: \.self) { year in
                                            Text("\(year)")
                                                .tag(year)
                                        }
                                    }
                                    .labelsHidden()
                                } label: {
                                    HStack {
                                        Text("\(selectedYear)")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .frame(minWidth: 55, alignment: .leading)
                                            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(ColorType.blue1.color)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(color: Color.primary.opacity(0.1), radius: 3, x: 0, y: 1)
                                }
                                .onChange(of: selectedYear) { _ in
                                    validateSelection()
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    nextMonth()
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white)
                                    .imageScale(.medium)
                                    .frame(width: 38, height: 38)
                                    .background(isAtCurrentMonth ? ColorType.blue1.color.opacity(0.3) : ColorType.blue1.color)
                                    .clipShape(Circle())
                            }
                            .disabled(isAtCurrentMonth)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        // Calendar container
                        VStack(spacing: 16) {
                            // Weekday headers
                            HStack {
                                ForEach(["SU", "MO", "TU", "WE", "TH", "FR", "SA"], id: \.self) { dayHeader in
                                    Text(dayHeader)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(ColorType.darkBlue.color.opacity(0.7))
                                }
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                            // Calendar grid
                            let days = generateDaysInMonth(month: selectedMonth, year: selectedYear)
                            ZStack {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                    ForEach(days, id: \.self) { date in
                                        if let validDate = date {
                                            CalendarDayCell(date: validDate, onTap: {
                                                tappedDate = validDate
                                                navigateToGraphs = true
                                            })
                                            .environmentObject(healthKitManager)
                                            .environmentObject(moodViewModel)
                                        } else {
                                            Rectangle()
                                                .foregroundColor(.clear)
                                                .frame(height: 50)
                                        }
                                    }
                                }
                                .padding(.bottom, 16)
                                .transition(.asymmetric(
                                    insertion: .move(edge: slideDirection > 0 ? .trailing : .leading),
                                    removal: .move(edge: slideDirection > 0 ? .leading : .trailing)
                                ))
                                .id("calendar-\(selectedMonth)-\(selectedYear)") // Force view recreation on month/year change
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMonth)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedYear)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal, 24)

                        Spacer()

                        // Generate Report Button
                        Button(action: { navigateToReport = true }) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.headline)
                                Text("Generate Custom Report")
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
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToReport) {
            ReportView()
        }
        .navigationTitle("Activity Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            validateSelection()
        }
    }
    
    private func nextMonth() {
        do {
            let currentDate = Date()
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: currentDate)
            let currentYear = calendar.component(.year, from: currentDate)
            
            // Check if we're already at the current month
            if selectedYear == currentYear && selectedMonth == currentMonth {
                return // Already at current month, can't go further
            }
            
            // Set slide direction for animation
            slideDirection = 1
            
            // Calculate next month
            if selectedMonth == 12 {
                // If December, go to January of next year
                let nextYear = selectedYear + 1
                
                // But don't go beyond current year
                if nextYear > currentYear {
                    selectedMonth = currentMonth
                    selectedYear = currentYear
                } else {
                    withAnimation {
                        selectedMonth = 1
                        selectedYear = nextYear
                    }
                }
            } else {
                // Regular month increment
                let nextMonth = selectedMonth + 1
                
                // Check if next month would exceed current month in current year
                if selectedYear == currentYear && nextMonth > currentMonth {
                    selectedMonth = currentMonth
                } else {
                    withAnimation {
                        selectedMonth = nextMonth
                    }
                }
            }
        } catch {
            errorMessage = "Failed to update calendar: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func previousMonth() {
        do {
            // Set slide direction for animation
            slideDirection = -1
            
            if selectedMonth == 1 {
                withAnimation {
                    selectedMonth = 12
                    selectedYear -= 1
                }
            } else {
                withAnimation {
                    selectedMonth -= 1
                }
            }
        } catch {
            errorMessage = "Failed to update calendar: \(error.localizedDescription)"
            showError = true
        }
    }

    private func getAvailableMonths() -> [Int] {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        if selectedYear == currentYear {
            // If current year, only show months up to current month
            return Array(1...currentMonth)
        } else {
            // For past years, show all months
            return Array(1...12)
        }
    }

    private func validateSelection() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        // If user somehow selected a future date, reset to current month/year
        if selectedYear > currentYear || (selectedYear == currentYear && selectedMonth > currentMonth) {
            selectedMonth = currentMonth
            selectedYear = currentYear
        }
    }

    private func formatYear(_ year: Int) -> String {
        return "\(year)"
    }
}

// MARK: - CalendarDayCell (Single Day Cell)
fileprivate struct CalendarDayCell: View {
    let date: Date
    let onTap: () -> Void

    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var moodViewModel: MoodViewModel
    @State private var dataAvailable: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 4) {
            if dataAvailable {
                Circle()
                    .fill(ColorType.blue1.color)
                    .frame(width: 6, height: 6)
                    .padding(.top, 2)
            } else {
                Spacer()
                    .frame(height: 8)
            }
            
            Text(dayNumberString(from: date))
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(dataAvailable ? .semibold : .regular)
                .foregroundColor(dataAvailable ? .primary : .gray)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(dataAvailable ? Color(.systemBackground) : Color.clear)
                .shadow(color: dataAvailable ? Color.primary.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(dataAvailable ? ColorType.blue1.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if dataAvailable {
                onTap()
            }
        }
        .task {
            do {
                dataAvailable = await fetchDataAvailability()
            } catch {
                errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                showError = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }

    private func dayNumberString(from date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    /// Asynchronously fetch data availability for the given day.
    private func fetchDataAvailability() async -> Bool {
        do {
            async let hrData = healthKitManager.fetchHeartRateData(for: date)
            async let noiseData = healthKitManager.fetchNoiseLevelData(for: date)
            async let moodData = moodViewModel.fetchMoods(for: date)
            let (hr, noise, moods) = await (hrData, noiseData, moodData)
            return !hr.isEmpty || !noise.isEmpty || !moods.isEmpty
        } catch {
            errorMessage = "Failed to fetch data: \(error.localizedDescription)"
            showError = true
            return false
        }
    }
}

// MARK: - Helper for generating days in a month
extension CalendarView {
    private func generateDaysInMonth(month: Int, year: Int) -> [Date?] {
        var days: [Date?] = []
        let calendar = Calendar.current

        // 1) Build a Date for the first day of the given month/year
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return days
        }

        let numDays = range.count
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlankCount = firstWeekday - 1
        for _ in 0..<leadingBlankCount {
            days.append(nil)
        }

        for dayValue in 1...numDays {
            var dayComponents = DateComponents()
            dayComponents.year = year
            dayComponents.month = month
            dayComponents.day = dayValue
            if let realDate = calendar.date(from: dayComponents) {
                days.append(realDate)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }
}

// MARK: - Example GraphsViewForDate
struct GraphsViewForDate: View {
    let selectedDate: Date
    var body: some View {
        Text("Graphs for \(selectedDate.formatted(date: .numeric, time: .omitted))")
            .font(.title3)
            .navigationTitle("Activity Review")
    }
}

#Preview {
    @Previewable @State var dateSelected: DateComponents? = nil
    @Previewable @State var displayEvents = false
    let calendarInterval = DateInterval(start: Date().addingTimeInterval(-7 * 60 * 24),
                                        end: Date().addingTimeInterval(7 * 60 * 24))

    CalendarView(interval: calendarInterval, dateSelected: $dateSelected, displayEvents: $displayEvents)
        .environmentObject(HealthKitManager())
        .environmentObject(MoodViewModel())
}
