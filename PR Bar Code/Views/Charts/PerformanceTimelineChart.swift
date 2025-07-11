//
//  PerformanceTimelineChart.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI
import Charts

struct PerformanceTimelineChart: View {
    let performanceData: [PerformanceData]
    @State private var selectedDataPoint: PerformanceData?
    
    private var displayData: [PerformanceData] {
        // Show all data sorted by date
        performanceData.sorted { data1, data2 in
            let date1 = parseDate(data1.date) ?? Date.distantPast
            let date2 = parseDate(data2.date) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    private var yAxisRange: ClosedRange<Double> {
        guard !displayData.isEmpty else { return 20...30 }
        
        let minTime = displayData.map { $0.timeInMinutes }.min() ?? 20
        let maxTime = displayData.map { $0.timeInMinutes }.max() ?? 30
        let padding = (maxTime - minTime) * 0.1
        
        return (minTime - padding)...(maxTime + padding)
    }
    
    private var yearAxisValues: [Date] {
        guard !displayData.isEmpty else { return [] }
        
        let dates = displayData.compactMap { parseDate($0.date) }
        guard !dates.isEmpty else { return [] }
        
        let sortedDates = dates.sorted()
        let startYear = Calendar.current.component(.year, from: sortedDates.first!)
        let endYear = Calendar.current.component(.year, from: sortedDates.last!)
        
        let yearRange = endYear - startYear + 1
        let maxLabels = 8
        
        if yearRange <= maxLabels {
            // Show all years if we have 8 or fewer
            return (startYear...endYear).compactMap { year in
                Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))
            }
        } else {
            // Show evenly spaced years to get approximately 8 labels
            let step = max(1, yearRange / maxLabels)
            return stride(from: startYear, through: endYear, by: step).compactMap { year in
                Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Performance Timeline")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Your complete parkrun performance history")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Chart(displayData, id: \.id) { data in
                LineMark(
                    x: .value("Date", parseDate(data.date) ?? Date()),
                    y: .value("Time", data.timeInMinutes)
                )
                .foregroundStyle(Color.adaptiveParkrunGreen)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                
                if let selectedDataPoint = selectedDataPoint, selectedDataPoint.id == data.id {
                    PointMark(
                        x: .value("Date", parseDate(data.date) ?? Date()),
                        y: .value("Time", data.timeInMinutes)
                    )
                    .foregroundStyle(Color.adaptiveParkrunGreen)
                    .symbolSize(60)
                    
                    RuleMark(x: .value("Selected Date", parseDate(data.date) ?? Date()))
                        .foregroundStyle(Color.adaptiveParkrunGreen.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
            }
            .frame(height: 220)
            .chartYScale(domain: yAxisRange)
            .chartXAxis {
                AxisMarks(values: yearAxisValues) { value in
                    AxisValueLabel(format: .dateTime.year(.defaultDigits))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let timeValue = value.as(Double.self) {
                            Text(formatTimeFromMinutes(timeValue))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
            }
            .onTapGesture { location in
                // Simple tap handling - in a real implementation, you'd calculate which point was tapped
                if selectedDataPoint != nil {
                    selectedDataPoint = nil
                } else if let firstPoint = displayData.first {
                    selectedDataPoint = firstPoint
                }
            }
            
            // Selected point details
            if let selectedPoint = selectedDataPoint {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Run Details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.adaptiveParkrunGreen)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedPoint.date)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text("Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedPoint.formattedTime)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.adaptiveParkrunGreen)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Venue")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedPoint.venue)
                                .font(.body)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .padding(12)
                .background(Color.adaptiveParkrunGreen.opacity(0.05))
                .cornerRadius(8)
            }
            
            // Performance insights
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Performance Trends")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.adaptiveParkrunGreen)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let mostRecent = displayData.first {
                        InsightRow(text: "Most recent run: \(mostRecent.formattedTime) at \(mostRecent.venue) (\(mostRecent.date))")
                    }
                    
                    if let bestRecent = displayData.min(by: { $0.timeInMinutes < $1.timeInMinutes }) {
                        InsightRow(text: "Best recent time: \(bestRecent.formattedTime) at \(bestRecent.venue)")
                    }
                    
                    let averageTime = displayData.reduce(0) { $0 + $1.timeInMinutes } / Double(displayData.count)
                    InsightRow(text: "Average recent time: \(formatTimeFromMinutes(averageTime))")
                    
                    if displayData.count > 1 {
                        let trend = calculateTrend()
                        InsightRow(text: trend)
                    }
                }
            }
            .padding(12)
            .background(Color.adaptiveParkrunGreen.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.date(from: dateString)
    }
    
    private func formatDateForChart(_ dateString: String) -> String {
        // Convert DD/MM/YYYY to shorter format for chart display
        let components = dateString.split(separator: "/")
        if components.count == 3 {
            return "\(components[0])/\(components[1])"
        }
        return dateString
    }
    
    private func formatTimeFromMinutes(_ minutes: Double) -> String {
        let mins = Int(minutes)
        let secs = Int((minutes - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func calculateTrend() -> String {
        guard displayData.count >= 2 else { return "Not enough data for trend analysis" }
        
        let recent = Array(displayData.prefix(3))
        let older = Array(displayData.suffix(3))
        
        let recentAverage = recent.reduce(0) { $0 + $1.timeInMinutes } / Double(recent.count)
        let olderAverage = older.reduce(0) { $0 + $1.timeInMinutes } / Double(older.count)
        
        let difference = recentAverage - olderAverage
        
        if abs(difference) < 0.1 {
            return "Times are consistently stable"
        } else if difference < 0 {
            let improvement = abs(difference) * 60
            return "Improving trend: \(Int(improvement)) seconds faster on average"
        } else {
            let decline = difference * 60
            return "Recent times are \(Int(decline)) seconds slower on average"
        }
    }
}

#Preview {
    let sampleData = [
        PerformanceData(venueRecord: VenueRecord(venue: "Whiteley parkrun", date: "05/07/2025", time: "24:24")),
        PerformanceData(venueRecord: VenueRecord(venue: "Ganger Farm parkrun", date: "28/06/2025", time: "24:08")),
        PerformanceData(venueRecord: VenueRecord(venue: "Keswick parkrun", date: "21/06/2025", time: "27:39")),
        PerformanceData(venueRecord: VenueRecord(venue: "Ganger Farm parkrun", date: "14/06/2025", time: "25:21")),
        PerformanceData(venueRecord: VenueRecord(venue: "Ganger Farm parkrun", date: "07/06/2025", time: "25:14"))
    ]
    
    PerformanceTimelineChart(performanceData: sampleData)
        .padding()
}
