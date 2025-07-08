//
//  AllYearsActivityHeatmapView.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI

struct AllYearsActivityHeatmapView: View {
    let allYearsData: [Int: [ActivityDay]]
    let totalParkruns: Int? // Add parameter for correct total
    @State private var selectedCell: (year: Int, month: Int)?
    
    private let cellHeight: CGFloat = 20
    private let cellSpacing: CGFloat = 2
    private let monthLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    private var sortedYears: [Int] {
        allYearsData.keys.sorted()
    }
    
    private var monthlyData: [Int: [Int: Int]] {
        var result: [Int: [Int: Int]] = [:]
        
        for (year, days) in allYearsData {
            var monthCounts: [Int: Int] = [:]
            let calendar = Calendar.current
            
            for day in days.filter({ $0.hasRun }) {
                let month = calendar.component(.month, from: day.date)
                monthCounts[month, default: 0] += 1
            }
            
            result[year] = monthCounts
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Activity Pattern - All Years")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Monthly parkrun activity across all years")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Month labels header
                    HStack(spacing: cellSpacing) {
                        // Spacer for year labels
                        Text("")
                            .frame(width: 50)
                        
                        ForEach(0..<12, id: \.self) { monthIndex in
                            Text(monthLabels[monthIndex])
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 40)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Year rows
                    ForEach(sortedYears, id: \.self) { year in
                        HStack(spacing: cellSpacing) {
                            // Year label
                            Text(String(year))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .trailing)
                            
                            // Monthly activity cells for the year
                            ForEach(1...12, id: \.self) { month in
                                let count = monthlyData[year]?[month] ?? 0
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(cellColor(for: count))
                                    .frame(width: 40, height: cellHeight)
                                    .overlay(
                                        Text(count > 0 ? "\(count)" : "")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(count > 0 ? .white : .clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(
                                                selectedCell?.year == year && selectedCell?.month == month ? Color.blue : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .onTapGesture {
                                        if selectedCell?.year == year && selectedCell?.month == month {
                                            selectedCell = nil
                                        } else {
                                            selectedCell = (year: year, month: month)
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }
                .padding(.horizontal)
            }
            
            // Legend and stats
            HStack(spacing: 16) {
                // Legend
                HStack(spacing: 8) {
                    Text("0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 16, height: 16)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(red: 0.58, green: 0.45, blue: 0.80).opacity(0.5))
                            .frame(width: 16, height: 16)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(red: 0.58, green: 0.45, blue: 0.80))
                            .frame(width: 16, height: 16)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(red: 0.45, green: 0.25, blue: 0.65))
                            .frame(width: 16, height: 16)
                    }
                    
                    Text("5+")
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
            
            // Selected cell details
            if let selectedCell = selectedCell {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Month")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(monthLabels[selectedCell.month - 1]) \(selectedCell.year)")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("parkruns")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(monthlyData[selectedCell.year]?[selectedCell.month] ?? 0)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
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
                    
                    if let mostActiveMonth = getMostActiveMonth() {
                        InsightRow(text: "Most active month: \(monthLabels[mostActiveMonth.month - 1]) with \(mostActiveMonth.totalCount) total parkruns")
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
        totalParkruns ?? allYearsData.values.flatMap { $0 }.filter { $0.hasRun }.count
    }
    
    private func cellColor(for count: Int) -> Color {
        switch count {
        case 0:
            return Color.gray.opacity(0.15)
        case 1:
            return Color(red: 0.58, green: 0.45, blue: 0.80).opacity(0.5)
        case 2...4:
            return Color(red: 0.58, green: 0.45, blue: 0.80)
        default: // 5+
            return Color(red: 0.45, green: 0.25, blue: 0.65)
        }
    }
    
    private func getMostActiveYear() -> (year: Int, count: Int)? {
        let yearCounts = allYearsData.mapValues { days in
            days.filter { $0.hasRun }.count
        }
        
        guard let maxEntry = yearCounts.max(by: { $0.value < $1.value }) else { return nil }
        return (year: maxEntry.key, count: maxEntry.value)
    }
    
    private func getMostActiveMonth() -> (month: Int, totalCount: Int)? {
        var monthTotals: [Int: Int] = [:]
        
        for (_, yearData) in monthlyData {
            for (month, count) in yearData {
                monthTotals[month, default: 0] += count
            }
        }
        
        guard let maxEntry = monthTotals.max(by: { $0.value < $1.value }) else { return nil }
        return (month: maxEntry.key, totalCount: maxEntry.value)
    }
}

#Preview {
    let sampleData = createSampleData()
    
    return AllYearsActivityHeatmapView(allYearsData: sampleData, totalParkruns: 283)
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