//
//  FamilyTabView.swift
//  PR Bar Code
//
//  Created by Claude Code on 15/06/2025.
//

import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins

struct FamilyTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var parkrunInfoList: [ParkrunInfo]
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var showAddUser = false
    @State private var showUserSelection = false
    @State private var selectedUserForQR: ParkrunInfo?
    
    private var availableUsers: [ParkrunInfo] {
        parkrunInfoList.sorted { $0.createdDate < $1.createdDate }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if parkrunInfoList.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.adaptiveParkrunGreen)
                        
                        Text("No Family Members")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Add family members and friends to track their parkrun progress together.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showAddUser = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add First Member")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.adaptiveParkrunGreen)
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    // Results table
                    List {
                        ForEach(availableUsers, id: \.parkrunID) { user in
                            FamilyUserCard(
                                user: user,
                                onTapQR: {
                                    selectedUserForQR = user
                                },
                                onDelete: {
                                    deleteUser(user)
                                },
                                onSetDefault: {
                                    setDefaultUser(user)
                                },
                                canDelete: parkrunInfoList.count > 1
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Family & Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !parkrunInfoList.isEmpty {
                            Button(action: {
                                showUserSelection = true
                            }) {
                                Image(systemName: "person.2.circle")
                                    .foregroundColor(.adaptiveParkrunGreen)
                            }
                        }
                        
                        Button(action: {
                            showAddUser = true
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.adaptiveParkrunGreen)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddUser) {
            AddUserView(isPresented: $showAddUser) { parkrunID in
                addNewUser(parkrunID: parkrunID)
            }
        }
        .sheet(isPresented: $showUserSelection) {
            UserSelectionView(
                users: availableUsers,
                currentUser: availableUsers.first(where: { $0.isDefault }),
                isPresented: $showUserSelection,
                onUserSelected: { user in
                    // Just close the sheet, no switching needed in Family view
                },
                onDeleteUser: { user in
                    deleteUser(user)
                },
                onSetDefault: { user in
                    setDefaultUser(user)
                }
            )
        }
        .sheet(item: $selectedUserForQR, onDismiss: {
            selectedUserForQR = nil
        }) { user in
            FamilyQRCodeView(user: user, isPresented: Binding(
                get: { selectedUserForQR != nil },
                set: { _ in selectedUserForQR = nil }
            ))
        }
        .onAppear {
            // Data correction: Fix corrupted names (one-time fix)
            fixCorruptedUserNames()
        }
    }
    
    // MARK: - Functions
    
    private func fixCorruptedUserNames() {
        var needsSave = false
        
        // Fix known data corruption: A79156 should be Matt GARDNER
        for user in parkrunInfoList {
            if user.parkrunID == "A79156" && user.name != "Matt GARDNER" {
                print("DEBUG - Fixing corrupted name for A79156: '\(user.name)' -> 'Matt GARDNER'")
                user.name = "Matt GARDNER"
                user.updateDisplayName()
                needsSave = true
            }
            
            // Set correct default user: A79156 (Matt) should be default
            if user.parkrunID == "A79156" && !user.isDefault {
                print("DEBUG - Setting A79156 (Matt) as default user")
                // First remove default from all users
                for otherUser in parkrunInfoList {
                    otherUser.isDefault = false
                }
                user.isDefault = true
                needsSave = true
            }
        }
        
        if needsSave {
            do {
                try modelContext.save()
                print("DEBUG - Data corruption fixed and saved")
            } catch {
                print("DEBUG - Failed to save data correction: \(error)")
            }
        }
    }
    
    private func addNewUser(parkrunID: String) {
        // Create new user (not default by default - only first user is automatically default)
        let isFirstUser = parkrunInfoList.isEmpty
        
        let newUser = ParkrunInfo(
            parkrunID: parkrunID,
            name: "", // Will be filled when user saves
            homeParkrun: "",
            country: Country.unitedKingdom.rawValue,
            isDefault: isFirstUser // Only first user is default automatically
        )
        
        modelContext.insert(newUser)
        
        do {
            try modelContext.save()
            
            print("DEBUG - Added new user \(parkrunID), now fetching data...")
            // Fetch data for the new user in background
            fetchParkrunnerName(for: newUser)
            
            print("Added new user with ID: \(parkrunID)")
        } catch {
            print("Failed to add new user: \(error)")
        }
    }
    
    private func deleteUser(_ user: ParkrunInfo) {
        // Don't allow deleting the last user
        guard parkrunInfoList.count > 1 else {
            print("Cannot delete the last user")
            return
        }
        
        let wasDefault = user.isDefault
        
        // Cancel notifications for this user
        notificationManager.cancelResultNotifications(for: user.parkrunID)
        
        // Delete the user
        modelContext.delete(user)
        
        do {
            try modelContext.save()
            
            // If the deleted user was the default, make the first remaining user default
            if wasDefault, let firstUser = parkrunInfoList.first {
                firstUser.isDefault = true
                try modelContext.save()
            }
            
            print("Deleted user: \(user.displayName)")
        } catch {
            print("Failed to delete user: \(error)")
        }
    }
    
    private func setDefaultUser(_ user: ParkrunInfo) {
        // Remove default flag from all users
        for parkrunUser in parkrunInfoList {
            parkrunUser.isDefault = false
        }
        
        // Set the chosen user as default
        user.isDefault = true
        
        // Save changes
        do {
            try modelContext.save()
            print("Set default user: \(user.displayName)")
        } catch {
            print("Failed to set default user: \(error)")
        }
    }
    
    private func fetchParkrunnerName(for user: ParkrunInfo) {
        // Extract numeric part from ID (remove 'A' prefix)
        let numericId = String(user.parkrunID.dropFirst())
        
        let urlString = "https://www.parkrun.org.uk/parkrunner/\(numericId)/"
        print("DEBUG - Starting fetch for \(user.parkrunID) at URL: \(urlString)")
        guard let url = URL(string: urlString) else { 
            print("DEBUG - Invalid URL for \(user.parkrunID): \(urlString)")
            return 
        }
        
        // Create request with proper headers to avoid 403
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error for \(user.parkrunID): \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("HTTP Error for \(user.parkrunID): \(httpResponse.statusCode)")
                return
            }
            
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                print("Failed to decode HTML data for \(user.parkrunID)")
                return
            }
            
            print("Successfully fetched HTML for ID: \(user.parkrunID)")
            
            // Parse the HTML to extract all information
            let extractedData = extractParkrunnerDataFromHTML(htmlString)
            
            print("DEBUG - Extracted data for \(user.parkrunID):")
            print("  - Name: \(extractedData.name ?? "nil")")
            print("  - Total runs: \(extractedData.totalRuns ?? "nil")")
            print("  - Last date: \(extractedData.lastDate ?? "nil")")
            print("  - Last time: \(extractedData.lastTime ?? "nil")")
            print("  - Last event: \(extractedData.lastEvent ?? "nil")")
            print("  - Last event URL: \(extractedData.lastEventURL ?? "nil")")
            
            DispatchQueue.main.async {
                print("DEBUG - Updating user data for \(user.parkrunID)")
                
                // Update user data
                if let name = extractedData.name {
                    print("DEBUG - Setting name: '\(user.name)' -> '\(name)'")
                    user.name = name
                }
                if let totalRuns = extractedData.totalRuns {
                    print("DEBUG - Setting totalParkruns: '\(user.totalParkruns ?? "nil")' -> '\(totalRuns)'")
                    user.totalParkruns = totalRuns
                }
                if let lastDate = extractedData.lastDate {
                    print("DEBUG - Setting lastParkrunDate: '\(user.lastParkrunDate ?? "nil")' -> '\(lastDate)'")
                    user.lastParkrunDate = lastDate
                }
                if let lastTime = extractedData.lastTime {
                    print("DEBUG - Setting lastParkrunTime: '\(user.lastParkrunTime ?? "nil")' -> '\(lastTime)'")
                    user.lastParkrunTime = lastTime
                }
                if let lastEvent = extractedData.lastEvent {
                    print("DEBUG - Setting lastParkrunEvent: '\(user.lastParkrunEvent ?? "nil")' -> '\(lastEvent)'")
                    user.lastParkrunEvent = lastEvent
                }
                if let lastEventURL = extractedData.lastEventURL {
                    print("DEBUG - Setting lastParkrunEventURL: '\(user.lastParkrunEventURL ?? "nil")' -> '\(lastEventURL)'")
                    user.lastParkrunEventURL = lastEventURL
                }
                
                // Update display name
                user.updateDisplayName()
                
                // Save the updated data
                do {
                    try self.modelContext.save()
                    print("DEBUG - Successfully saved data for user: \(user.parkrunID)")
                    print("DEBUG - Final saved values:")
                    print("  - Name: '\(user.name)'")
                    print("  - TotalParkruns: '\(user.totalParkruns ?? "nil")'")
                    print("  - LastDate: '\(user.lastParkrunDate ?? "nil")'")
                    print("  - LastTime: '\(user.lastParkrunTime ?? "nil")'")
                    print("  - LastEvent: '\(user.lastParkrunEvent ?? "nil")'")
                    print("  - LastEventURL: '\(user.lastParkrunEventURL ?? "nil")'")
                } catch {
                    print("DEBUG - Failed to save updated data for user \(user.parkrunID): \(error)")
                }
            }
        }.resume()
    }
    
    internal func extractParkrunnerDataFromHTML(_ html: String) -> (name: String?, totalRuns: String?, lastDate: String?, lastTime: String?, lastEvent: String?, lastEventURL: String?) {
        var name: String?
        var totalRuns: String?
        var lastDate: String?
        var lastTime: String?
        var lastEvent: String?
        var lastEventURL: String?
        
        print("DEBUG - Starting HTML parsing, HTML length: \(html.count)")
        
        // Extract runner name from h2 tag
        if let nameRegex = try? NSRegularExpression(pattern: #"<h2>([^<]+?)\s*<span[^>]*title="parkrun ID"[^>]*>"#, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let nameMatches = nameRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = nameMatches.first, let nameRange = Range(match.range(at: 1), in: html) {
                name = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("DEBUG - Extracted name: '\(name ?? "nil")'")
            }
        }
        
        // Extract total parkruns
        if let totalRegex = try? NSRegularExpression(pattern: #"(\d+)\s+parkruns?(?:\s+&\s+\d+\s+junior\s+parkrun)?\s+total"#, options: [.caseInsensitive]) {
            let totalMatches = totalRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = totalMatches.first, let totalRange = Range(match.range(at: 1), in: html) {
                totalRuns = String(html[totalRange])
                print("DEBUG - Extracted totalRuns: '\(totalRuns ?? "nil")'")
            }
        }
        
        // Look for event name in first <td><a> combination  
        if let eventRegex = try? NSRegularExpression(pattern: #"<td><a[^>]*>([^<]+parkrun[^<]*)</a></td>"#, options: [.caseInsensitive]) {
            let eventMatches = eventRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = eventMatches.first, let eventRange = Range(match.range(at: 1), in: html) {
                lastEvent = String(html[eventRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("DEBUG - Extracted lastEvent: '\(lastEvent ?? "nil")'")
            }
        }
        
        // Look for date pattern DD/MM/YYYY
        if let dateRegex = try? NSRegularExpression(pattern: #"(\d{2}/\d{2}/\d{4})"#, options: []) {
            let dateMatches = dateRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = dateMatches.first, let dateRange = Range(match.range(at: 1), in: html) {
                lastDate = String(html[dateRange])
                print("DEBUG - Extracted lastDate: '\(lastDate ?? "nil")'")
            }
        }
        
        // Look for time pattern MM:SS in table
        if let timeRegex = try? NSRegularExpression(pattern: #"<td>(\d{2}:\d{2})</td>"#, options: []) {
            let timeMatches = timeRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = timeMatches.first, let timeRange = Range(match.range(at: 1), in: html) {
                lastTime = String(html[timeRange])
                print("DEBUG - Extracted lastTime: '\(lastTime ?? "nil")'")
            }
        }
        
        // Look for event URL - first try full URLs
        if let urlRegex = try? NSRegularExpression(pattern: #"<td><a href="(https://www\.parkrun\.(?:org\.uk|com|us|au|org\.nz|co\.za|it|se|dk|pl|ie|ca|fi|fr|sg|de|no|ru|my)/[^/]+/results/\d+/)"[^>]*>(?:[^<]+|\d{2}/\d{2}/\d{4})</a></td>"#, options: [.caseInsensitive]) {
            let urlMatches = urlRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = urlMatches.first, let urlRange = Range(match.range(at: 1), in: html) {
                lastEventURL = String(html[urlRange])
                print("DEBUG - Extracted lastEventURL: '\(lastEventURL ?? "nil")'")
            }
        }
        
        // If no full URL found, look for relative URLs and convert them
        if lastEventURL == nil {
            if let relativeUrlRegex = try? NSRegularExpression(pattern: #"<td><a href="/parkrun/([^/]+/results/\d+/)"[^>]*>(?:[^<]+|\d{2}/\d{2}/\d{4})</a></td>"#, options: [.caseInsensitive]) {
                let relativeMatches = relativeUrlRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                if let match = relativeMatches.first, let urlRange = Range(match.range(at: 1), in: html) {
                    let pathWithoutParkrun = String(html[urlRange])
                    lastEventURL = "https://www.parkrun.org.uk/" + pathWithoutParkrun
                    print("DEBUG - Extracted lastEventURL from relative: '\(lastEventURL ?? "nil")'")
                }
            }
        }
        
        // If we're missing any data, try the complex table pattern as fallback
        if lastEvent == nil || lastDate == nil || lastTime == nil {
            print("DEBUG - Trying complex table pattern as fallback")
            if let recentRegex = try? NSRegularExpression(pattern: #"<td><a href="[^"]*"[^>]*>([^<]+)</a></td><td><a href="[^"]*results/\d+/"[^>]*>(\d{2}/\d{2}/\d{4})</a></td><td>\d+</td><td>\d+</td><td>([^<]+)</td>"#, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let recentMatches = recentRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                if let match = recentMatches.first {
                    if lastEvent == nil, let eventRange = Range(match.range(at: 1), in: html) {
                        lastEvent = String(html[eventRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        print("DEBUG - Extracted lastEvent: '\(lastEvent ?? "nil")' using complex pattern")
                    }
                    if lastDate == nil, let dateRange = Range(match.range(at: 2), in: html) {
                        lastDate = String(html[dateRange])
                        print("DEBUG - Extracted lastDate: '\(lastDate ?? "nil")' using complex pattern")
                    }
                    if lastTime == nil, let timeRange = Range(match.range(at: 3), in: html) {
                        lastTime = String(html[timeRange])
                        print("DEBUG - Extracted lastTime: '\(lastTime ?? "nil")' using complex pattern")
                    }
                }
            }
        }
        
        return (name, totalRuns, lastDate, lastTime, lastEvent, lastEventURL)
    }
}

// MARK: - Family User Card

struct FamilyUserCard: View {
    let user: ParkrunInfo
    let onTapQR: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void
    let canDelete: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Name row - spans full width
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(user.name.isEmpty ? user.parkrunID : user.name)
                            .font(.body)
                            .fontWeight(user.isDefault ? .semibold : .medium)
                            .foregroundColor(.primary)
                        
                        if user.isDefault {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        if !user.name.isEmpty {
                            Text(user.parkrunID)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let totalRuns = user.totalParkruns, !totalRuns.isEmpty {
                            if !user.name.isEmpty {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("\(totalRuns) runs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // QR button
                Button(action: onTapQR) {
                    Image(systemName: "qrcode")
                        .font(.title2)
                        .foregroundColor(.adaptiveParkrunGreen)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Data row - event, date, time
            if user.lastParkrunEvent != nil || user.lastParkrunDate != nil || user.lastParkrunTime != nil {
                HStack {
                    // Last Event
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Event")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        if let lastEvent = user.lastParkrunEvent, !lastEvent.isEmpty {
                            Text(lastEvent)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Date
                    VStack(alignment: .center, spacing: 2) {
                        Text("Date")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        if let lastDate = user.lastParkrunDate, !lastDate.isEmpty {
                            Text(lastDate)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: true, vertical: false)
                                .lineLimit(1)
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(minWidth: 80, maxWidth: 100, alignment: .center)
                    
                    // Time
                    VStack(alignment: .center, spacing: 2) {
                        Text("Time")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        if let lastTime = user.lastParkrunTime, !lastTime.isEmpty {
                            Text(lastTime)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.adaptiveParkrunGreen)
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 60, alignment: .center)
                }
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if canDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if !user.isDefault {
                Button(action: onSetDefault) {
                    Label("Set Default", systemImage: "star")
                }
                .tint(.orange)
            }
        }
    }
}

// MARK: - Family QR Code View

struct FamilyQRCodeView: View {
    let user: ParkrunInfo
    @Binding var isPresented: Bool
    @State private var selectedCodeType: Int = 0 // 0 = QR Code, 1 = Barcode
    
    private let context = CIContext()
    private let qrCodeFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User info
                VStack(spacing: 8) {
                    Text(user.name.isEmpty ? user.parkrunID : user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.adaptiveParkrunGreen)
                    
                    if !user.name.isEmpty {
                        Text(user.parkrunID)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    if let totalRuns = user.totalParkruns, !totalRuns.isEmpty {
                        Text("\(totalRuns) total parkruns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.adaptiveCardBackground)
                .cornerRadius(12)
                
                // Code type picker
                Picker("Code Type", selection: $selectedCodeType) {
                    Text("QR Code").tag(0)
                    Text("Barcode").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // QR Code or Barcode
                VStack {
                    if selectedCodeType == 0 {
                        if let qrImage = generateQRCode(from: user.parkrunID) {
                            Image(uiImage: qrImage)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    } else {
                        if let barcodeImage = generateBarcode(from: user.parkrunID) {
                            Image(uiImage: barcodeImage)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 300, height: 100)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - QR & Barcode Generation
    private func generateQRCode(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }
        qrCodeFilter.message = Data(string.utf8)
        guard let ciImage = qrCodeFilter.outputImage else { return nil }
        return convertToUIImage(from: ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10)))
    }

    private func generateBarcode(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }
        barcodeFilter.message = Data(string.utf8)
        guard let ciImage = barcodeFilter.outputImage else { return nil }
        return convertToUIImage(from: ciImage.transformed(by: CGAffineTransform(scaleX: 2, y: 2)))
    }

    private func convertToUIImage(from ciImage: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    do {
        let previewContainer = try ModelContainer(for: ParkrunInfo.self, configurations: ModelConfiguration())
        let context = previewContainer.mainContext
        
        // Insert sample data for preview
        let user1 = ParkrunInfo(parkrunID: "A12345", name: "John Doe", homeParkrun: "Southampton", country: Country.unitedKingdom.rawValue, totalParkruns: "25", lastParkrunDate: "14/06/2025", lastParkrunTime: "22:30", lastParkrunEvent: "Southampton parkrun", isDefault: true)
        let user2 = ParkrunInfo(parkrunID: "A67890", name: "Jane Smith", homeParkrun: "Portsmouth", country: Country.unitedKingdom.rawValue, totalParkruns: "15", lastParkrunDate: "07/06/2025", lastParkrunTime: "25:45", lastParkrunEvent: "Portsmouth parkrun")
        
        context.insert(user1)
        context.insert(user2)
        
        return FamilyTabView()
            .modelContainer(previewContainer)
            .environmentObject(NotificationManager.shared)
    } catch {
        return Text("Failed to create preview: \(error)")
    }
}