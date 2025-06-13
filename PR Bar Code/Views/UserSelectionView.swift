//
//  UserSelectionView.swift
//  PR Bar Code
//
//  Created by Claude Code on 13/06/2025.
//

import SwiftUI

struct UserSelectionView: View {
    let users: [ParkrunInfo]
    let currentUser: ParkrunInfo?
    @Binding var isPresented: Bool
    let onUserSelected: (ParkrunInfo) -> Void
    let onDeleteUser: (ParkrunInfo) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(users, id: \.parkrunID) { user in
                    UserRowView(
                        user: user,
                        isSelected: user.isSelected,
                        onTap: {
                            onUserSelected(user)
                            isPresented = false
                        },
                        onDelete: {
                            onDeleteUser(user)
                        },
                        canDelete: users.count > 1
                    )
                }
            }
            .navigationTitle("Select User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct UserRowView: View {
    let user: ParkrunInfo
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let canDelete: Bool
    
    var body: some View {
        HStack {
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.body)
                            .fontWeight(isSelected ? .semibold : .medium)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("ID: \(user.parkrunID)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let totalRuns = user.totalParkruns, !totalRuns.isEmpty {
                                Text("• \(totalRuns) runs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.body)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    UserSelectionView(
        users: [],
        currentUser: nil,
        isPresented: .constant(true),
        onUserSelected: { _ in },
        onDeleteUser: { _ in }
    )
}