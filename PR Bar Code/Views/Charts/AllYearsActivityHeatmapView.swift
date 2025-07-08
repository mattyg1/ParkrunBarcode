//
//  AllYearsActivityHeatmapView.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI

struct AllYearsActivityHeatmapView: View {
    let allYearsData: [Int: [ActivityDay]]
    @State private var selectedDay: ActivityDay?
    
    private let cellSize: CGFloat = 10
    private let cellSpacing: CGFloat = 1
    private let monthLabels = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
    
    private var sortedYears: [Int] {
        allYearsData.keys.sorted()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Activity Pattern - All Years")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Your complete parkrun history across all years")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Month labels header
                    HStack(spacing: 0) {
                        // Spacer for year labels
                        VStack { }
                            .frame(width: 50)
                        
                        ForEach(0..<12, id: \.self) { monthIndex in
                            Text(monthLabels[monthIndex])
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: getMonthWidth(monthIndex: monthIndex))
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Year rows
                    ForEach(sortedYears, id: \.self) { year in
                        HStack(spacing: 0) {
                            // Year label
                            Text(String(year))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                                .padding(.trailing, 5)
                            
                            // Activity cells for the year
                            HStack(spacing: 0) {
                                ForEach(0..<12, id: \.self) { monthIndex in
                                    let monthData = getMonthData(year: year, monthIndex: monthIndex)
                                    let weeksInMonth = ceil(Double(monthData.count) / 7.0)
                                    
                                    HStack(spacing: cellSpacing) {
                                        ForEach(0..<Int(weeksInMonth), id: \.self) { weekIndex in
                                            VStack(spacing: cellSpacing) {
                                                ForEach(0..<7, id: \.self) { dayIndex in
                                                    let dayData = getDayData(monthData: monthData, week: weekIndex, day: dayIndex)
                                                    
                                                    RoundedRectangle(cornerRadius: 1)
                                                        .fill(cellColor(for: dayData))
                                                        .frame(width: cellSize, height: cellSize)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 1)
                                                                .stroke(selectedDay?.id == dayData?.id ? Color.blue : Color.clear, lineWidth: 1)
                                                        )
                                                        .onTapGesture {
                                                            selectedDay = selectedDay?.id == dayData?.id ? nil : dayData
                                                        }
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: getMonthWidth(monthIndex: monthIndex))
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal)
            }
            
            // Legend and stats
            HStack(spacing: 16) {
                // Legend
                HStack(spacing: 8) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: cellSize, height: cellSize)
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 0.58, green: 0.45, blue: 0.80))
                            .frame(width: cellSize, height: cellSize)
                    }
                    
                    Text("More")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Total stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalRuns) parkruns")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("across \(sortedYears.count) years")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
                Text("Activity Analysis")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    InsightRow(text: "\(totalRuns) parkruns completed across \(sortedYears.count) years")
                    
                    if let mostActiveYear = getMostActiveYear() {
                        InsightRow(text: "Most active year: \(mostActiveYear.year) with \(mostActiveYear.count) parkruns")
                    }
                    
                    if let firstYear = sortedYears.first, let lastYear = sortedYears.last, firstYear != lastYear {
                        InsightRow(text: "parkrun journey spans from \(firstYear) to \(lastYear)")
                    }
                    
                    let averagePerYear = Double(totalRuns) / Double(sortedYears.count)
                    InsightRow(text: "Average \(String(format: "%.1f", averagePerYear)) parkruns per year")
                }
            }
            .padding(12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var totalRuns: Int {
        allYearsData.values.flatMap { $0 }.filter { $0.hasRun }.count
    }
    
    private func cellColor(for day: ActivityDay?) -> Color {
        guard let day = day else { return Color.gray.opacity(0.1) }
        
        if day.hasRun {
            return Color(red: 0.58, green: 0.45, blue: 0.80) // Purple for parkrun days
        } else {
            return Color.gray.opacity(0.15)
        }
    }
    
    private func getMonthWidth(monthIndex: Int) -> CGFloat {
        // Calculate approximate width needed for each month
        // This is a simplified calculation - in a real implementation you'd calculate based on actual days
        let daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][monthIndex]
        let weeksInMonth = ceil(Double(daysInMonth) / 7.0)
        return max(CGFloat(weeksInMonth) * (cellSize + cellSpacing), 20)
    }
    
    private func getMonthData(year: Int, monthIndex: Int) -> [ActivityDay] {
        guard let yearData = allYearsData[year] else { return [] }
        
        let calendar = Calendar.current
        return yearData.filter { day in
            calendar.component(.month, from: day.date) == monthIndex + 1
        }
    }
    
    private func getDayData(monthData: [ActivityDay], week: Int, day: Int) -> ActivityDay? {
        let dayIndex = week * 7 + day
        return dayIndex < monthData.count ? monthData[dayIndex] : nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getMostActiveYear() -> (year: Int, count: Int)? {
        let yearCounts = allYearsData.mapValues { days in
            days.filter { $0.hasRun }.count
        }
        
        guard let maxEntry = yearCounts.max(by: { $0.value < $1.value }) else { return nil }
        return (year: maxEntry.key, count: maxEntry.value)
    }
}

#Preview {
    let sampleData = createSampleData()
    
    return AllYearsActivityHeatmapView(allYearsData: sampleData)
        .padding()
}

private func createSampleData() -> [Int: [ActivityDay]] {
    let calendar = Calendar.current
    var sampleData: [Int: [ActivityDay]] = [:]
    
    for year in 2022...2025 {
        let yearData = (1...365).compactMap { dayOffset -> ActivityDay? in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: calendar.date(from: DateComponents(year: year, month: 1, day: 1))!) else { return nil }
            
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
        sampleData[year] = yearData
    }
    
    return sampleData
}