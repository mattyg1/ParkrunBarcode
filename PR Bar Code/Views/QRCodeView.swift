import SwiftUI
import CoreImage.CIFilterBuiltins
import SwiftData
import WatchConnectivity

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

enum WatchSyncStatus {
    case idle
    case sending
    case success
    case failed
}

struct QRCodeBarcodeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var parkrunInfoList: [ParkrunInfo]

    @State private var inputText: String = ""
    @State private var name: String = ""
    @State private var homeParkrun: String = ""
    @State private var selectedCountryCode: Int = Country.unitedKingdom.rawValue // Default to UK
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
    @State private var watchSyncStatus: WatchSyncStatus = .idle
    @State private var showOnboarding: Bool = false

    private let context = CIContext()
    private let qrCodeFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()
    
    private var confirmationMessage: String {
        var message = "Please confirm your details:\n\nParkrun ID: \(inputText)"
        
        if !name.isEmpty {
            message += "\nName: \(name)"
        }
        
        print("DEBUG - confirmationMessage: totalParkruns='\(totalParkruns)', isEmpty=\(totalParkruns.isEmpty)")
        if !totalParkruns.isEmpty {
            message += "\nTotal Parkruns: \(totalParkruns)"
        }
        
        print("DEBUG - confirmationMessage: lastParkrunDate='\(lastParkrunDate)', lastParkrunTime='\(lastParkrunTime)', lastParkrunEvent='\(lastParkrunEvent)'")
        if !lastParkrunDate.isEmpty && !lastParkrunTime.isEmpty && !lastParkrunEvent.isEmpty {
            message += "\nLast Parkrun: \(lastParkrunEvent)"
            message += "\nDate: \(lastParkrunDate), Time: \(lastParkrunTime)"
        }
        
        print("DEBUG - Final confirmation message: '\(message)'")
        return message
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                if isEditing || parkrunInfoList.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Personal Information Section
                            personalInfoSection
                            
                            // QR Code and Barcode Selector and Display
                            qrCodeAndBarcodeSection
                            
                            // Watch sync status indicator
                            watchSyncIndicator
                        }
                        .padding()
                    }
                    .navigationTitle(isEditing ? "Edit Parkrun Info" : "Add Parkrun Info")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            cancelEdit()
                        }.disabled(parkrunInfoList.isEmpty),
                        trailing: Button("Confirm") {
                            print("Confirm button pressed with inputText: '\(inputText)'")
                            if !inputText.isEmpty && inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil {
                                print("Valid Parkrun ID format detected")
                                if name.isEmpty && !isLoadingName {
                                    print("Name is empty and not loading, triggering API lookup...")
                                    // Fetch data first, then show confirmation dialog
                                    fetchParkrunnerName(id: inputText) {
                                        print("API lookup completed, showing confirmation dialog")
                                        self.showConfirmationDialog = true
                                    }
                                } else if isLoadingName {
                                    print("Currently loading data, please wait...")
                                    // Do nothing, data is being fetched
                                } else {
                                    print("Name already available: '\(name)', showing confirmation dialog")
                                    print("Current data - name: '\(name)', totalParkruns: '\(totalParkruns)', lastEvent: '\(lastParkrunEvent)'")
                                    // Data already available, show confirmation dialog
                                    showConfirmationDialog = true
                                }
                            } else {
                                print("Invalid Parkrun ID format")
                                alertMessage = "Please enter a valid Parkrun ID first."
                                showAlert = true
                            }
                        }
                    )
                } else {
                    // Display Saved Data
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 15) {
                                // Personal Information Section
                                personalInfoSection
                                
                                // QR Code and Barcode Selector and Display
                                qrCodeAndBarcodeSection
                                
                                // Watch sync status indicator
                                watchSyncIndicator
                            }
                            .padding()
                        }
                        
                        // Send to Watch Button Section
                        sendToWatchSection
                    }
                    .navigationTitle("Parkrun Info")
                    .navigationBarItems(trailing: Button("Edit") {
                        startEdit()
                    })
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Invalid Input"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .confirmationDialog("Confirm Details", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
                Button("Save") {
                    saveParkrunInfo()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(confirmationMessage)
            }
            .onAppear {
                loadInitialData()
                WatchSessionManager.shared.startSession()
                checkForOnboarding()
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
        }
    }

    // MARK: - Personal Info Section
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Personal Information")
                .font(.headline)
                .padding(.bottom, 1)

            if isEditing {
                VStack(alignment: .leading, spacing: 5) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            TextField("Parkrun ID (e.g., A12345)", text: $inputText)
                                .keyboardType(.asciiCapable)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: inputText) { oldValue, newValue in
                                    // Clear data when ID changes or becomes invalid
                                    if newValue != oldValue {
                                        self.name = ""
                                        self.totalParkruns = ""
                                        self.lastParkrunDate = ""
                                        self.lastParkrunTime = ""
                                        self.lastParkrunEvent = ""
                                    }
                                }
                            
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
                        .padding(6)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(6)
                        
                        // Helper text
                        if !inputText.isEmpty && inputText.range(of: #"^A\d+$"#, options: .regularExpression) == nil {
                            Text("ID must start with 'A' followed by numbers")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 6)
                        } else if isLoadingName {
                            Text("Looking up runner details...")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.leading, 6)
                        } else if !name.isEmpty && inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil {
                            Text("Details found - ready to save")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.leading, 6)
                        } else if inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil {
                            Text("Press Confirm to lookup details")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.leading, 6)
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
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .frame(width: 90, alignment: .center)
                                    Text("Time")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .frame(width: 70, alignment: .center)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.quaternarySystemFill))
                                
                                // Data row
                                HStack(alignment: .center) {
                                    Text(lastParkrunEvent)
                                        .font(.body)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(lastParkrunDate)
                                        .font(.body)
                                        .frame(width: 90, alignment: .center)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(lastParkrunTime)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                        .frame(width: 70, alignment: .center)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color(.tertiarySystemBackground))
                            }
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                // Read-only display with horizontal layout for compact display
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Parkrun ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(inputText.isEmpty ? "Not set" : inputText)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(6)
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
                    Text(name.isEmpty ? "Not set" : name)
                        .font(.body)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(6)
                }
                
                if !lastParkrunDate.isEmpty && !lastParkrunTime.isEmpty && !lastParkrunEvent.isEmpty {
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
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .frame(width: 90, alignment: .center)
                                Text("Time")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .frame(width: 70, alignment: .center)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.quaternarySystemFill))
                            
                            // Data row
                            HStack(alignment: .center) {
                                Text(lastParkrunEvent)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(lastParkrunDate)
                                    .font(.body)
                                    .frame(width: 90, alignment: .center)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text(lastParkrunTime)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                    .frame(width: 70, alignment: .center)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(.tertiarySystemBackground))
                        }
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .frame(maxWidth: .infinity)
    }


    // MARK: - QR Code and Barcode Section
    private var qrCodeAndBarcodeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("Code Type", selection: $selectedCodeType) {
                Text("QR Code").tag(0)
                Text("Barcode").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 8)

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
            .frame(maxWidth: .infinity) // Center align QR/Barcode
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Watch Sync Indicator
    private var watchSyncIndicator: some View {
        Group {
            if watchSyncStatus != .idle {
                HStack(spacing: 8) {
                    switch watchSyncStatus {
                    case .sending:
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Sending to Watch...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    case .success:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Sent to Watch")
                            .font(.caption)
                            .foregroundColor(.green)
                    case .failed:
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Failed to send to Watch")
                            .font(.caption)
                            .foregroundColor(.red)
                    case .idle:
                        EmptyView()
                    }
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: watchSyncStatus)
            }
        }
    }
    
    // MARK: - Send to Watch Section
    private var sendToWatchSection: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                Button(action: {
                    sendToWatch()
                }) {
                    HStack(spacing: 8) {
                        if watchSyncStatus == .sending {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
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
                    .background(watchSyncStatus == .sending ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(watchSyncStatus == .sending || inputText.isEmpty)
                
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
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Watch Not Connected")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Functions
    private func loadInitialData() {
        if let savedInfo = parkrunInfoList.first {
            inputText = savedInfo.parkrunID
            name = savedInfo.name
            homeParkrun = savedInfo.homeParkrun
            selectedCountryCode = savedInfo.country ?? Country.unitedKingdom.rawValue
            totalParkruns = savedInfo.totalParkruns ?? ""
            lastParkrunDate = savedInfo.lastParkrunDate ?? ""
            lastParkrunTime = savedInfo.lastParkrunTime ?? ""
            lastParkrunEvent = savedInfo.lastParkrunEvent ?? ""
            
            print("DEBUG - loadInitialData: parkrunID='\(savedInfo.parkrunID)', name='\(savedInfo.name)'")
            print("DEBUG - loadInitialData: totalParkruns='\(savedInfo.totalParkruns ?? "nil")', lastEvent='\(savedInfo.lastParkrunEvent ?? "nil")'")
            print("DEBUG - loadInitialData: lastDate='\(savedInfo.lastParkrunDate ?? "nil")', lastTime='\(savedInfo.lastParkrunTime ?? "nil")'")
        } else {
            print("DEBUG - loadInitialData: No saved parkrun info found")
        }
    }
    
    private func checkForOnboarding() {
        // Show onboarding if no parkrun info exists
        if parkrunInfoList.isEmpty {
            showOnboarding = true
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
        if let existingInfo = parkrunInfoList.first {
            existingInfo.parkrunID = inputText
            existingInfo.name = name
            existingInfo.homeParkrun = homeParkrun
            existingInfo.country = selectedCountryCode
            existingInfo.totalParkruns = totalParkruns.isEmpty ? nil : totalParkruns
            existingInfo.lastParkrunDate = lastParkrunDate.isEmpty ? nil : lastParkrunDate
            existingInfo.lastParkrunTime = lastParkrunTime.isEmpty ? nil : lastParkrunTime
            existingInfo.lastParkrunEvent = lastParkrunEvent.isEmpty ? nil : lastParkrunEvent
        } else {
            let newInfo = ParkrunInfo(
                parkrunID: inputText, 
                name: name, 
                homeParkrun: homeParkrun, 
                country: selectedCountryCode,
                totalParkruns: totalParkruns.isEmpty ? nil : totalParkruns,
                lastParkrunDate: lastParkrunDate.isEmpty ? nil : lastParkrunDate,
                lastParkrunTime: lastParkrunTime.isEmpty ? nil : lastParkrunTime,
                lastParkrunEvent: lastParkrunEvent.isEmpty ? nil : lastParkrunEvent
            )
            modelContext.insert(newInfo)
        }

        do {
            try modelContext.save()
            isEditing = false
            
            // Send to watch with status tracking
            watchSyncStatus = .sending
            WatchSessionManager.shared.sendParkrunID(inputText) { success in
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
        WatchSessionManager.shared.sendParkrunID(inputText) { success in
            DispatchQueue.main.async {
                self.watchSyncStatus = success ? .success : .failed
                
                // Reset status after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.watchSyncStatus = .idle
                }
            }
        }
    }
    
    // MARK: - Parkrun API Functions
    private func fetchParkrunnerName(id: String, completion: (() -> Void)? = nil) {
        // Extract numeric part from ID (remove 'A' prefix)
        let numericId = String(id.dropFirst())
        
        isLoadingName = true
        
        let urlString = "https://www.parkrun.org.uk/parkrunner/\(numericId)/"
        guard let url = URL(string: urlString) else {
            isLoadingName = false
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
                self.isLoadingName = false
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
                completion?()
            }
        }.resume()
    }
    
    private func extractParkrunnerDataFromHTML(_ html: String) -> (name: String?, totalRuns: String?, lastDate: String?, lastTime: String?, lastEvent: String?) {
        var name: String?
        var totalRuns: String?
        var lastDate: String?
        var lastTime: String?
        var lastEvent: String?
        
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
        
        // If simple pattern didn't work, try complex pattern
        if totalRuns == nil {
            if let totalRegex = try? NSRegularExpression(pattern: #"<h3>(\d+)\s+parkruns?\s+total</h3>"#, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let totalMatches = totalRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                if let match = totalMatches.first, let totalRange = Range(match.range(at: 1), in: html) {
                    totalRuns = String(html[totalRange])
                    print("DEBUG - Extracted totalRuns: '\(totalRuns ?? "nil")' using complex pattern")
                } else {
                    print("DEBUG - No total parkruns match found with complex pattern")
                    // Let's search for any h3 tags to see what's actually there
                    if let debugRegex = try? NSRegularExpression(pattern: #"<h3[^>]*>([^<]+)</h3>"#, options: [.caseInsensitive]) {
                        let debugMatches = debugRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                        print("DEBUG - Found \(debugMatches.count) h3 tags")
                        for (index, debugMatch) in debugMatches.enumerated() {
                            if let debugRange = Range(debugMatch.range(at: 1), in: html) {
                                let content = String(html[debugRange])
                                print("DEBUG - h3[\(index)]: '\(content)'")
                                if content.contains("parkrun") {
                                    print("DEBUG - *** This h3 contains 'parkrun': '\(content)'")
                                }
                            }
                        }
                    }
                }
            } else {
                print("DEBUG - Failed to create complex total regex")
            }
        }
        
        // Extract most recent parkrun data from first row of results table
        // Try simple patterns for each piece of data
        
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
        
        // If simple patterns didn't work, try the complex pattern
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
                } else {
                    print("DEBUG - No recent parkrun match found with complex pattern")
                    // Debug: show first few table cells
                    if let debugRegex = try? NSRegularExpression(pattern: #"<td[^>]*>([^<]+)</td>"#, options: [.caseInsensitive]) {
                        let debugMatches = debugRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                        print("DEBUG - Found \(debugMatches.count) td elements, showing first 20:")
                        for (index, debugMatch) in debugMatches.prefix(20).enumerated() {
                            if let debugRange = Range(debugMatch.range(at: 1), in: html) {
                                let content = String(html[debugRange])
                                print("DEBUG - TD[\(index)]: '\(content)'")
                                if content.contains("parkrun") || content.contains("/") || content.contains(":") {
                                    print("DEBUG - *** Interesting TD[\(index)]: '\(content)'")
                                }
                            }
                        }
                    }
                }
            } else {
                print("DEBUG - Failed to create complex recent regex")
            }
        }
        
        print("DEBUG - Final extracted data: name='\(name ?? "nil")', totalRuns='\(totalRuns ?? "nil")', lastEvent='\(lastEvent ?? "nil")', lastDate='\(lastDate ?? "nil")', lastTime='\(lastTime ?? "nil")'")
        return (name: name, totalRuns: totalRuns, lastDate: lastDate, lastTime: lastTime, lastEvent: lastEvent)
    }

    // MARK: - QR & Barcode Generation
    private func generateQRCode(from string: String) -> PlatformImage? {
        guard !string.isEmpty else { return nil }
        qrCodeFilter.message = Data(string.utf8)
        guard let ciImage = qrCodeFilter.outputImage else { return nil }
        return convertToPlatformImage(from: ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10)))
    }

    private func generateBarcode(from string: String) -> PlatformImage? {
        guard !string.isEmpty else { return nil }
        barcodeFilter.message = Data(string.utf8)
        guard let ciImage = barcodeFilter.outputImage else { return nil }
        return convertToPlatformImage(from: ciImage.transformed(by: CGAffineTransform(scaleX: 2, y: 2)))
    }

    private func convertToPlatformImage(from ciImage: CIImage) -> PlatformImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: CGSize(width: ciImage.extent.width, height: ciImage.extent.height))
        #endif
    }
}

// MARK: - Reusable CodeSectionView
struct CodeSectionView: View {
    let title: String
    let image: PlatformImage?
    let size: CGSize

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            if let image = image {
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                #elseif os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                #endif
            } else {
                Text("Failed to generate \(title)")
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - SwiftUI Preview
struct QRCodeBarcodeView_Previews: PreviewProvider {
    static var previews: some View {
        do {
            let previewContainer = try ModelContainer(for: ParkrunInfo.self, configurations: ModelConfiguration())
            let context = previewContainer.mainContext

            // Insert sample data for preview
            let previewParkrunInfo = ParkrunInfo(parkrunID: "A12345", name: "John Doe", homeParkrun: "Southampton Parkrun", country: Country.unitedKingdom.rawValue)
            context.insert(previewParkrunInfo)

            return QRCodeBarcodeView()
                .modelContainer(previewContainer)
        } catch {
            fatalError("Failed to create SwiftData container for preview: \(error)")
        }
    }
}

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private override init() { super.init() }
    
    func startSession() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendParkrunID(_ id: String, completion: ((Bool) -> Void)? = nil) {
        print("Attempting to send Parkrun ID: \(id)")
        print("Session supported: \(WCSession.isSupported())")
        print("Session reachable: \(WCSession.default.isReachable)")
        print("Session activated: \(WCSession.default.activationState == .activated)")
        
        // Generate QR code image data
        guard let qrImage = generateQRCodeImage(from: id),
              let imageData = qrImage.pngData() else {
            print("Failed to generate QR code image")
            completion?(false)
            return
        }
        
        // Try both methods - transferUserInfo works even when not reachable
        if WCSession.default.activationState == .activated {
            let data: [String: Any] = [
                "parkrunID": id,
                "qrCodeImageData": imageData
            ]
            
            // Method 1: transferUserInfo (works when not immediately reachable)
            WCSession.default.transferUserInfo(data)
            print("User info transferred: \(id) with QR code image")
            
            // Method 2: sendMessage (only works when reachable)
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(data, replyHandler: { response in
                    print("Message sent successfully: \(response)")
                    completion?(true)
                }, errorHandler: { error in
                    print("Error sending message: \(error)")
                    completion?(false)
                })
            } else {
                print("Watch is not reachable for immediate messaging")
                // Still consider successful as transferUserInfo was called
                completion?(true)
            }
        } else {
            print("Session not activated")
            completion?(false)
        }
    }
    
    private func generateQRCodeImage(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }
        
        let context = CIContext()
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        qrCodeFilter.message = Data(string.utf8)
        
        guard let ciImage = qrCodeFilter.outputImage else { return nil }
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("iOS: Session activated with state: \(activationState.rawValue)")
        if let error = error {
            print("iOS: Activation error: \(error)")
        }
        print("iOS: Session reachable: \(session.isReachable)")
        print("iOS: Session paired: \(session.isPaired)")
        print("iOS: Session installed: \(session.isWatchAppInstalled)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("iOS: Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("iOS: Session deactivated")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("iOS: Reachability changed to: \(session.isReachable)")
    }
}
