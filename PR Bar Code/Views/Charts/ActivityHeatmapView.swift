//
//  ActivityHeatmapView.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI

struct ActivityHeatmapView: View {
    let activityData: [ActivityDay]
    let year: Int
    @State private var selectedDay: ActivityDay?
    
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 2
    private let monthLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Activity Heatmap - \(year)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Your parkrun activity throughout the year")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Month labels
                    HStack(spacing: 0) {
                        // Spacer for day labels
                        VStack { }
                            .frame(width: 30)
                        
                        ForEach(0..<12, id: \.self) { monthIndex in
                            let monthData = getMonthData(monthIndex: monthIndex)
                            let weeksInMonth = monthData.count / 7 + (monthData.count % 7 > 0 ? 1 : 0)
                            let monthWidth = CGFloat(weeksInMonth) * (cellSize + cellSpacing)
                            
                            Text(monthLabels[monthIndex])
                                .font(.caption2)
                                .frame(width: max(monthWidth, 25))
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Calendar grid
                    HStack(alignment: .top, spacing: 0) {
                        // Day labels
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                Text(dayLabels[dayIndex])
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, height: cellSize)
                            }
                        }
                        .padding(.trailing, 10)
                        
                        // Heatmap cells
                        LazyHStack(spacing: cellSpacing) {
                            ForEach(getWeeksInYear(), id: \.self) { weekIndex in
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        let dayData = getDayData(week: weekIndex, day: dayIndex)
                                        
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(cellColor(for: dayData))
                                            .frame(width: cellSize, height: cellSize)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 2)
                                                    .stroke(selectedDay?.id == dayData?.id ? Color.blue : Color.clear, lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                selectedDay = selectedDay?.id == dayData?.id ? nil : dayData
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Legend
            HStack(spacing: 16) {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { intensity in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(legendColor(intensity: intensity))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
                
                Text("More")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalRuns) parkruns in \(year)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if let longestStreak = calculateLongestStreak() {
                        Text("Longest gap: \(longestStreak) weeks")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Selected day details
            if let selectedDay = selectedDay {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Day")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDate(selectedDay.date))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        if selectedDay.hasRun {
                            VStack(alignment: .center, spacing: 2) {
                                Text("Venue")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(selectedDay.venue ?? "Unknown")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(selectedDay.time ?? "N/A")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Text("No parkrun")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
            
            // Activity insights
            VStack(alignment: .leading, spacing: 8) {
                Text("\(year) Activity Pattern")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    InsightRow(text: "\(totalRuns) parkruns completed so far in \(year)")
                    
                    if let mostActiveMonth = getMostActiveMonth() {
                        InsightRow(text: "Most active month: \(mostActiveMonth)")
                    }
                    
                    InsightRow(text: "Regular Saturday participation maintained")
                    
                    if let gap = calculateLongestStreak() {
                        InsightRow(text: "Longest gap: \(gap) weeks between parkruns")
                    }
                }
            }
            .padding(12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var totalRuns: Int {
        activityData.filter { $0.hasRun }.count
    }
    
    private func cellColor(for day: ActivityDay?) -> Color {
        guard let day = day else { return Color.gray.opacity(0.1) }
        
        if day.hasRun {
            return Color(red: 0.58, green: 0.45, blue: 0.80) // Purple for parkrun days
        } else {
            return Color.gray.opacity(0.15)
        }
    }
    
    private func legendColor(intensity: Int) -> Color {
        switch intensity {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color(red: 0.58, green: 0.45, blue: 0.80).opacity(0.3)
        case 2: return Color(red: 0.58, green: 0.45, blue: 0.80).opacity(0.5)
        case 3: return Color(red: 0.58, green: 0.45, blue: 0.80).opacity(0.7)
        case 4: return Color(red: 0.58, green: 0.45, blue: 0.80)
        default: return Color.gray.opacity(0.15)
        }
    }
    
    private func getWeeksInYear() -> Range<Int> {
        // Calculate number of weeks in the year
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        let weeks = calendar.dateInterval(of: .weekOfYear, for: startOfYear)!.start
        let weeksCount = calendar.dateComponents([.weekOfYear], from: weeks, to: endOfYear).weekOfYear ?? 52
        
        return 0..<weeksCount
    }
    
    private func getDayData(week: Int, day: Int) -> ActivityDay? {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let startOfFirstWeek = calendar.dateInterval(of: .weekOfYear, for: startOfYear)!.start
        
        guard let targetDate = calendar.date(byAdding: .day, value: week * 7 + day, to: startOfFirstWeek) else {
            return nil
        }
        
        // Check if this date is within our year
        let targetYear = calendar.component(.year, from: targetDate)
        guard targetYear == year else { return nil }
        
        return activityData.first { calendar.isDate($0.date, inSameDayAs: targetDate) }
    }
    
    private func getMonthData(monthIndex: Int) -> [ActivityDay] {
        let calendar = Calendar.current
        return activityData.filter { day in
            calendar.component(.month, from: day.date) == monthIndex + 1
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getMostActiveMonth() -> String? {
        let calendar = Calendar.current
        let monthCounts = Dictionary(grouping: activityData.filter { $0.hasRun }) { day in
            calendar.component(.month, from: day.date)
        }.mapValues { $0.count }
        
        guard let maxMonth = monthCounts.max(by: { $0.value < $1.value }) else { return nil }
        
        let monthName = monthLabels[maxMonth.key - 1]
        return "\(monthName) with \(maxMonth.value) parkruns"
    }
    
    private func calculateLongestStreak() -> Int? {
        let runsWithDates = activityData
            .filter { $0.hasRun }
            .sorted { $0.date < $1.date }
        
        guard runsWithDates.count > 1 else { return nil }
        
        var maxGap = 0
        let calendar = Calendar.current
        
        for i in 1..<runsWithDates.count {
            let gap = calendar.dateComponents([.day], from: runsWithDates[i-1].date, to: runsWithDates[i].date).day ?? 0
            let weekGap = gap / 7
            maxGap = max(maxGap, weekGap)
        }
        
        return maxGap
    }
}

#Preview {
    let calendar = Calendar.current
    let sampleData = (1...365).compactMap { dayOffset -> ActivityDay? in
        guard let date = calendar.date(byAdding: .day, value: dayOffset, to: calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!) else { return nil }
        
        // Create some sample parkrun days (Saturdays mostly)
        let isWeekend = calendar.component(.weekday, from: date) == 7 // Saturday
        let hasRun = isWeekend && dayOffset % 14 == 0 // Every other Saturday
        
        return ActivityDay(
            date: date,
            hasRun: hasRun,
            venue: hasRun ? ["Whiteley parkrun", "Netley Abbey parkrun", "Lee-on-the-Solent parkrun"].randomElement() : nil,
            time: hasRun ? ["24:24", "25:15", "23:42", "26:01"].randomElement() : nil
        )
    }
    
    ActivityHeatmapView(activityData: sampleData, year: 2025)
        .padding()
}