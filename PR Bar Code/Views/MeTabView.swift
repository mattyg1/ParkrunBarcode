//
//  MeTabView.swift
//  PR Bar Code
//
//  Created by Claude Code on 15/06/2025.
//

import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins
import WatchConnectivity

struct MeTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var parkrunInfoList: [ParkrunInfo]
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var inputText: String = ""
    @State private var name: String = ""
    @State private var homeParkrun: String = ""
    @State private var selectedCountryCode: Int = Country.unitedKingdom.rawValue
    @State private var isEditing: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var selectedCodeType: Int = 0 // 0 = QR Code, 1 = Barcode
    @State private var isLoadingName: Bool = false
    @State private var showConfirmationDialog: Bool = false
    @State private var totalParkruns: String = ""
    @State private var lastParkrunDate: String = ""
    @State private var lastParkrunTime: String = ""
    @State private var lastParkrunEvent: String = ""
    @State private var lastParkrunEventURL: String = ""
    @State private var watchSyncStatus: WatchSyncStatus = .idle
    @State private var showOnboarding: Bool = false
    
    private let context = CIContext()
    private let qrCodeFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()
    
    // Get default user only
    private var defaultUser: ParkrunInfo? {
        if let defaultUser = parkrunInfoList.first(where: { $0.isDefault }) {
            return defaultUser
        }
        return parkrunInfoList.first
    }
    
    private var confirmationMessage: String {
        var message = "Please confirm your details:\n\nParkrun ID: \(inputText)"
        
        if !name.isEmpty {
            message += "\nName: \(name)"
        }
        
        if !totalParkruns.isEmpty {
            message += "\nTotal Parkruns: \(totalParkruns)"
        }
        
        if !lastParkrunDate.isEmpty && !lastParkrunTime.isEmpty && !lastParkrunEvent.isEmpty {
            message += "\nLast Parkrun: \(lastParkrunEvent)"
            message += "\nDate: \(lastParkrunDate), Time: \(lastParkrunTime)"
        }
        
        return message
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    if isEditing || defaultUser == nil {
                        // Personal Information Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personal Information")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.adaptiveParkrunGreen)
                            
                            personalInfoSection
                        }
                        .cardStyle()
                        .transition(AnimationConstants.cardTransition)
                        
                        // QR Code Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Code")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.adaptiveParkrunGreen)
                            
                            qrCodeAndBarcodeSection
                        }
                        .cardStyle()
                        .transition(AnimationConstants.cardTransition)
                        
                        // Send to Watch Button
                        sendToWatchSection
                            .cardStyle()
                            .transition(AnimationConstants.cardTransition)
                        
                        // Watch Sync Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Watch Sync")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.adaptiveParkrunGreen)
                            
                            watchSyncIndicator
                        }
                        .cardStyle()
                        .transition(AnimationConstants.cardTransition)
                        
                    } else {
                        // Display Default User Data
                        VStack(spacing: 20) {
                            // Personal Information Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("My Information")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.adaptiveParkrunGreen)
                                
                                personalInfoSection
                            }
                            .cardStyle()
                            
                            // QR Code Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("My QR Code")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.adaptiveParkrunGreen)
                                
                                qrCodeAndBarcodeSection
                            }
                            .cardStyle()
                            
                            // Send to Watch Button
                            sendToWatchSection
                                .cardStyle()
                            
                            // Watch Sync Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Watch Sync")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.adaptiveParkrunGreen)
                                
                                watchSyncIndicator
                            }
                            .cardStyle()
                        }
                        .transition(AnimationConstants.slideTransition)
                    }
                }
                .padding()
                .animation(AnimationConstants.springAnimation, value: isEditing)
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            withAnimation(AnimationConstants.springAnimation) {
                                cancelEdit()
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            withAnimation(AnimationConstants.springAnimation) {
                                // Refresh user details and show confirmation dialog without saving
                                fetchParkrunnerName(id: inputText) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                        self.showConfirmationDialog = true
                                    }
                                }
                            }
                        }
                    } else {
                        Button("Edit") {
                            withAnimation(AnimationConstants.springAnimation) {
                                startEdit()
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Invalid Input"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Confirm Details", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
            Button("Save") {
                saveParkrunInfo()
            }
            Button("Cancel", role: .cancel) {
                // Revert Parkrun details back to original
                loadInitialData()
            }
        } message: {
            Text(confirmationMessage)
        }
        .onAppear {
            loadInitialData()
            WatchSessionManager.shared.startSession()
            checkForOnboarding()
            refreshEventDataIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh data when app comes back to foreground
            refreshEventDataIfNeeded()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SetParkrunID"))) { notification in
            if let parkrunID = notification.object as? String {
                inputText = parkrunID
                // Clear existing data and trigger API lookup
                name = ""
                totalParkruns = ""
                lastParkrunDate = ""
                lastParkrunTime = ""
                lastParkrunEvent = ""
                lastParkrunEventURL = ""
                
                // Trigger edit mode to show the new ID
                isEditing = true
                
                // Fetch data for the ID
                fetchParkrunnerName(id: parkrunID)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SetParkrunIDWithConfirmation"))) { notification in
            if let parkrunID = notification.object as? String {
                inputText = parkrunID
                // Clear existing data and trigger API lookup
                name = ""
                totalParkruns = ""
                lastParkrunDate = ""
                lastParkrunTime = ""
                lastParkrunEvent = ""
                lastParkrunEventURL = ""
                
                // Trigger edit mode to show the new ID
                isEditing = true
                
                // Fetch data for the ID and show confirmation dialog when done
                fetchParkrunnerName(id: parkrunID) {
                    // Show confirmation dialog after API call completes
                    print("Onboarding: API lookup completed, showing confirmation dialog")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.showConfirmationDialog = true
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshParkrunData"))) { notification in
            if let parkrunID = notification.object as? String, parkrunID == inputText {
                // Refresh data when notification is tapped
                print("Refreshing parkrun data from notification tap")
                refreshEventDataIfNeeded()
            }
        }
    }
    
    // MARK: - View Components (reuse from original QRCodeView)
    // [Copy the relevant view components from QRCodeView.swift]
    
    // MARK: - Personal Info Section
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Parkrun ID")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Parkrun ID (e.g., A12345)", text: $inputText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.asciiCapable)
                            
                            if isLoadingName {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil {
                                if !name.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "magnifyingglass.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            } else if !inputText.isEmpty {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(name.isEmpty ? "Auto-filled from Parkrun ID" : name)
                            .font(.body)
                            .foregroundColor(name.isEmpty ? .secondary : .primary)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(6)
                    }
                    
                    // Show total parkruns if available
                    if !totalParkruns.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Parkruns")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(totalParkruns)
                                .font(.body)
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(6)
                        }
                    }
                    
                    // Show last parkrun table if data is available
                    if !lastParkrunDate.isEmpty && !lastParkrunTime.isEmpty && !lastParkrunEvent.isEmpty {
                        lastParkrunSection
                    }
                }
                .transition(AnimationConstants.fadeTransition)
            } else {
                // Read-only display
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Parkrun ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            openParkrunProfile()
                        }) {
                            HStack {
                                Text(inputText.isEmpty ? "Not set" : inputText)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                if !inputText.isEmpty {
                                    Image(systemName: "safari")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(inputText.isEmpty)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Parkruns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(totalParkruns.isEmpty ? "Not set" : totalParkruns)
                            .font(.body)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(6)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        openParkrunProfile()
                    }) {
                        HStack {
                            Text(name.isEmpty ? "Not set" : name)
                                .font(.body)
                                .foregroundColor(name.isEmpty ? .secondary : .blue)
                            
                            if !name.isEmpty && !inputText.isEmpty {
                                Image(systemName: "safari")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(name.isEmpty || inputText.isEmpty)
                }
                
                if !lastParkrunDate.isEmpty && !lastParkrunTime.isEmpty && !lastParkrunEvent.isEmpty {
                    lastParkrunSection
                }
            }
        }
        .padding(10)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(10)
        .shadow(radius: 2)
        .frame(maxWidth: .infinity)
    }
    
    private var lastParkrunSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Last Parkrun")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Event")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Date")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 75, alignment: .center)
                    Text("Time")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .center)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.quaternarySystemFill))
                
                // Data row
                HStack(alignment: .center) {
                    Button(action: {
                        openEventResults()
                    }) {
                        HStack {
                            Text(lastParkrunEvent)
                                .font(.body)
                                .foregroundColor(.blue)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if !lastParkrunEventURL.isEmpty {
                                Image(systemName: "safari")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(lastParkrunEventURL.isEmpty)
                    
                    Text(lastParkrunDate)
                        .font(.caption)
                        .frame(width: 75, alignment: .center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(lastParkrunTime)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(width: 60, alignment: .center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemBackground))
            }
            .cornerRadius(8)
        }
    }
    
    // MARK: - QR Code and Barcode Section
    private var qrCodeAndBarcodeSection: some View {
        VStack(spacing: 16) {
            Picker("Code Type", selection: $selectedCodeType) {
                Text("QR Code").tag(0)
                Text("Barcode").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack {
                if selectedCodeType == 0 {
                    CodeSectionView(
                        title: "",
                        image: generateQRCode(from: inputText),
                        size: CGSize(width: 200, height: 200)
                    )
                } else {
                    CodeSectionView(
                        title: "",
                        image: generateBarcode(from: inputText),
                        size: CGSize(width: 300, height: 100)
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(10)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(10)
        .shadow(radius: 2)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Watch Sync Indicator
    private var watchSyncIndicator: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                if WCSession.default.isReachable {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Watch Connected")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Watch Not Connected")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            withAnimation(AnimationConstants.springAnimation) {
                                openWatchQRCode()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "qrcode")
                                    .font(.caption)
                                Text("Open 5K QR Code on Watch")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .disabled(inputText.isEmpty)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(Color.adaptiveCardBackground)
    }
    
    // MARK: - Send to Watch Section
    private var sendToWatchSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(AnimationConstants.springAnimation) {
                    sendToWatch()
                }
            }) {
                HStack(spacing: 8) {
                    if watchSyncStatus == .sending {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "applewatch")
                            .font(.title3)
                    }
                    
                    Text(watchSyncStatus == .sending ? "Sending..." : "Send to Watch")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(watchSyncStatus == .sending ? Color.gray : Color.adaptiveParkrunGreen)
                .cornerRadius(12)
            }
            .disabled(watchSyncStatus == .sending || inputText.isEmpty)
            .animation(AnimationConstants.springAnimation, value: watchSyncStatus)
        }
    }
    
    // MARK: - Functions
    private func loadInitialData() {
        print("DEBUG - MeTab loadInitialData: Found \(parkrunInfoList.count) users")
        
        if let savedInfo = defaultUser {
            inputText = savedInfo.parkrunID
            name = savedInfo.name
            homeParkrun = savedInfo.homeParkrun
            selectedCountryCode = savedInfo.country ?? Country.unitedKingdom.rawValue
            totalParkruns = savedInfo.totalParkruns ?? ""
            lastParkrunDate = savedInfo.lastParkrunDate ?? ""
            lastParkrunTime = savedInfo.lastParkrunTime ?? ""
            lastParkrunEvent = savedInfo.lastParkrunEvent ?? ""
            lastParkrunEventURL = savedInfo.lastParkrunEventURL ?? ""
            
            print("DEBUG - MeTab loadInitialData: Loaded default user - parkrunID='\(savedInfo.parkrunID)', name='\(savedInfo.name)'")
        } else {
            print("DEBUG - MeTab loadInitialData: No default user found")
        }
    }
    
    private func checkForOnboarding() {
        // Show onboarding if no default user exists
        if defaultUser == nil {
            showOnboarding = true
        }
    }
    
    private func refreshEventDataIfNeeded() {
        // Only refresh if we have a valid parkrun ID and we're not currently editing
        guard !inputText.isEmpty, 
              inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil,
              !isEditing,
              !isLoadingName else {
            print("DEBUG - MeTab refreshEventDataIfNeeded: Skipping refresh - invalid ID or currently editing")
            return
        }
        
        print("DEBUG - MeTab refreshEventDataIfNeeded: Refreshing event data for ID: \(inputText)")
        
        // Refresh the parkrun data in background without showing loading indicators
        fetchParkrunnerName(id: inputText, showLoadingIndicator: false) {
            print("DEBUG - MeTab refreshEventDataIfNeeded: Background refresh completed")
            // Auto-save the updated data
            DispatchQueue.main.async {
                self.saveUpdatedDataSilently()
            }
        }
    }
    
    private func saveUpdatedDataSilently() {
        // Save updated data without triggering UI changes or watch sync
        if let existingInfo = defaultUser {
            existingInfo.name = name
            existingInfo.totalParkruns = totalParkruns.isEmpty ? nil : totalParkruns
            existingInfo.lastParkrunDate = lastParkrunDate.isEmpty ? nil : lastParkrunDate
            existingInfo.lastParkrunTime = lastParkrunTime.isEmpty ? nil : lastParkrunTime
            existingInfo.lastParkrunEvent = lastParkrunEvent.isEmpty ? nil : lastParkrunEvent
            existingInfo.lastParkrunEventURL = lastParkrunEventURL.isEmpty ? nil : lastParkrunEventURL
            
            do {
                try modelContext.save()
                print("DEBUG - MeTab saveUpdatedDataSilently: Successfully saved refreshed data")
            } catch {
                print("DEBUG - MeTab saveUpdatedDataSilently: Failed to save refreshed data: \(error)")
            }
        }
    }

    private func saveParkrunInfo() {
        guard !inputText.isEmpty, inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil else {
            alertMessage = "Parkrun ID must start with 'A' followed by numbers (e.g., A12345)."
            showAlert = true
            return
        }

        completeSave()
    }
    
    private func completeSave() {
        if let existingInfo = defaultUser {
            // Update existing default user
            existingInfo.parkrunID = inputText
            existingInfo.name = name
            existingInfo.homeParkrun = homeParkrun
            existingInfo.country = selectedCountryCode
            existingInfo.totalParkruns = totalParkruns.isEmpty ? nil : totalParkruns
            existingInfo.lastParkrunDate = lastParkrunDate.isEmpty ? nil : lastParkrunDate
            existingInfo.lastParkrunTime = lastParkrunTime.isEmpty ? nil : lastParkrunTime
            existingInfo.lastParkrunEvent = lastParkrunEvent.isEmpty ? nil : lastParkrunEvent
            existingInfo.lastParkrunEventURL = lastParkrunEventURL.isEmpty ? nil : lastParkrunEventURL
            existingInfo.updateDisplayName()
        } else {
            // Create new default user (first user is always default)
            let newInfo = ParkrunInfo(
                parkrunID: inputText, 
                name: name, 
                homeParkrun: homeParkrun, 
                country: selectedCountryCode,
                totalParkruns: totalParkruns.isEmpty ? nil : totalParkruns,
                lastParkrunDate: lastParkrunDate.isEmpty ? nil : lastParkrunDate,
                lastParkrunTime: lastParkrunTime.isEmpty ? nil : lastParkrunTime,
                lastParkrunEvent: lastParkrunEvent.isEmpty ? nil : lastParkrunEvent,
                lastParkrunEventURL: lastParkrunEventURL.isEmpty ? nil : lastParkrunEventURL,
                isDefault: true // This is the default user
            )
            modelContext.insert(newInfo)
        }

        do {
            try modelContext.save()
            isEditing = false
            
            // Set up notifications for the user if enabled
            if notificationManager.hasPermission && notificationManager.isNotificationsEnabled {
                setupNotificationsForCurrentUser()
            }
            
            // Send to watch automatically for default user
            watchSyncStatus = .sending
            WatchSessionManager.shared.sendParkrunID(inputText, userName: name) { success in
                DispatchQueue.main.async {
                    self.watchSyncStatus = success ? .success : .failed
                    
                    // Reset status after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.watchSyncStatus = .idle
                    }
                }
            }
        } catch {
            alertMessage = "Failed to save data. Please try again."
            showAlert = true
        }
    }

    private func startEdit() {
        isEditing = true
    }

    private func cancelEdit() {
        isEditing = false
        loadInitialData()
    }
    
    private func sendToWatch() {
        guard !inputText.isEmpty else {
            alertMessage = "No Parkrun ID available to send."
            showAlert = true
            return
        }
        
        // Send to watch with status tracking
        watchSyncStatus = .sending
        WatchSessionManager.shared.sendParkrunID(inputText, userName: name) { success in
            DispatchQueue.main.async {
                self.watchSyncStatus = success ? .success : .failed
                
                // Reset status after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.watchSyncStatus = .idle
                }
            }
        }
    }
    
    private func setupNotificationsForCurrentUser() {
        guard notificationManager.hasPermission, !inputText.isEmpty else { return }
        
        // Schedule result check notifications if we have parkrun data
        if !lastParkrunDate.isEmpty {
            notificationManager.scheduleBackgroundResultCheck(for: inputText, lastKnownDate: lastParkrunDate)
        }
        
        print("Notifications set up for user: \(name.isEmpty ? inputText : name)")
    }
    
    private func openEventResults() {
        print("DEBUG - openEventResults called with URL: '\(lastParkrunEventURL)'")
        guard !lastParkrunEventURL.isEmpty else {
            print("DEBUG - openEventResults failed: URL is empty")
            alertMessage = "No event results URL available."
            showAlert = true
            return
        }
        
        guard let url = URL(string: lastParkrunEventURL) else {
            alertMessage = "Invalid event results URL."
            showAlert = true
            return
        }
        
        #if os(iOS)
        UIApplication.shared.open(url) { success in
            if !success {
                DispatchQueue.main.async {
                    self.alertMessage = "Unable to open event results page."
                    self.showAlert = true
                }
            }
        }
        #endif
    }
    
    private func openParkrunProfile() {
        guard !inputText.isEmpty, inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil else {
            alertMessage = "Invalid Parkrun ID. Cannot open profile page."
            showAlert = true
            return
        }
        
        // Extract numeric part from ID (remove 'A' prefix)
        let numericId = String(inputText.dropFirst())
        let profileURL = "https://www.parkrun.org.uk/parkrunner/\(numericId)/all/"
        
        guard let url = URL(string: profileURL) else {
            alertMessage = "Unable to create profile URL."
            showAlert = true
            return
        }
        
        #if os(iOS)
        UIApplication.shared.open(url) { success in
            if !success {
                DispatchQueue.main.async {
                    self.alertMessage = "Unable to open parkrun profile page."
                    self.showAlert = true
                }
            }
        }
        #endif
    }
    
    private func openWatchQRCode() {
        guard !inputText.isEmpty else {
            alertMessage = "No Parkrun ID available to display."
            showAlert = true
            return
        }
        
        // Try to open the watch app directly to show QR code
        #if os(iOS)
        let watchAppURL = URL(string: "watch://")
        if let url = watchAppURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if success {
                    print("Successfully opened watch app")
                    // Send the parkrun ID with a special flag to show QR immediately
                    WatchSessionManager.shared.sendParkrunIDForQRDisplay(inputText, userName: name)
                } else {
                    print("Failed to open watch app")
                    DispatchQueue.main.async {
                        self.alertMessage = "Unable to open watch app. Make sure your Apple Watch is nearby and the app is installed."
                        self.showAlert = true
                    }
                }
            }
        } else {
            // Fallback: try to send data and hope watch app opens
            WatchSessionManager.shared.sendParkrunIDForQRDisplay(inputText, userName: name)
            alertMessage = "QR code sent to watch. Please open the Parkrun app on your Apple Watch."
            showAlert = true
        }
        #endif
    }
    
    // MARK: - Parkrun API Functions
    private func fetchParkrunnerName(id: String, showLoadingIndicator: Bool = true, completion: (() -> Void)? = nil) {
        // Extract numeric part from ID (remove 'A' prefix)
        let numericId = String(id.dropFirst())
        
        if showLoadingIndicator {
            isLoadingName = true
        }
        
        let urlString = "https://www.parkrun.org.uk/parkrunner/\(numericId)/"
        guard let url = URL(string: urlString) else {
            if showLoadingIndicator {
                isLoadingName = false
            }
            completion?()
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
            DispatchQueue.main.async {
                if showLoadingIndicator {
                    self.isLoadingName = false
                }
            }
            
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("HTTP Error: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion?()
                    }
                    return
                }
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                print("Failed to decode HTML data")
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            
            print("Successfully fetched HTML for ID: \(id)")
            
            // Parse the HTML to extract all information
            let extractedData = self.extractParkrunnerDataFromHTML(htmlString)
            
            DispatchQueue.main.async {
                if let name = extractedData.name {
                    self.name = name
                    print("Successfully extracted name: \(name)")
                }
                if let totalRuns = extractedData.totalRuns {
                    self.totalParkruns = totalRuns
                    print("Total parkruns: \(totalRuns)")
                }
                if let lastDate = extractedData.lastDate {
                    self.lastParkrunDate = lastDate
                    print("Last parkrun date: \(lastDate)")
                }
                if let lastTime = extractedData.lastTime {
                    self.lastParkrunTime = lastTime
                    print("Last parkrun time: \(lastTime)")
                }
                if let lastEvent = extractedData.lastEvent {
                    self.lastParkrunEvent = lastEvent
                    print("Last parkrun event: \(lastEvent)")
                }
                if let lastEventURL = extractedData.lastEventURL {
                    self.lastParkrunEventURL = lastEventURL
                    print("Last parkrun event URL: \(lastEventURL)")
                    print("DEBUG - lastParkrunEventURL is now set to: '\(self.lastParkrunEventURL)'")
                } else {
                    print("DEBUG - No lastEventURL found in extracted data, lastParkrunEventURL remains: '\(self.lastParkrunEventURL)'")
                }
                completion?()
            }
        }.resume()
    }
    
    private func extractParkrunnerDataFromHTML(_ html: String) -> (name: String?, totalRuns: String?, lastDate: String?, lastTime: String?, lastEvent: String?, lastEventURL: String?) {
        var name: String?
        var totalRuns: String?
        var lastDate: String?
        var lastTime: String?
        var lastEvent: String?
        var lastEventURL: String?
        
        print("DEBUG - Starting HTML parsing, HTML length: \(html.count)")
        
        // Extract runner name from h2 tag: <h2>Matt GARDNER <span style="font-weight: normal;" title="parkrun ID">(A79156)</span></h2>
        if let nameRegex = try? NSRegularExpression(pattern: #"<h2>([^<]+?)\s*<span[^>]*title="parkrun ID"[^>]*>"#, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let nameMatches = nameRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = nameMatches.first, let nameRange = Range(match.range(at: 1), in: html) {
                name = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("DEBUG - Extracted name: '\(name ?? "nil")'")
            } else {
                print("DEBUG - No name match found")
            }
        } else {
            print("DEBUG - Failed to create name regex")
        }
        
        // Extract total parkruns from h3 tag: <h3>279 parkruns total</h3>
        // Try simpler pattern first
        if let totalRegex = try? NSRegularExpression(pattern: #"(\d+)\s+parkruns?\s+total"#, options: [.caseInsensitive]) {
            let totalMatches = totalRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = totalMatches.first, let totalRange = Range(match.range(at: 1), in: html) {
                totalRuns = String(html[totalRange])
                print("DEBUG - Extracted totalRuns: '\(totalRuns ?? "nil")' using simple pattern")
            } else {
                print("DEBUG - No total parkruns match found with simple pattern")
            }
        } else {
            print("DEBUG - Failed to create simple total regex")
        }
        
        // Look for event name in first <td><a> combination  
        if let eventRegex = try? NSRegularExpression(pattern: #"<td><a[^>]*>([^<]+parkrun[^<]*)</a></td>"#, options: [.caseInsensitive]) {
            let eventMatches = eventRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = eventMatches.first, let eventRange = Range(match.range(at: 1), in: html) {
                lastEvent = String(html[eventRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("DEBUG - Extracted lastEvent: '\(lastEvent ?? "nil")' using simple pattern")
            }
        }
        
        // Look for date pattern DD/MM/YYYY
        if let dateRegex = try? NSRegularExpression(pattern: #"(\d{2}/\d{2}/\d{4})"#, options: []) {
            let dateMatches = dateRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = dateMatches.first, let dateRange = Range(match.range(at: 1), in: html) {
                lastDate = String(html[dateRange])
                print("DEBUG - Extracted lastDate: '\(lastDate ?? "nil")' using simple pattern")
            }
        }
        
        // Look for time pattern MM:SS in table
        if let timeRegex = try? NSRegularExpression(pattern: #"<td>(\d{2}:\d{2})</td>"#, options: []) {
            let timeMatches = timeRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = timeMatches.first, let timeRange = Range(match.range(at: 1), in: html) {
                lastTime = String(html[timeRange])
                print("DEBUG - Extracted lastTime: '\(lastTime ?? "nil")' using simple pattern")
            }
        }
        
        // Look for event results URL from date link pattern
        if let eventURLRegex = try? NSRegularExpression(pattern: #"<td><a href="(https://www\.parkrun\.(?:org\.uk|com|us|au|org\.nz|co\.za|it|se|dk|pl|ie|ca|fi|fr|sg|de|no|ru|my)/[^/]+/results/\d+/)"[^>]*>\d{2}/\d{2}/\d{4}</a></td>"#, options: [.caseInsensitive]) {
            let urlMatches = eventURLRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = urlMatches.first, let urlRange = Range(match.range(at: 1), in: html) {
                lastEventURL = String(html[urlRange])
                print("DEBUG - Extracted lastEventURL: '\(lastEventURL ?? "nil")' using corrected pattern with <td> wrapper")
            }
        }
        
        print("DEBUG - Final extracted data: name='\(name ?? "nil")', totalRuns='\(totalRuns ?? "nil")', lastEvent='\(lastEvent ?? "nil")', lastDate='\(lastDate ?? "nil")', lastTime='\(lastTime ?? "nil")', lastEventURL='\(lastEventURL ?? "nil")'")
        return (name: name, totalRuns: totalRuns, lastDate: lastDate, lastTime: lastTime, lastEvent: lastEvent, lastEventURL: lastEventURL)
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
        let previewParkrunInfo = ParkrunInfo(parkrunID: "A12345", name: "John Doe", homeParkrun: "Southampton Parkrun", country: Country.unitedKingdom.rawValue, isDefault: true)
        context.insert(previewParkrunInfo)
        
        return MeTabView()
            .modelContainer(previewContainer)
            .environmentObject(NotificationManager.shared)
    } catch {
        return Text("Failed to create preview: \(error)")
    }
}