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
        // Show last 10 runs for better mobile display
        Array(performanceData.prefix(10))
    }
    
    private var yAxisRange: ClosedRange<Double> {
        guard !displayData.isEmpty else { return 20...30 }
        
        let minTime = displayData.map { $0.timeInMinutes }.min() ?? 20
        let maxTime = displayData.map { $0.timeInMinutes }.max() ?? 30
        let padding = (maxTime - minTime) * 0.1
        
        return (minTime - padding)...(maxTime + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Performance Timeline")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Your recent parkrun times and trends")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Chart(displayData.reversed(), id: \.id) { data in
                LineMark(
                    x: .value("Date", formatDateForChart(data.date)),
                    y: .value("Time", data.timeInMinutes)
                )
                .foregroundStyle(Color.adaptiveParkrunGreen)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("Date", formatDateForChart(data.date)),
                    y: .value("Time", data.timeInMinutes)
                )
                .foregroundStyle(Color.adaptiveParkrunGreen)
                .symbolSize(selectedDataPoint?.id == data.id ? 80 : 50)
                
                if let selectedDataPoint = selectedDataPoint, selectedDataPoint.id == data.id {
                    RuleMark(x: .value("Selected Date", formatDateForChart(data.date)))
                        .foregroundStyle(Color.adaptiveParkrunGreen.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
            }
            .frame(height: 200)
            .chartYScale(domain: yAxisRange)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.caption2)
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
            .chartAngleSelection(value: .constant(nil))
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