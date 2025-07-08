//
//  VolunteerContributionChart.swift
//  PR Bar Code
//
//  Created by Claude Code on 07/07/2025.
//

import SwiftUI
import Charts

struct VolunteerContributionChart: View {
    let volunteerStats: [VolunteerStats]
    @State private var selectedRole: VolunteerStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Volunteer Contributions")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Your community service beyond running")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if volunteerStats.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "hands.and.sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No volunteer data available")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Volunteer contributions will appear here once data is available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            } else {
                HStack(spacing: 20) {
                    // Polar area chart (simplified as pie chart)
                    Chart(volunteerStats, id: \.role) { stats in
                        SectorMark(
                            angle: .value("Count", stats.count),
                            innerRadius: .ratio(0.4),
                            angularInset: 2
                        )
                        .foregroundStyle(stats.color)
                        .opacity(selectedRole == nil || selectedRole?.role == stats.role ? 1.0 : 0.5)
                    }
                    .frame(height: 200)
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            if let selectedRole = selectedRole {
                                VStack(spacing: 2) {
                                    Text("\(selectedRole.count)")
                                        .font(.title2.bold())
                                        .foregroundColor(.primary)
                                    Text("times")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(selectedRole.percentage, specifier: "%.0f")%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
                            } else {
                                VStack(spacing: 2) {
                                    Text("\(totalVolunteerOccasions)")
                                        .font(.title2.bold())
                                        .foregroundColor(.primary)
                                    Text("total")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("occasions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
                            }
                        }
                    }
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(volunteerStats, id: \.role) { stats in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(stats.color)
                                    .frame(width: 12, height: 12)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stats.role)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(2)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(stats.count) times (\(stats.percentage, specifier: "%.0f")%)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedRole = selectedRole?.role == stats.role ? nil : stats
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Selected role details
                if let selectedRole = selectedRole {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Role Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Role")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(selectedRole.role)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .center, spacing: 2) {
                                    Text("Occasions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(selectedRole.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Venues")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(selectedRole.venues.count)")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            if !selectedRole.venues.isEmpty {
                                HStack {
                                    Text("Venues:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(selectedRole.venues.joined(separator: ", "))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(2)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
                
                // Volunteer insights
                VStack(alignment: .leading, spacing: 8) {
                    Text("Volunteer Profile")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        InsightRow(text: "Total of \(totalVolunteerOccasions) volunteer occasions across \(uniqueRoles) different roles")
                        
                        if let mostFrequent = volunteerStats.max(by: { $0.count < $1.count }) {
                            InsightRow(text: "Most frequent role: \(mostFrequent.role) (\(mostFrequent.count) times)")
                        }
                        
                        let multipleRoleStats = volunteerStats.filter { $0.count > 1 }
                        if multipleRoleStats.count > 1 {
                            let roleNames = multipleRoleStats.map { "\($0.role) (\($0.count) times)" }.joined(separator: ", ")
                            InsightRow(text: "Regular contributor in: \(roleNames)")
                        }
                        
                        InsightRow(text: "Demonstrates commitment to parkrun community beyond just running")
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private var totalVolunteerOccasions: Int {
        volunteerStats.reduce(0) { $0 + $1.count }
    }
    
    private var uniqueRoles: Int {
        volunteerStats.count
    }
}

#Preview {
    // Sample with data
    let sampleStats = [
        VolunteerStats(role: "Pre-event Setup", count: 6, venues: ["Whiteley"], percentage: 42.9),
        VolunteerStats(role: "Timekeeper", count: 4, venues: ["Whiteley", "Netley Abbey"], percentage: 28.6),
        VolunteerStats(role: "Marshal", count: 2, venues: ["Netley Abbey"], percentage: 14.3),
        VolunteerStats(role: "Others", count: 2, venues: ["Whiteley"], percentage: 14.3)
    ]
    
    // Empty state
    let emptyStats: [VolunteerStats] = []
    
    VStack(spacing: 30) {
        VolunteerContributionChart(volunteerStats: sampleStats)
        
        Divider()
        
        VolunteerContributionChart(volunteerStats: emptyStats)
    }
    .padding()
}