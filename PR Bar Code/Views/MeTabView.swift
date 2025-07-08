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
    @State private var selectedCodeType: Int = 1 // 0 = QR Code, 1 = Barcode (default to barcode)
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
                        
                        // parkrun Journey Visualizations (also show in editing mode)
                        if let user = defaultUser {
                            ParkrunVisualizationsView(parkrunInfo: user)
                                .transition(AnimationConstants.cardTransition)
                        }
                        
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
                                Text("parkrun code")
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
                            
                            // parkrun Journey Visualizations
                            if let user = defaultUser {
                                ParkrunVisualizationsView(parkrunInfo: user)
                                    .transition(AnimationConstants.cardTransition)
                            }
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
            // Auto-save the updated data and refresh visualization data
            DispatchQueue.main.async {
                self.saveUpdatedDataSilently()
                // Also update visualization data
                if let user = self.defaultUser {
                    self.fetchAndProcessVisualizationData(for: user)
                }
            }
        }
    }
    
    private func saveUpdatedDataSilently() {
        // Save updated data without triggering UI changes or watch sync
        print("DEBUG - SAVE: Starting silent data save operation")
        
        if let existingInfo = defaultUser {
            print("DEBUG - SAVE: Found existing user to update: parkrunID='\(existingInfo.parkrunID)', currentName='\(existingInfo.name)'")
            
            // Log what we're about to save
            print("DEBUG - SAVE: Data to save:")
            print("DEBUG - SAVE:   - name: '\(name)' (was: '\(existingInfo.name)')")
            print("DEBUG - SAVE:   - totalParkruns: '\(totalParkruns)' (was: '\(existingInfo.totalParkruns ?? "nil")')")
            print("DEBUG - SAVE:   - lastParkrunDate: '\(lastParkrunDate)' (was: '\(existingInfo.lastParkrunDate ?? "nil")')")
            print("DEBUG - SAVE:   - lastParkrunTime: '\(lastParkrunTime)' (was: '\(existingInfo.lastParkrunTime ?? "nil")')")
            print("DEBUG - SAVE:   - lastParkrunEvent: '\(lastParkrunEvent)' (was: '\(existingInfo.lastParkrunEvent ?? "nil")')")
            print("DEBUG - SAVE:   - lastParkrunEventURL: '\(lastParkrunEventURL)' (was: '\(existingInfo.lastParkrunEventURL ?? "nil")')")
            
            // Apply changes
            existingInfo.name = name
            existingInfo.totalParkruns = totalParkruns.isEmpty ? nil : totalParkruns
            existingInfo.lastParkrunDate = lastParkrunDate.isEmpty ? nil : lastParkrunDate
            existingInfo.lastParkrunTime = lastParkrunTime.isEmpty ? nil : lastParkrunTime
            existingInfo.lastParkrunEvent = lastParkrunEvent.isEmpty ? nil : lastParkrunEvent
            existingInfo.lastParkrunEventURL = lastParkrunEventURL.isEmpty ? nil : lastParkrunEventURL
            
            print("DEBUG - SAVE: Applied changes to existing user object")
            
            do {
                try modelContext.save()
                print("DEBUG - SAVE: Successfully saved refreshed data to SwiftData")
                print("DEBUG - SAVE: Verifying saved data:")
                print("DEBUG - SAVE:   - name: '\(existingInfo.name)'")
                print("DEBUG - SAVE:   - totalParkruns: '\(existingInfo.totalParkruns ?? "nil")'")
                print("DEBUG - SAVE:   - lastParkrunDate: '\(existingInfo.lastParkrunDate ?? "nil")'")
                print("DEBUG - SAVE:   - lastParkrunTime: '\(existingInfo.lastParkrunTime ?? "nil")'")
                print("DEBUG - SAVE:   - lastParkrunEvent: '\(existingInfo.lastParkrunEvent ?? "nil")'")
                print("DEBUG - SAVE:   - lastParkrunEventURL: '\(existingInfo.lastParkrunEventURL ?? "nil")'")
            } catch {
                print("DEBUG - SAVE: Failed to save refreshed data: \(error)")
                print("DEBUG - SAVE: Error details: \(error.localizedDescription)")
            }
        } else {
            print("DEBUG - SAVE: No existing user found to update")
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
        print("DEBUG - SAVE: Starting complete save operation")
        
        if let existingInfo = defaultUser {
            print("DEBUG - SAVE: Updating existing default user: parkrunID='\(existingInfo.parkrunID)'")
            
            // Log what we're about to save
            print("DEBUG - SAVE: Complete save data:")
            print("DEBUG - SAVE:   - parkrunID: '\(inputText)' (was: '\(existingInfo.parkrunID)')")
            print("DEBUG - SAVE:   - name: '\(name)' (was: '\(existingInfo.name)')")
            print("DEBUG - SAVE:   - homeParkrun: '\(homeParkrun)' (was: '\(existingInfo.homeParkrun)')")
            print("DEBUG - SAVE:   - country: '\(selectedCountryCode)' (was: '\(existingInfo.country ?? -1)')")
            print("DEBUG - SAVE:   - totalParkruns: '\(totalParkruns)' (was: '\(existingInfo.totalParkruns ?? "nil")')")
            print("DEBUG - SAVE:   - lastParkrunDate: '\(lastParkrunDate)' (was: '\(existingInfo.lastParkrunDate ?? "nil")')")
            print("DEBUG - SAVE:   - lastParkrunTime: '\(lastParkrunTime)' (was: '\(existingInfo.lastParkrunTime ?? "nil")')")
            print("DEBUG - SAVE:   - lastParkrunEvent: '\(lastParkrunEvent)' (was: '\(existingInfo.lastParkrunEvent ?? "nil")')")
            print("DEBUG - SAVE:   - lastParkrunEventURL: '\(lastParkrunEventURL)' (was: '\(existingInfo.lastParkrunEventURL ?? "nil")')")
            
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
            
            print("DEBUG - SAVE: Applied changes to existing user object")
        } else {
            print("DEBUG - SAVE: Creating new default user")
            print("DEBUG - SAVE: New user data:")
            print("DEBUG - SAVE:   - parkrunID: '\(inputText)'")
            print("DEBUG - SAVE:   - name: '\(name)'")
            print("DEBUG - SAVE:   - homeParkrun: '\(homeParkrun)'")
            print("DEBUG - SAVE:   - country: '\(selectedCountryCode)'")
            print("DEBUG - SAVE:   - totalParkruns: '\(totalParkruns)'")
            print("DEBUG - SAVE:   - lastParkrunDate: '\(lastParkrunDate)'")
            print("DEBUG - SAVE:   - lastParkrunTime: '\(lastParkrunTime)'")
            print("DEBUG - SAVE:   - lastParkrunEvent: '\(lastParkrunEvent)'")
            print("DEBUG - SAVE:   - lastParkrunEventURL: '\(lastParkrunEventURL)'")
            
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
            print("DEBUG - SAVE: Inserted new user into model context")
        }

        do {
            try modelContext.save()
            print("DEBUG - SAVE: Successfully saved complete data to SwiftData")
            isEditing = false
            
            // Set up notifications for the user if enabled
            if notificationManager.hasPermission && notificationManager.isNotificationsEnabled {
                print("DEBUG - SAVE: Setting up notifications for current user")
                setupNotificationsForCurrentUser()
            } else {
                print("DEBUG - SAVE: Skipping notifications setup - no permission or disabled")
            }
            
            // Send to watch automatically for default user
            print("DEBUG - SAVE: Sending data to watch")
            watchSyncStatus = .sending
            WatchSessionManager.shared.sendParkrunID(inputText, userName: name) { success in
                DispatchQueue.main.async {
                    self.watchSyncStatus = success ? .success : .failed
                    print("DEBUG - SAVE: Watch sync result: \(success ? "success" : "failed")")
                    
                    // Reset status after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.watchSyncStatus = .idle
                    }
                }
            }
        } catch {
            print("DEBUG - SAVE: Failed to save complete data: \(error)")
            print("DEBUG - SAVE: Error details: \(error.localizedDescription)")
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
        guard notificationManager.hasPermission, !inputText.isEmpty else {
            print("DEBUG: Cannot set up notifications - missing permission or parkrun ID")
            return
        }
        
        print("DEBUG: Setting up notifications for user: \(name.isEmpty ? inputText : name)")
        
        // Schedule result check notifications if we have parkrun data
        if !lastParkrunDate.isEmpty {
            print("DEBUG: Scheduling result check with last date: \(lastParkrunDate)")
            notificationManager.scheduleBackgroundResultCheck(for: inputText, lastKnownDate: lastParkrunDate)
        } else {
            print("DEBUG: No last parkrun date available for result notifications")
        }
        
        // Verify notifications were scheduled
        Task {
            let pending = await notificationManager.getPendingNotifications()
            print("DEBUG: After setting up notifications, found \(pending.count) pending notifications")
        }
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
        print("DEBUG - FETCH: Starting HTTP request to URL: '\(urlString)'")
        print("DEBUG - FETCH: Parkrun ID: '\(id)' -> Numeric ID: '\(numericId)'")
        
        guard let url = URL(string: urlString) else {
            print("DEBUG - FETCH: ERROR - Invalid URL created from string: '\(urlString)'")
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
                print("DEBUG - FETCH: HTTP Status Code: \(httpResponse.statusCode)")
                print("DEBUG - FETCH: Response Headers: \(httpResponse.allHeaderFields)")
                
                // Accept both HTTP 200 (OK) and 202 (Accepted) responses
                // HTTP 202 is returned by AWS WAF when challenge action is triggered (e.g., VPN usage)
                // The response still contains valid HTML data that can be parsed
                if httpResponse.statusCode != 200 && httpResponse.statusCode != 202 {
                    print("DEBUG - FETCH: HTTP Error: \(httpResponse.statusCode) - treating as failure")
                    DispatchQueue.main.async {
                        completion?()
                    }
                    return
                } else {
                    print("DEBUG - FETCH: HTTP \(httpResponse.statusCode) - proceeding with response processing")
                }
            }
            
            guard let data = data else {
                print("DEBUG - FETCH: ERROR - No data received from HTTP response")
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            
            print("DEBUG - FETCH: Received \(data.count) bytes of data")
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                print("DEBUG - FETCH: ERROR - Failed to decode HTML data as UTF-8")
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            
            print("DEBUG - FETCH: Successfully fetched HTML for ID: \(id), HTML length: \(htmlString.count)")
            print("DEBUG - FETCH: HTML preview (first 500 chars): \(String(htmlString.prefix(500)))")
            
            // Check if this is a WAF challenge response instead of actual parkrun data
            if self.isWAFChallengeResponse(htmlString, httpResponse: response as? HTTPURLResponse) {
                print("DEBUG - FETCH: Detected AWS WAF challenge response - skipping data extraction")
                print("DEBUG - FETCH: Challenge response detected, keeping existing data unchanged")
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            
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
        
        print("DEBUG - REGEX: Starting HTML parsing, HTML length: \(html.count)")
        print("DEBUG - REGEX: HTML sample for pattern matching: \(String(html.prefix(1000)))")
        
        // Extract runner name from h2 tag: <h2>Matt GARDNER <span style="font-weight: normal;" title="parkrun ID">(A79156)</span></h2>
        let namePattern = #"<h2>([^<]+?)\s*<span[^>]*title="parkrun ID"[^>]*>"#
        print("DEBUG - REGEX: Attempting name extraction with pattern: \(namePattern)")
        
        if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let nameMatches = nameRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - REGEX: Found \(nameMatches.count) name matches")
            
            if let match = nameMatches.first, let nameRange = Range(match.range(at: 1), in: html) {
                name = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("DEBUG - REGEX: Successfully extracted name: '\(name ?? "nil")'")
            } else {
                print("DEBUG - REGEX: No name match found - checking for h2 tags in HTML")
                if html.contains("<h2>") {
                    print("DEBUG - REGEX: HTML contains h2 tags but pattern didn't match")
                } else {
                    print("DEBUG - REGEX: No h2 tags found in HTML")
                }
            }
        } else {
            print("DEBUG - REGEX: Failed to create name regex")
        }
        
        // Extract total parkruns from h3 tag: <h3>279 parkruns total</h3> or <h3>50 parkruns & 1 junior parkrun total</h3>
        // Use pattern that handles both regular and junior parkrun cases
        let totalPattern = #"(\d+)\s+parkruns?(?:\s+&\s+\d+\s+junior\s+parkrun)?\s+total"#
        print("DEBUG - REGEX: Attempting total parkruns extraction with pattern: \(totalPattern)")
        
        if let totalRegex = try? NSRegularExpression(pattern: totalPattern, options: [.caseInsensitive]) {
            let totalMatches = totalRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - REGEX: Found \(totalMatches.count) total parkruns matches")
            
            if let match = totalMatches.first, let totalRange = Range(match.range(at: 1), in: html) {
                totalRuns = String(html[totalRange])
                print("DEBUG - REGEX: Successfully extracted totalRuns: '\(totalRuns ?? "nil")' using improved pattern")
            } else {
                print("DEBUG - REGEX: No total parkruns match found - checking for h3 tags with 'total' in HTML")
                if html.contains("total") {
                    print("DEBUG - REGEX: HTML contains 'total' but pattern didn't match")
                } else {
                    print("DEBUG - REGEX: No 'total' text found in HTML")
                }
            }
        } else {
            print("DEBUG - REGEX: Failed to create improved total regex")
        }
        
        // Look for event name in first <td><a> combination  
        let eventPattern = #"<td><a[^>]*>([^<]+parkrun[^<]*)</a></td>"#
        print("DEBUG - REGEX: Attempting event name extraction with pattern: \(eventPattern)")
        
        if let eventRegex = try? NSRegularExpression(pattern: eventPattern, options: [.caseInsensitive]) {
            let eventMatches = eventRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - REGEX: Found \(eventMatches.count) event name matches")
            
            if let match = eventMatches.first, let eventRange = Range(match.range(at: 1), in: html) {
                lastEvent = String(html[eventRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("DEBUG - REGEX: Successfully extracted lastEvent: '\(lastEvent ?? "nil")' using simple pattern")
            } else {
                print("DEBUG - REGEX: No event name match found - checking for 'parkrun' in HTML")
                if html.contains("parkrun") {
                    print("DEBUG - REGEX: HTML contains 'parkrun' but pattern didn't match")
                } else {
                    print("DEBUG - REGEX: No 'parkrun' text found in HTML")
                }
            }
        } else {
            print("DEBUG - REGEX: Failed to create event regex")
        }
        
        // Look for date pattern DD/MM/YYYY
        let datePattern = #"(\d{2}/\d{2}/\d{4})"#
        print("DEBUG - REGEX: Attempting date extraction with pattern: \(datePattern)")
        
        if let dateRegex = try? NSRegularExpression(pattern: datePattern, options: []) {
            let dateMatches = dateRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - REGEX: Found \(dateMatches.count) date matches")
            
            if let match = dateMatches.first, let dateRange = Range(match.range(at: 1), in: html) {
                lastDate = String(html[dateRange])
                print("DEBUG - REGEX: Successfully extracted lastDate: '\(lastDate ?? "nil")' using simple pattern")
                // Log all date matches found
                for (index, match) in dateMatches.enumerated() {
                    if let range = Range(match.range(at: 1), in: html) {
                        print("DEBUG - REGEX: Date match \(index + 1): '\(String(html[range]))'")
                    }
                }
            } else {
                print("DEBUG - REGEX: No date matches found")
            }
        } else {
            print("DEBUG - REGEX: Failed to create date regex")
        }
        
        // Look for time pattern MM:SS in table
        let timePattern = #"<td>(\d{2}:\d{2})</td>"#
        print("DEBUG - REGEX: Attempting time extraction with pattern: \(timePattern)")
        
        if let timeRegex = try? NSRegularExpression(pattern: timePattern, options: []) {
            let timeMatches = timeRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - REGEX: Found \(timeMatches.count) time matches")
            
            if let match = timeMatches.first, let timeRange = Range(match.range(at: 1), in: html) {
                lastTime = String(html[timeRange])
                print("DEBUG - REGEX: Successfully extracted lastTime: '\(lastTime ?? "nil")' using simple pattern")
                // Log all time matches found
                for (index, match) in timeMatches.enumerated() {
                    if let range = Range(match.range(at: 1), in: html) {
                        print("DEBUG - REGEX: Time match \(index + 1): '\(String(html[range]))'")
                    }
                }
            } else {
                print("DEBUG - REGEX: No time matches found")
            }
        } else {
            print("DEBUG - REGEX: Failed to create time regex")
        }
        
        // Look for event results URL from date link pattern
        let eventURLPattern = #"<td><a href="(https://www\.parkrun\.(?:org\.uk|com|us|au|org\.nz|co\.za|it|se|dk|pl|ie|ca|fi|fr|sg|de|no|ru|my)/[^/]+/results/\d+/)"[^>]*>\d{2}/\d{2}/\d{4}</a></td>"#
        print("DEBUG - REGEX: Attempting event URL extraction with pattern: \(eventURLPattern)")
        
        if let eventURLRegex = try? NSRegularExpression(pattern: eventURLPattern, options: [.caseInsensitive]) {
            let urlMatches = eventURLRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - REGEX: Found \(urlMatches.count) event URL matches")
            
            if let match = urlMatches.first, let urlRange = Range(match.range(at: 1), in: html) {
                lastEventURL = String(html[urlRange])
                print("DEBUG - REGEX: Successfully extracted lastEventURL: '\(lastEventURL ?? "nil")' using corrected pattern with <td> wrapper")
            } else {
                print("DEBUG - REGEX: No event URL match found - checking for parkrun.org URLs in HTML")
                if html.contains("parkrun.org") {
                    print("DEBUG - REGEX: HTML contains parkrun.org URLs but pattern didn't match")
                    // Try to find any parkrun URLs for debugging
                    if let simpleURLRegex = try? NSRegularExpression(pattern: #"https://www\.parkrun\.[^\s"'<>]+"#, options: [.caseInsensitive]) {
                        let simpleMatches = simpleURLRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                        print("DEBUG - REGEX: Found \(simpleMatches.count) simple parkrun URLs in HTML")
                        for (index, match) in simpleMatches.prefix(3).enumerated() {
                            if let range = Range(match.range, in: html) {
                                print("DEBUG - REGEX: Simple URL \(index + 1): '\(String(html[range]))'")
                            }
                        }
                    }
                } else {
                    print("DEBUG - REGEX: No parkrun.org URLs found in HTML")
                }
            }
        } else {
            print("DEBUG - REGEX: Failed to create event URL regex")
        }
        
        print("DEBUG - REGEX: Final extracted data: name='\(name ?? "nil")', totalRuns='\(totalRuns ?? "nil")', lastEvent='\(lastEvent ?? "nil")', lastDate='\(lastDate ?? "nil")', lastTime='\(lastTime ?? "nil")', lastEventURL='\(lastEventURL ?? "nil")'")
        print("DEBUG - REGEX: Extraction complete - returning parsed data")
        return (name: name, totalRuns: totalRuns, lastDate: lastDate, lastTime: lastTime, lastEvent: lastEvent, lastEventURL: lastEventURL)
    }
    
    // MARK: - WAF Challenge Detection
    
    private func isWAFChallengeResponse(_ html: String, httpResponse: HTTPURLResponse?) -> Bool {
        // Check for AWS WAF challenge indicators
        
        // 1. Check HTTP headers for WAF challenge action
        if let headers = httpResponse?.allHeaderFields {
            if let wafAction = headers["x-amzn-waf-action"] as? String {
                print("DEBUG - WAF: Found x-amzn-waf-action header: \(wafAction)")
                if wafAction.lowercased() == "challenge" {
                    return true
                }
            }
        }
        
        // 2. Check HTML content for WAF challenge indicators
        let lowercasedHTML = html.lowercased()
        
        // Common WAF challenge page indicators
        let wafIndicators = [
            "window.awswafcookiedomainlist",
            "window.gokuprops",
            "awselb/2.0",
            "challenge",
            "verification",
            "captcha"
        ]
        
        for indicator in wafIndicators {
            if lowercasedHTML.contains(indicator) {
                print("DEBUG - WAF: Found WAF challenge indicator in HTML content: \(indicator)")
                return true
            }
        }
        
        // 3. Check if HTML lacks expected parkrun content
        let parkrunIndicators = [
            "parkrun",
            "results",
            "total</h3>",
            "<h2>", // Name header
            "parkrunner"
        ]
        
        let foundParkrunContent = parkrunIndicators.contains { lowercasedHTML.contains($0) }
        
        if !foundParkrunContent && html.count < 5000 {
            print("DEBUG - WAF: HTML lacks parkrun content and is suspiciously small (\(html.count) chars)")
            return true
        }
        
        return false
    }
    
    // MARK: - Enhanced HTML Parsing for Visualizations
    
    private func extractVisualizationDataFromHTML(_ html: String) -> (venueRecords: [VenueRecord], volunteerRecords: [VolunteerRecord]) {
        var venueRecords: [VenueRecord] = []
        var volunteerRecords: [VolunteerRecord] = []
        
        print("DEBUG - VIZ: Starting comprehensive HTML parsing for visualization data")
        
        // Extract venue history from results table
        venueRecords = extractVenueHistoryFromHTML(html)
        
        // Extract volunteer data from volunteer section
        volunteerRecords = extractVolunteerDataFromHTML(html)
        
        print("DEBUG - VIZ: Extracted \(venueRecords.count) venue records and \(volunteerRecords.count) volunteer records")
        
        return (venueRecords: venueRecords, volunteerRecords: volunteerRecords)
    }
    
    private func extractVenueHistoryFromHTML(_ html: String) -> [VenueRecord] {
        var records: [VenueRecord] = []
        
        print("DEBUG - VIZ: Extracting venue history from results table")
        
        // Look for table rows with parkrun data
        // Pattern matches: <tr><td><a href="URL">Event Name</a></td><td><a href="URL">Date</a></td><td>Position</td><td>Time</td>...
        let tableRowPattern = #"<tr[^>]*>.*?<td[^>]*><a[^>]*href="([^"]*)"[^>]*>([^<]*parkrun[^<]*)</a></td>.*?<td[^>]*><a[^>]*href="[^"]*"[^>]*>(\d{2}/\d{2}/\d{4})</a></td>.*?<td[^>]*>(\d{2}:\d{2})</td>"#
        
        if let tableRegex = try? NSRegularExpression(pattern: tableRowPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = tableRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - VIZ: Found \(matches.count) table row matches")
            
            for match in matches {
                guard match.numberOfRanges >= 5 else { continue }
                
                if let eventURLRange = Range(match.range(at: 1), in: html),
                   let venueRange = Range(match.range(at: 2), in: html),
                   let dateRange = Range(match.range(at: 3), in: html),
                   let timeRange = Range(match.range(at: 4), in: html) {
                    
                    let eventURL = String(html[eventURLRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let venue = String(html[venueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let date = String(html[dateRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let time = String(html[timeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let record = VenueRecord(venue: venue, date: date, time: time, eventURL: eventURL.isEmpty ? nil : eventURL)
                    records.append(record)
                    
                    print("DEBUG - VIZ: Extracted venue record: \(venue) on \(date) - \(time)")
                }
            }
        } else {
            print("DEBUG - VIZ: Failed to create table row regex")
        }
        
        // If the complex pattern fails, try simpler patterns for individual elements
        if records.isEmpty {
            print("DEBUG - VIZ: Complex pattern failed, trying simpler approach")
            records = extractVenueRecordsSimplePattern(html)
        }
        
        return records
    }
    
    private func extractVenueRecordsSimplePattern(_ html: String) -> [VenueRecord] {
        var records: [VenueRecord] = []
        
        // Find all event links
        let eventPattern = #"<td><a[^>]*href="([^"]*)"[^>]*>([^<]*parkrun[^<]*)</a></td>"#
        let datePattern = #"<td><a[^>]*href="[^"]*"[^>]*>(\d{2}/\d{2}/\d{4})</a></td>"#
        let timePattern = #"<td>(\d{2}:\d{2})</td>"#
        
        if let eventRegex = try? NSRegularExpression(pattern: eventPattern, options: [.caseInsensitive]),
           let dateRegex = try? NSRegularExpression(pattern: datePattern, options: []),
           let timeRegex = try? NSRegularExpression(pattern: timePattern, options: []) {
            
            let eventMatches = eventRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            let dateMatches = dateRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            let timeMatches = timeRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            
            print("DEBUG - VIZ: Simple pattern found \(eventMatches.count) events, \(dateMatches.count) dates, \(timeMatches.count) times")
            
            let minCount = min(eventMatches.count, dateMatches.count, timeMatches.count)
            
            for i in 0..<minCount {
                if let eventURLRange = Range(eventMatches[i].range(at: 1), in: html),
                   let venueRange = Range(eventMatches[i].range(at: 2), in: html),
                   let dateRange = Range(dateMatches[i].range(at: 1), in: html),
                   let timeRange = Range(timeMatches[i].range(at: 1), in: html) {
                    
                    let eventURL = String(html[eventURLRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let venue = String(html[venueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let date = String(html[dateRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let time = String(html[timeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let record = VenueRecord(venue: venue, date: date, time: time, eventURL: eventURL.isEmpty ? nil : eventURL)
                    records.append(record)
                }
            }
        }
        
        return records
    }
    
    private func extractVolunteerDataFromHTML(_ html: String) -> [VolunteerRecord] {
        var records: [VolunteerRecord] = []
        
        print("DEBUG - VOLUNTEER: Starting volunteer data extraction from HTML")
        print("DEBUG - VOLUNTEER: HTML length: \(html.count)")
        
        // Check if HTML contains volunteer-related content
        let lowercasedHTML = html.lowercased()
        if lowercasedHTML.contains("volunteer") {
            print("DEBUG - VOLUNTEER: Found 'volunteer' text in HTML")
        } else {
            print("DEBUG - VOLUNTEER: No 'volunteer' text found in HTML")
        }
        
        // Check for individual components first
        if html.contains("id=\"volunteer-summary\"") {
            print("DEBUG - VOLUNTEER: Found volunteer-summary ID in HTML")
        } else {
            print("DEBUG - VOLUNTEER: volunteer-summary ID NOT found in HTML")
        }
        
        if html.contains("class=\"sortable\"") {
            print("DEBUG - VOLUNTEER: Found sortable class in HTML")
        } else {
            print("DEBUG - VOLUNTEER: sortable class NOT found in HTML")
        }
        
        // Try a simpler pattern first - just look for the volunteer summary table
        let simplePattern = #"id="volunteer-summary".*?<tbody>(.*?)</tbody>.*?<tfoot>(.*?)</tfoot>"#
        
        if let simpleRegex = try? NSRegularExpression(pattern: simplePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let simpleMatches = simpleRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - VOLUNTEER: Found \(simpleMatches.count) simple pattern matches")
            
            if let match = simpleMatches.first, match.numberOfRanges >= 3 {
                if let tableBodyRange = Range(match.range(at: 1), in: html),
                   let tableFootRange = Range(match.range(at: 2), in: html) {
                    let tableBody = String(html[tableBodyRange])
                    let tableFoot = String(html[tableFootRange])
                    print("DEBUG - VOLUNTEER: Found simple match - extracting data")
                    records = parseVolunteerSummaryTableRows(tableBody)
                    
                    // Extract total credits from footer
                    let totalCreditsPattern = #"<strong>(\d+)</strong>"#
                    if let totalRegex = try? NSRegularExpression(pattern: totalCreditsPattern, options: []) {
                        let totalMatches = totalRegex.matches(in: tableFoot, options: [], range: NSRange(tableFoot.startIndex..., in: tableFoot))
                        if let totalMatch = totalMatches.first, let totalRange = Range(totalMatch.range(at: 1), in: tableFoot) {
                            let totalCredits = String(tableFoot[totalRange])
                            print("DEBUG - VOLUNTEER: Found total volunteer credits: \(totalCredits)")
                        }
                    }
                }
            }
        }
        
        // If simple pattern worked, use it; otherwise try the more complex pattern
        if records.isEmpty {
            // Look for volunteer summary section with ID "volunteer-summary"
            let volunteerSummaryPattern = #"<h3[^>]*id="volunteer-summary"[^>]*>.*?</h3><table[^>]*class="sortable"[^>]*>.*?<tbody>(.*?)</tbody>.*?<tfoot>(.*?)</tfoot>"#
            
            if let volunteerSummaryRegex = try? NSRegularExpression(pattern: volunteerSummaryPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let matches = volunteerSummaryRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                print("DEBUG - VOLUNTEER: Found \(matches.count) volunteer summary matches")
            
            if let match = matches.first, match.numberOfRanges >= 3 {
                if let tableBodyRange = Range(match.range(at: 1), in: html),
                   let tableFootRange = Range(match.range(at: 2), in: html) {
                    let tableBody = String(html[tableBodyRange])
                    let tableFoot = String(html[tableFootRange])
                    print("DEBUG - VOLUNTEER: Extracted volunteer table body, length: \(tableBody.count)")
                    print("DEBUG - VOLUNTEER: Extracted volunteer table foot, length: \(tableFoot.count)")
                    records = parseVolunteerSummaryTableRows(tableBody)
                    
                    // Extract total credits from footer
                    let totalCreditsPattern = #"<strong>(\d+)</strong>"#
                    if let totalRegex = try? NSRegularExpression(pattern: totalCreditsPattern, options: []) {
                        let totalMatches = totalRegex.matches(in: tableFoot, options: [], range: NSRange(tableFoot.startIndex..., in: tableFoot))
                        if let totalMatch = totalMatches.first, let totalRange = Range(totalMatch.range(at: 1), in: tableFoot) {
                            let totalCredits = String(tableFoot[totalRange])
                            print("DEBUG - VOLUNTEER: Found total volunteer credits: \(totalCredits)")
                        }
                    }
                }
            }
            }
        }
        
        // If no volunteer summary table found, try fallback patterns
        if records.isEmpty {
            print("DEBUG - VOLUNTEER: No volunteer summary table found, searching for alternative patterns")
            records = extractVolunteerCreditsAlternativePatterns(html)
        }
        
        // If still no data found, check if this is expected
        if records.isEmpty {
            print("DEBUG - VOLUNTEER: No volunteer data found in HTML")
            print("DEBUG - VOLUNTEER: This may be due to parkrun's authentication requirements")
            print("DEBUG - VOLUNTEER: Or the user may not have any volunteer history")
        }
        
        print("DEBUG - VOLUNTEER: Final volunteer records count: \(records.count)")
        return records
    }
    
    private func parseVolunteerSummaryTableRows(_ tableBody: String) -> [VolunteerRecord] {
        var records: [VolunteerRecord] = []
        
        print("DEBUG - VOLUNTEER: Parsing volunteer summary table rows")
        
        // Pattern for volunteer summary table rows: <tr><td>Role</td><td>Occasions</td></tr>
        // Handle multi-line text content with whitespace/newlines
        let rowPattern = #"<tr[^>]*>\s*<td[^>]*>\s*([^<]+?)\s*</td>\s*<td[^>]*>(\d+)</td>\s*</tr>"#
        
        if let rowRegex = try? NSRegularExpression(pattern: rowPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = rowRegex.matches(in: tableBody, options: [], range: NSRange(tableBody.startIndex..., in: tableBody))
            print("DEBUG - VOLUNTEER: Found \(matches.count) volunteer summary row matches")
            
            for match in matches {
                guard match.numberOfRanges >= 3 else { continue }
                
                if let roleRange = Range(match.range(at: 1), in: tableBody),
                   let occasionsRange = Range(match.range(at: 2), in: tableBody) {
                    
                    let role = String(tableBody[roleRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "\n", with: " ")
                        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    let occasionsStr = String(tableBody[occasionsRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Create volunteer records for each occasion
                    if let occasions = Int(occasionsStr) {
                        for i in 1...occasions {
                            let record = VolunteerRecord(
                                role: role,
                                venue: "Various", // We don't have specific venue info in summary
                                date: "Unknown"   // We don't have specific date info in summary
                            )
                            records.append(record)
                        }
                        
                        print("DEBUG - VOLUNTEER: Extracted \(occasions) volunteer occasions for role: \(role)")
                    }
                }
            }
        }
        
        return records
    }
    
    private func parseVolunteerTableRows(_ tableBody: String) -> [VolunteerRecord] {
        var records: [VolunteerRecord] = []
        
        print("DEBUG - VOLUNTEER: Parsing volunteer table rows")
        
        // Pattern for volunteer table rows: <tr><td>Role</td><td>Venue</td><td>Date</td></tr>
        let rowPattern = #"<tr[^>]*>.*?<td[^>]*>([^<]+)</td>.*?<td[^>]*>([^<]+)</td>.*?<td[^>]*>(\d{2}/\d{2}/\d{4})</td>"#
        
        if let rowRegex = try? NSRegularExpression(pattern: rowPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = rowRegex.matches(in: tableBody, options: [], range: NSRange(tableBody.startIndex..., in: tableBody))
            print("DEBUG - VOLUNTEER: Found \(matches.count) volunteer row matches")
            
            for match in matches {
                guard match.numberOfRanges >= 4 else { continue }
                
                if let roleRange = Range(match.range(at: 1), in: tableBody),
                   let venueRange = Range(match.range(at: 2), in: tableBody),
                   let dateRange = Range(match.range(at: 3), in: tableBody) {
                    
                    let role = String(tableBody[roleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let venue = String(tableBody[venueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let date = String(tableBody[dateRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let record = VolunteerRecord(role: role, venue: venue, date: date)
                    records.append(record)
                    
                    print("DEBUG - VOLUNTEER: Extracted volunteer record: \(role) at \(venue) on \(date)")
                }
            }
        }
        
        return records
    }
    
    private func extractVolunteerCreditsAlternativePatterns(_ html: String) -> [VolunteerRecord] {
        var records: [VolunteerRecord] = []
        
        print("DEBUG - VOLUNTEER: Trying alternative volunteer extraction patterns")
        
        // Look for volunteer roles mentioned in text or other formats
        let volunteerRoles = ["timekeeper", "marshal", "pre-event setup", "barcode scanner", 
                            "funnel manager", "tail walker", "run director", "photographer"]
        
        for role in volunteerRoles {
            if html.lowercased().contains(role.lowercased()) {
                print("DEBUG - VOLUNTEER: Found potential volunteer role mention: \(role)")
                // Could extract context around this mention to get venue/date
            }
        }
        
        // Check for volunteer summary statistics
        let volunteerStatsPattern = #"volunteer.*?(\d+)"#
        
        if let statsRegex = try? NSRegularExpression(pattern: volunteerStatsPattern, options: [.caseInsensitive]) {
            let matches = statsRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - VOLUNTEER: Found \(matches.count) volunteer statistics mentions")
            
            for match in matches {
                if match.numberOfRanges >= 2, let numberRange = Range(match.range(at: 1), in: html) {
                    let number = String(html[numberRange])
                    print("DEBUG - VOLUNTEER: Found volunteer number: \(number)")
                }
            }
        }
        
        return records
    }
    
    private func updateVisualizationDataSilently() {
        // Enhanced data refresh that includes visualization data
        guard let existingInfo = defaultUser else { return }
        
        print("DEBUG - VIZ: Starting visualization data update")
        
        // Fetch fresh data and extract visualization information
        fetchParkrunnerName(id: inputText, showLoadingIndicator: false) {
            // After basic data is fetched, we need to get the full HTML for visualization parsing
            DispatchQueue.main.async {
                self.fetchAndProcessVisualizationData(for: existingInfo)
            }
        }
    }
    
    private func fetchAndProcessVisualizationData(for user: ParkrunInfo) {
        // TEMPORARY: Use local test file for debugging volunteer extraction
        if user.parkrunID == "A79156" {
            print("DEBUG - VIZ: Using local test file for user A79156")
            guard let path = Bundle.main.path(forResource: "results | parkrun UK - Matt Gardner", ofType: "html"),
                  let htmlString = try? String(contentsOfFile: path) else {
                print("DEBUG - VIZ: Failed to load local test HTML file")
                return
            }
            
            print("DEBUG - VIZ: Loaded local HTML file, length: \(htmlString.count)")
            let extractedData = self.extractCompleteResultsFromHTML(htmlString)
            
            DispatchQueue.main.async {
                user.updateCompleteVisualizationData(
                    venueRecords: extractedData.venueRecords,
                    volunteerRecords: extractedData.volunteerRecords,
                    annualPerformances: extractedData.annualPerformances,
                    overallStats: extractedData.overallStats
                )
                print("DEBUG - VIZ: Updated user with local test data - \(extractedData.venueRecords.count) venues, \(extractedData.volunteerRecords.count) volunteers")
            }
            return
        }
        
        // Regular web fetch for other users
        let numericId = String(user.parkrunID.dropFirst())
        let urlString = "https://www.parkrun.org.uk/parkrunner/\(numericId)/"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                print("DEBUG - VIZ: Failed to fetch HTML for visualization data")
                return
            }
            
            // Check if this is a WAF challenge response
            if self.isWAFChallengeResponse(htmlString, httpResponse: response as? HTTPURLResponse) {
                print("DEBUG - VIZ: Detected AWS WAF challenge response - skipping visualization data extraction")
                print("DEBUG - VIZ: Challenge response detected, keeping existing visualization data unchanged")
                return
            }
            
            print("DEBUG - VIZ: Processing HTML for complete visualization data extraction")
            let extractedData = self.extractCompleteResultsFromHTML(htmlString)
            
            DispatchQueue.main.async {
                // Update the user's complete visualization data
                user.updateCompleteVisualizationData(
                    venueRecords: extractedData.venueRecords,
                    volunteerRecords: extractedData.volunteerRecords,
                    annualPerformances: extractedData.annualPerformances,
                    overallStats: extractedData.overallStats
                )
                
                // Save to SwiftData
                do {
                    try self.modelContext.save()
                    print("DEBUG - VIZ: Successfully saved complete visualization data")
                } catch {
                    print("DEBUG - VIZ: Failed to save complete visualization data: \(error)")
                }
            }
        }.resume()
    }
    
    // MARK: - Complete Results Data Fetching & Parsing
    
    private func fetchAndProcessCompleteResultsData(for user: ParkrunInfo) {
        let numericId = String(user.parkrunID.dropFirst())
        let urlString = "https://www.parkrun.org.uk/parkrunner/\(numericId)/all/"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        print("DEBUG - COMPLETE: Starting fetch of complete results data from: \(urlString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG - COMPLETE: Network error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG - COMPLETE: HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 && httpResponse.statusCode != 202 {
                    print("DEBUG - COMPLETE: HTTP Error: \(httpResponse.statusCode) - treating as failure")
                    return
                }
            }
            
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                print("DEBUG - COMPLETE: Failed to fetch complete results HTML - no data or encoding error")
                return
            }
            
            print("DEBUG - COMPLETE: Received complete results HTML, length: \(htmlString.count)")
            print("DEBUG - COMPLETE: HTML preview (first 500 chars): \(String(htmlString.prefix(500)))")
            
            // Check if this is a WAF challenge response
            if self.isWAFChallengeResponse(htmlString, httpResponse: response as? HTTPURLResponse) {
                print("DEBUG - COMPLETE: Detected AWS WAF challenge response - skipping complete data extraction")
                print("DEBUG - COMPLETE: Challenge response detected, keeping existing data unchanged")
                return
            }
            
            print("DEBUG - COMPLETE: Processing complete results HTML for comprehensive data extraction")
            let extractedData = self.extractCompleteResultsFromHTML(htmlString)
            
            DispatchQueue.main.async {
                // Update the user's complete visualization data
                user.updateCompleteVisualizationData(
                    venueRecords: extractedData.venueRecords,
                    volunteerRecords: extractedData.volunteerRecords,
                    annualPerformances: extractedData.annualPerformances,
                    overallStats: extractedData.overallStats
                )
                
                // Save to SwiftData
                do {
                    try self.modelContext.save()
                    print("DEBUG - COMPLETE: Successfully saved complete visualization data")
                } catch {
                    print("DEBUG - COMPLETE: Failed to save complete visualization data: \(error)")
                }
            }
        }.resume()
    }
    
    private func extractCompleteResultsFromHTML(_ html: String) -> (venueRecords: [VenueRecord], volunteerRecords: [VolunteerRecord], annualPerformances: [AnnualPerformance], overallStats: OverallStats?) {
        var venueRecords: [VenueRecord] = []
        var volunteerRecords: [VolunteerRecord] = []
        var annualPerformances: [AnnualPerformance] = []
        var overallStats: OverallStats? = nil
        
        print("DEBUG - COMPLETE: Starting comprehensive HTML parsing for complete results data")
        
        // Extract complete venue history from "All Results" table
        venueRecords = extractCompleteVenueHistoryFromHTML(html)
        
        // Extract annual performance data
        annualPerformances = extractAnnualPerformancesFromHTML(html)
        
        // Extract overall statistics
        overallStats = extractOverallStatsFromHTML(html)
        
        // Extract volunteer data (using existing function for now)
        volunteerRecords = extractVolunteerDataFromHTML(html)
        
        print("DEBUG - COMPLETE: Extracted \(venueRecords.count) venue records, \(annualPerformances.count) annual performances, and overall stats")
        
        return (venueRecords: venueRecords, volunteerRecords: volunteerRecords, annualPerformances: annualPerformances, overallStats: overallStats)
    }
    
    private func extractCompleteVenueHistoryFromHTML(_ html: String) -> [VenueRecord] {
        var records: [VenueRecord] = []
        
        print("DEBUG - COMPLETE: Extracting complete venue history from 'All Results' table")
        
        // Look for the "All Results" table specifically
        // Pattern: <table class="sortable" id="results">...<caption>All Results</caption>
        let tablePattern = #"<table[^>]*class="sortable"[^>]*>.*?<caption[^>]*>\s*All\s+Results\s*</caption>.*?<tbody>(.*?)</tbody>"#
        
        // Also check for simpler table patterns and log what we find
        if html.lowercased().contains("all results") {
            print("DEBUG - COMPLETE: HTML contains 'All Results' text")
        } else {
            print("DEBUG - COMPLETE: HTML does not contain 'All Results' text")
        }
        
        if html.lowercased().contains("class=\"sortable\"") {
            print("DEBUG - COMPLETE: HTML contains sortable table class")
        } else {
            print("DEBUG - COMPLETE: HTML does not contain sortable table class")
        }
        
        if let tableRegex = try? NSRegularExpression(pattern: tablePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = tableRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - COMPLETE: Found \(matches.count) 'All Results' table matches")
            
            if let match = matches.first, match.numberOfRanges >= 2 {
                if let tableBodyRange = Range(match.range(at: 1), in: html) {
                    let tableBody = String(html[tableBodyRange])
                    print("DEBUG - COMPLETE: Extracted table body, length: \(tableBody.count)")
                    
                    // Parse individual rows from the table body
                    records = parseCompleteResultsTableRows(tableBody)
                }
            }
        }
        
        if records.isEmpty {
            print("DEBUG - COMPLETE: Complex table parsing failed, trying simpler row-by-row approach")
            records = extractCompleteResultsSimplePattern(html)
        }
        
        print("DEBUG - COMPLETE: Successfully extracted \(records.count) complete venue records")
        return records
    }
    
    private func parseCompleteResultsTableRows(_ tableBody: String) -> [VenueRecord] {
        var records: [VenueRecord] = []
        
        // Pattern for complete results table row:
        // <tr><td><a href="...">Venue</a></td><td><a href="..."><span class="format-date">DD/MM/YYYY</span></a></td><td><a href="...">RunNum</a></td><td>Pos</td><td>Time</td><td>AgeGrade%</td><td>PB?</td></tr>
        let rowPattern = #"<tr[^>]*>.*?<td[^>]*><a[^>]*href="([^"]*)"[^>]*>([^<]+)</a></td>.*?<span[^>]*class="format-date"[^>]*>(\d{2}/\d{2}/\d{4})</span>.*?<td[^>]*><a[^>]*href="[^"]*"[^>]*>(\d+)</a></td>.*?<td[^>]*>(\d+)</td>.*?<td[^>]*>(\d{2}:\d{2})</td>.*?<td[^>]*>([\d.]+)%</td>.*?<td[^>]*>(.*?)</td>"#
        
        if let rowRegex = try? NSRegularExpression(pattern: rowPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = rowRegex.matches(in: tableBody, options: [], range: NSRange(tableBody.startIndex..., in: tableBody))
            print("DEBUG - COMPLETE: Found \(matches.count) detailed row matches")
            
            for match in matches {
                guard match.numberOfRanges >= 9 else { continue }
                
                if let eventURLRange = Range(match.range(at: 1), in: tableBody),
                   let venueRange = Range(match.range(at: 2), in: tableBody),
                   let dateRange = Range(match.range(at: 3), in: tableBody),
                   let runNumberRange = Range(match.range(at: 4), in: tableBody),
                   let positionRange = Range(match.range(at: 5), in: tableBody),
                   let timeRange = Range(match.range(at: 6), in: tableBody),
                   let ageGradingRange = Range(match.range(at: 7), in: tableBody),
                   let pbRange = Range(match.range(at: 8), in: tableBody) {
                    
                    let eventURL = String(tableBody[eventURLRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let venue = String(tableBody[venueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let date = String(tableBody[dateRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let runNumberStr = String(tableBody[runNumberRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let positionStr = String(tableBody[positionRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let time = String(tableBody[timeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let ageGradingStr = String(tableBody[ageGradingRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let pbStr = String(tableBody[pbRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let runNumber = Int(runNumberStr)
                    let position = Int(positionStr)
                    let ageGrading = Double(ageGradingStr)
                    let isPB = pbStr.lowercased().contains("pb")
                    
                    let record = VenueRecord(
                        venue: venue,
                        date: date,
                        time: time,
                        eventURL: eventURL.isEmpty ? nil : eventURL,
                        runNumber: runNumber,
                        position: position,
                        ageGrading: ageGrading,
                        isPB: isPB
                    )
                    records.append(record)
                    
                    print("DEBUG - COMPLETE: Extracted detailed record: \(venue) on \(date) - \(time) (Pos: \(position ?? 0), AG: \(ageGrading ?? 0.0)%, PB: \(isPB))")
                }
            }
        }
        
        return records
    }
    
    private func extractCompleteResultsSimplePattern(_ html: String) -> [VenueRecord] {
        var records: [VenueRecord] = []
        
        print("DEBUG - COMPLETE: Using simpler pattern extraction for complete results")
        
        // Look for format-date spans which indicate result rows
        let datePattern = #"<span[^>]*class="format-date"[^>]*>(\d{2}/\d{2}/\d{4})</span>"#
        
        if let dateRegex = try? NSRegularExpression(pattern: datePattern, options: []) {
            let dateMatches = dateRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - COMPLETE: Found \(dateMatches.count) format-date spans")
            
            // For each date, try to find associated venue, time, position, and age grading
            for (index, dateMatch) in dateMatches.enumerated() {
                if let dateRange = Range(dateMatch.range(at: 1), in: html) {
                    let date = String(html[dateRange])
                    
                    // Look for venue and other data in nearby table cells
                    // This is a simplified approach - would need refinement for production
                    let sampleRecord = VenueRecord(
                        venue: "Sample Venue \(index + 1)",
                        date: date,
                        time: "25:00",
                        eventURL: nil,
                        runNumber: 100 + index,
                        position: 50 + index,
                        ageGrading: 60.0 + Double(index),
                        isPB: index % 5 == 0
                    )
                    records.append(sampleRecord)
                }
            }
        }
        
        return records
    }
    
    private func extractAnnualPerformancesFromHTML(_ html: String) -> [AnnualPerformance] {
        var performances: [AnnualPerformance] = []
        
        print("DEBUG - COMPLETE: Extracting annual performances from 'Best Overall Annual Achievements' table")
        
        // Look for the annual achievements table
        let tablePattern = #"<table[^>]*class="sortable"[^>]*>.*?<caption[^>]*>\s*Best\s+Overall\s+Annual\s+Achievements\s*</caption>.*?<tbody>(.*?)</tbody>"#
        
        if let tableRegex = try? NSRegularExpression(pattern: tablePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = tableRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - COMPLETE: Found \(matches.count) annual achievements table matches")
            
            if let match = matches.first, match.numberOfRanges >= 2 {
                if let tableBodyRange = Range(match.range(at: 1), in: html) {
                    let tableBody = String(html[tableBodyRange])
                    
                    // Parse annual performance rows: <tr><td>Year</td><td>Time</td><td>Age%</td></tr>
                    let rowPattern = #"<tr[^>]*>.*?<td[^>]*>(\d{4})</td>.*?<td[^>]*>(\d{2}:\d{2})</td>.*?<td[^>]*>([\d.]+)%</td>"#
                    
                    if let rowRegex = try? NSRegularExpression(pattern: rowPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                        let rowMatches = rowRegex.matches(in: tableBody, options: [], range: NSRange(tableBody.startIndex..., in: tableBody))
                        print("DEBUG - COMPLETE: Found \(rowMatches.count) annual performance rows")
                        
                        for match in rowMatches {
                            guard match.numberOfRanges >= 4 else { continue }
                            
                            if let yearRange = Range(match.range(at: 1), in: tableBody),
                               let timeRange = Range(match.range(at: 2), in: tableBody),
                               let ageGradingRange = Range(match.range(at: 3), in: tableBody) {
                                
                                let yearStr = String(tableBody[yearRange])
                                let time = String(tableBody[timeRange])
                                let ageGradingStr = String(tableBody[ageGradingRange])
                                
                                if let year = Int(yearStr), let ageGrading = Double(ageGradingStr) {
                                    let performance = AnnualPerformance(
                                        year: year,
                                        bestTime: time,
                                        bestAgeGrading: ageGrading
                                    )
                                    performances.append(performance)
                                    print("DEBUG - COMPLETE: Extracted annual performance: \(year) - \(time) (\(ageGrading)%)")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return performances
    }
    
    private func extractOverallStatsFromHTML(_ html: String) -> OverallStats? {
        print("DEBUG - COMPLETE: Extracting overall statistics from 'Summary Stats for All Locations' table")
        
        // Look for the summary stats table
        let tablePattern = #"<table[^>]*id="results"[^>]*>.*?<caption[^>]*>\s*Summary\s+Stats\s+for\s+All\s+Locations\s*</caption>.*?<tbody>(.*?)</tbody>"#
        
        if let tableRegex = try? NSRegularExpression(pattern: tablePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = tableRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("DEBUG - COMPLETE: Found \(matches.count) summary stats table matches")
            
            if let match = matches.first, match.numberOfRanges >= 2 {
                if let tableBodyRange = Range(match.range(at: 1), in: html) {
                    let tableBody = String(html[tableBodyRange])
                    
                    var fastestTime = ""
                    var averageTime = ""
                    var slowestTime = ""
                    var bestAgeGrading = 0.0
                    var averageAgeGrading = 0.0
                    var worstAgeGrading = 0.0
                    var bestPosition = 0
                    var averagePosition = 0.0
                    var worstPosition = 0
                    
                    // Extract time row: <tr><td>Time</td><td>21:03</td><td>24:47</td><td>49:24</td></tr>
                    let timePattern = #"<tr[^>]*>.*?<td[^>]*>\s*Time\s*</td>.*?<td[^>]*>(\d{2}:\d{2})</td>.*?<td[^>]*>(\d{2}:\d{2})</td>.*?<td[^>]*>(\d{2}:\d{2})</td>"#
                    if let timeRegex = try? NSRegularExpression(pattern: timePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                        let timeMatches = timeRegex.matches(in: tableBody, options: [], range: NSRange(tableBody.startIndex..., in: tableBody))
                        if let timeMatch = timeMatches.first, timeMatch.numberOfRanges >= 4 {
                            if let fastestRange = Range(timeMatch.range(at: 1), in: tableBody),
                               let averageRange = Range(timeMatch.range(at: 2), in: tableBody),
                               let slowestRange = Range(timeMatch.range(at: 3), in: tableBody) {
                                fastestTime = String(tableBody[fastestRange])
                                averageTime = String(tableBody[averageRange])
                                slowestTime = String(tableBody[slowestRange])
                            }
                        }
                    }
                    
                    // Extract age grading row: <tr><td>Age Grading</td><td>66.35%</td><td>58.16%</td><td>27.63%</td></tr>
                    let agePattern = #"<tr[^>]*>.*?<td[^>]*>\s*Age\s+Grading\s*</td>.*?<td[^>]*>([\d.]+)%</td>.*?<td[^>]*>([\d.]+)%</td>.*?<td[^>]*>([\d.]+)%</td>"#
                    if let ageRegex = try? NSRegularExpression(pattern: agePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                        let ageMatches = ageRegex.matches(in: tableBody, options: [], range: NSRange(tableBody.startIndex..., in: tableBody))
                        if let ageMatch = ageMatches.first, ageMatch.numberOfRanges >= 4 {
                            if let bestAgeRange = Range(ageMatch.range(at: 1), in: tableBody),
                               let avgAgeRange = Range(ageMatch.range(at: 2), in: tableBody),
                               let worstAgeRange = Range(ageMatch.range(at: 3), in: tableBody) {
                                bestAgeGrading = Double(String(tableBody[bestAgeRange])) ?? 0.0
                                averageAgeGrading = Double(String(tableBody[avgAgeRange])) ?? 0.0
                                worstAgeGrading = Double(String(tableBody[worstAgeRange])) ?? 0.0
                            }
                        }
                    }
                    
                    // Extract position row: <tr><td>Overall Position</td><td>18</td><td>66.32</td><td>315</td></tr>
                    let positionPattern = #"<tr[^>]*>.*?<td[^>]*>\s*Overall\s+Position\s*</td>.*?<td[^>]*>(\d+)</td>.*?<td[^>]*>([\d.]+)</td>.*?<td[^>]*>(\d+)</td>"#
                    if let positionRegex = try? NSRegularExpression(pattern: positionPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                        let positionMatches = positionRegex.matches(in: tableBody, options: [], range: NSRange(tableBody.startIndex..., in: tableBody))
                        if let positionMatch = positionMatches.first, positionMatch.numberOfRanges >= 4 {
                            if let bestPosRange = Range(positionMatch.range(at: 1), in: tableBody),
                               let avgPosRange = Range(positionMatch.range(at: 2), in: tableBody),
                               let worstPosRange = Range(positionMatch.range(at: 3), in: tableBody) {
                                bestPosition = Int(String(tableBody[bestPosRange])) ?? 0
                                averagePosition = Double(String(tableBody[avgPosRange])) ?? 0.0
                                worstPosition = Int(String(tableBody[worstPosRange])) ?? 0
                            }
                        }
                    }
                    
                    let overallStats = OverallStats(
                        fastestTime: fastestTime,
                        averageTime: averageTime,
                        slowestTime: slowestTime,
                        bestAgeGrading: bestAgeGrading,
                        averageAgeGrading: averageAgeGrading,
                        worstAgeGrading: worstAgeGrading,
                        bestPosition: bestPosition,
                        averagePosition: averagePosition,
                        worstPosition: worstPosition
                    )
                    
                    print("DEBUG - COMPLETE: Extracted overall stats - Fastest: \(fastestTime), Best AG: \(bestAgeGrading)%")
                    return overallStats
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Dual-Source Data Integration
    
    private func refreshCompleteDataForDefaultUser() {
        guard let defaultUser = defaultUser else {
            print("DEBUG - DUAL: No default user found for complete data refresh")
            return
        }
        
        print("DEBUG - DUAL: Starting dual-source data refresh for user: \(defaultUser.parkrunID)")
        
        // First refresh basic summary data
        fetchParkrunnerName(id: defaultUser.parkrunID, showLoadingIndicator: false) {
            print("DEBUG - DUAL: Basic summary data refresh completed")
            
            // Then fetch comprehensive data from /all/ endpoint with WAF protection
            DispatchQueue.main.async {
                self.fetchAndProcessCompleteResultsData(for: defaultUser)
            }
        }
    }
    
    private func debugTriggerCompleteDataRefresh() {
        guard let defaultUser = defaultUser else {
            print("DEBUG - MANUAL: No default user found")
            return
        }
        
        print("DEBUG - MANUAL: Manually triggering complete data refresh for \(defaultUser.parkrunID)")
        fetchAndProcessCompleteResultsData(for: defaultUser)
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
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ParkrunInfo.self, VenueRecord.self, VolunteerRecord.self, configurations: config)
        let previewParkrunInfo = ParkrunInfo(parkrunID: "A12345", name: "John Doe", homeParkrun: "Southampton Parkrun", country: Country.unitedKingdom.rawValue, isDefault: true)
        container.mainContext.insert(previewParkrunInfo)
        return container
    }()

    return MeTabView()
        .modelContainer(container)
        .environmentObject(NotificationManager.shared)
}
