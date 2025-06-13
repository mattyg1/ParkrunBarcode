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

// Add animation constants
struct AnimationConstants {
    static let cardTransition = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.8).combined(with: .opacity),
        removal: .scale(scale: 0.8).combined(with: .opacity)
    )
    static let slideTransition = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )
    static let fadeTransition = AnyTransition.opacity
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let easeAnimation = Animation.easeInOut(duration: 0.2)
}

// Add custom color scheme
extension Color {
    static let parkrunGreen = Color(red: 0.2, green: 0.6, blue: 0.2)
    static let parkrunLightGreen = Color(red: 0.9, green: 1.0, blue: 0.9)
    static let cardBackground = Color(.systemBackground)
    static let secondaryCardBackground = Color(.secondarySystemBackground)
}

// Add custom view modifiers
struct CardModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(isPressed ? 0.05 : 0.1), radius: isPressed ? 3 : 5, x: 0, y: isPressed ? 1 : 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AnimationConstants.springAnimation, value: isPressed)
            .onTapGesture {
                withAnimation(AnimationConstants.springAnimation) {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
            }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

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
    @State private var lastParkrunEventURL: String = ""
    @State private var watchSyncStatus: WatchSyncStatus = .idle
    @State private var showOnboarding: Bool = false
    @State private var isAnimating = false

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
            ScrollView {
                VStack(spacing: 20) {
                    if isEditing || parkrunInfoList.isEmpty {
                        // Personal Information Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personal Information")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.parkrunGreen)
                            
                            personalInfoSection
                        }
                        .cardStyle()
                        .transition(AnimationConstants.cardTransition)
                        
                        // QR Code Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Code")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.parkrunGreen)
                            
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
                                .foregroundColor(.parkrunGreen)
                            
                            watchSyncIndicator
                        }
                        .cardStyle()
                        .transition(AnimationConstants.cardTransition)
                    } else {
                        // Display Saved Data
                        VStack(spacing: 20) {
                            // Personal Information Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Personal Information")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.parkrunGreen)
                                
                                personalInfoSection
                            }
                            .cardStyle()
                            
                            // QR Code Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Code")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.parkrunGreen)
                                
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
                                    .foregroundColor(.parkrunGreen)
                                
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
            .navigationBarItems(trailing: !isEditing ? Button("Edit") {
                withAnimation(AnimationConstants.springAnimation) {
                    startEdit()
                }
            } : nil)
            .background(Color(.systemGroupedBackground))
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
    }

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
                                    Button(action: {
                                        openEventResults()
                                    }) {
                                        HStack {
                                            Text(lastParkrunEvent)
                                                .font(.body)
                                                .foregroundColor(.blue)
                                                .lineLimit(2)
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
                                    .onAppear {
                                        print("DEBUG - Button 1 render: lastParkrunEvent='\(lastParkrunEvent)', lastParkrunEventURL='\(lastParkrunEventURL)', disabled=\(lastParkrunEventURL.isEmpty)")
                                    }
                                    Text(lastParkrunDate)
                                        .font(.body)
                                        .frame(width: 90, alignment: .center)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(lastParkrunTime)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
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
                .transition(AnimationConstants.fadeTransition)
            } else {
                // Read-only display with horizontal layout for compact display
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
                                Button(action: {
                                    openEventResults()
                                }) {
                                    HStack {
                                        Text(lastParkrunEvent)
                                            .font(.body)
                                            .foregroundColor(.blue)
                                            .lineLimit(2)
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
                                .onAppear {
                                    print("DEBUG - Button 2 render: lastParkrunEvent='\(lastParkrunEvent)', lastParkrunEventURL='\(lastParkrunEventURL)', disabled=\(lastParkrunEventURL.isEmpty)")
                                }
                                Text(lastParkrunDate)
                                    .font(.body)
                                    .frame(width: 90, alignment: .center)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text(lastParkrunTime)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
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
            .transition(AnimationConstants.fadeTransition)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .frame(maxWidth: .infinity)
    }


    // MARK: - QR Code and Barcode Section
    private var qrCodeAndBarcodeSection: some View {
        VStack(spacing: 16) {
            Picker("Code Type", selection: $selectedCodeType) {
                Text("QR Code").tag(0)
                Text("Barcode").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .transition(AnimationConstants.fadeTransition)
            
            HStack {
                if selectedCodeType == 0 {
                    CodeSectionView(
                        title: "",
                        image: generateQRCode(from: inputText),
                        size: CGSize(width: 200, height: 200)
                    )
                    .transition(AnimationConstants.fadeTransition)
                } else {
                    CodeSectionView(
                        title: "",
                        image: generateBarcode(from: inputText),
                        size: CGSize(width: 300, height: 100)
                    )
                    .transition(AnimationConstants.fadeTransition)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(AnimationConstants.springAnimation, value: selectedCodeType)
        }
    }
    
    // MARK: - Watch Sync Indicator
    private var watchSyncIndicator: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal)
                .transition(AnimationConstants.fadeTransition)
            
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
                    .transition(AnimationConstants.fadeTransition)
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
                        .transition(AnimationConstants.fadeTransition)
                        
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
                        .transition(AnimationConstants.fadeTransition)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            .animation(AnimationConstants.springAnimation, value: WCSession.default.isReachable)
        }
        .background(Color(.systemBackground))
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
                            .foregroundColor(.white)
                            .transition(AnimationConstants.fadeTransition)
                    } else {
                        Image(systemName: "applewatch")
                            .font(.title3)
                            .transition(AnimationConstants.fadeTransition)
                    }
                    
                    Text(watchSyncStatus == .sending ? "Sending..." : "Send to Watch")
                        .font(.headline)
                        .fontWeight(.medium)
                        .transition(AnimationConstants.fadeTransition)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(watchSyncStatus == .sending ? Color.gray : Color.parkrunGreen)
                .cornerRadius(12)
            }
            .disabled(watchSyncStatus == .sending || inputText.isEmpty)
            .animation(AnimationConstants.springAnimation, value: watchSyncStatus)
        }
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
            lastParkrunEventURL = savedInfo.lastParkrunEventURL ?? ""
            
            print("DEBUG - loadInitialData: parkrunID='\(savedInfo.parkrunID)', name='\(savedInfo.name)'")
            print("DEBUG - loadInitialData: totalParkruns='\(savedInfo.totalParkruns ?? "nil")', lastEvent='\(savedInfo.lastParkrunEvent ?? "nil")'")
            print("DEBUG - loadInitialData: lastDate='\(savedInfo.lastParkrunDate ?? "nil")', lastTime='\(savedInfo.lastParkrunTime ?? "nil")'")
            print("DEBUG - loadInitialData: lastParkrunEventURL='\(savedInfo.lastParkrunEventURL ?? "nil")' -> '\(lastParkrunEventURL)'")
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
    
    private func refreshEventDataIfNeeded() {
        // Only refresh if we have a valid parkrun ID and we're not currently editing
        guard !inputText.isEmpty, 
              inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil,
              !isEditing,
              !isLoadingName else {
            print("DEBUG - refreshEventDataIfNeeded: Skipping refresh - invalid ID or currently editing")
            return
        }
        
        print("DEBUG - refreshEventDataIfNeeded: Refreshing event data for ID: \(inputText)")
        
        // Refresh the parkrun data in background without showing loading indicators
        fetchParkrunnerName(id: inputText, showLoadingIndicator: false) {
            print("DEBUG - refreshEventDataIfNeeded: Background refresh completed")
            // Auto-save the updated data
            DispatchQueue.main.async {
                self.saveUpdatedDataSilently()
            }
        }
    }
    
    private func saveUpdatedDataSilently() {
        // Save updated data without triggering UI changes or watch sync
        if let existingInfo = parkrunInfoList.first {
            existingInfo.name = name
            existingInfo.totalParkruns = totalParkruns.isEmpty ? nil : totalParkruns
            existingInfo.lastParkrunDate = lastParkrunDate.isEmpty ? nil : lastParkrunDate
            existingInfo.lastParkrunTime = lastParkrunTime.isEmpty ? nil : lastParkrunTime
            existingInfo.lastParkrunEvent = lastParkrunEvent.isEmpty ? nil : lastParkrunEvent
            existingInfo.lastParkrunEventURL = lastParkrunEventURL.isEmpty ? nil : lastParkrunEventURL
            
            do {
                try modelContext.save()
                print("DEBUG - saveUpdatedDataSilently: Successfully saved refreshed data")
            } catch {
                print("DEBUG - saveUpdatedDataSilently: Failed to save refreshed data: \(error)")
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
        if let existingInfo = parkrunInfoList.first {
            existingInfo.parkrunID = inputText
            existingInfo.name = name
            existingInfo.homeParkrun = homeParkrun
            existingInfo.country = selectedCountryCode
            existingInfo.totalParkruns = totalParkruns.isEmpty ? nil : totalParkruns
            existingInfo.lastParkrunDate = lastParkrunDate.isEmpty ? nil : lastParkrunDate
            existingInfo.lastParkrunTime = lastParkrunTime.isEmpty ? nil : lastParkrunTime
            existingInfo.lastParkrunEvent = lastParkrunEvent.isEmpty ? nil : lastParkrunEvent
            existingInfo.lastParkrunEventURL = lastParkrunEventURL.isEmpty ? nil : lastParkrunEventURL
        } else {
            let newInfo = ParkrunInfo(
                parkrunID: inputText, 
                name: name, 
                homeParkrun: homeParkrun, 
                country: selectedCountryCode,
                totalParkruns: totalParkruns.isEmpty ? nil : totalParkruns,
                lastParkrunDate: lastParkrunDate.isEmpty ? nil : lastParkrunDate,
                lastParkrunTime: lastParkrunTime.isEmpty ? nil : lastParkrunTime,
                lastParkrunEvent: lastParkrunEvent.isEmpty ? nil : lastParkrunEvent,
                lastParkrunEventURL: lastParkrunEventURL.isEmpty ? nil : lastParkrunEventURL
            )
            modelContext.insert(newInfo)
        }

        do {
            try modelContext.save()
            isEditing = false
            
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
        
        // Look for event results URL from date link pattern: <td><a href="https://www.parkrun.org.uk/gangerfarm/results/133/" target="_top">07/06/2025</a></td>
        // Support multiple parkrun domains: .org.uk, .com, .us, .au, etc.
        if let eventURLRegex = try? NSRegularExpression(pattern: #"<td><a href="(https://www\.parkrun\.(?:org\.uk|com|us|au|org\.nz|co\.za|it|se|dk|pl|ie|ca|fi|fr|sg|de|no|ru|my)/[^/]+/results/\d+/)"[^>]*>\d{2}/\d{2}/\d{4}</a></td>"#, options: [.caseInsensitive]) {
            let urlMatches = eventURLRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = urlMatches.first, let urlRange = Range(match.range(at: 1), in: html) {
                lastEventURL = String(html[urlRange])
                print("DEBUG - Extracted lastEventURL: '\(lastEventURL ?? "nil")' using corrected pattern with <td> wrapper")
            } else {
                print("DEBUG - No event URL match found with <td> wrapper pattern, trying simpler pattern")
                // Try without <td> wrapper
                if let simpleURLRegex = try? NSRegularExpression(pattern: #"<a href="(https://www\.parkrun\.(?:org\.uk|com|us|au|org\.nz|co\.za|it|se|dk|pl|ie|ca|fi|fr|sg|de|no|ru|my)/[^/]+/results/\d+/)"[^>]*>\d{2}/\d{2}/\d{4}</a>"#, options: [.caseInsensitive]) {
                    let simpleMatches = simpleURLRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                    if let match = simpleMatches.first, let urlRange = Range(match.range(at: 1), in: html) {
                        lastEventURL = String(html[urlRange])
                        print("DEBUG - Extracted lastEventURL: '\(lastEventURL ?? "nil")' using simple pattern without <td>")
                    } else {
                        print("DEBUG - No event URL match found with simple pattern either")
                    }
                }
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
                    
                    // Also try to extract URL if not already found
                    if lastEventURL == nil {
                        let fullMatch = String(html[Range(match.range(at: 0), in: html)!])
                        if let urlMatch = fullMatch.range(of: #"https://www\.parkrun\.(?:org\.uk|com|us|au|org\.nz|co\.za|it|se|dk|pl|ie|ca|fi|fr|sg|de|no|ru|my)/[^/]+/results/\d+/"#, options: .regularExpression) {
                            lastEventURL = String(fullMatch[urlMatch])
                            print("DEBUG - Extracted lastEventURL: '\(lastEventURL ?? "nil")' from complex pattern")
                        }
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
        
        print("DEBUG - Final extracted data: name='\(name ?? "nil")', totalRuns='\(totalRuns ?? "nil")', lastEvent='\(lastEvent ?? "nil")', lastDate='\(lastDate ?? "nil")', lastTime='\(lastTime ?? "nil")', lastEventURL='\(lastEventURL ?? "nil")'")
        return (name: name, totalRuns: totalRuns, lastDate: lastDate, lastTime: lastTime, lastEvent: lastEvent, lastEventURL: lastEventURL)
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
    @State private var isAnimating = false

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
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .scaleEffect(isAnimating ? 1.0 : 0.95)
                    .opacity(isAnimating ? 1.0 : 0.8)
                    .animation(AnimationConstants.springAnimation, value: isAnimating)
                    .onAppear {
                        isAnimating = true
                    }
                #elseif os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .scaleEffect(isAnimating ? 1.0 : 0.95)
                    .opacity(isAnimating ? 1.0 : 0.8)
                    .animation(AnimationConstants.springAnimation, value: isAnimating)
                    .onAppear {
                        isAnimating = true
                    }
                #endif
            } else {
                Text("Failed to generate \(title)")
                    .foregroundColor(.red)
                    .transition(AnimationConstants.fadeTransition)
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
    
    func sendParkrunID(_ id: String, userName: String = "", completion: ((Bool) -> Void)? = nil) {
        print("Attempting to send Parkrun ID: \(id), userName: \(userName)")
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
            var data: [String: Any] = [
                "parkrunID": id,
                "qrCodeImageData": imageData
            ]
            
            // Add user name if available
            if !userName.isEmpty {
                data["userName"] = userName
            }
            
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
    
    func sendParkrunIDForQRDisplay(_ id: String, userName: String = "") {
        print("Sending Parkrun ID for QR display: \(id), userName: \(userName)")
        
        // Generate QR code image data
        guard let qrImage = generateQRCodeImage(from: id),
              let imageData = qrImage.pngData() else {
            print("Failed to generate QR code image for display")
            return
        }
        
        if WCSession.default.activationState == .activated {
            var data: [String: Any] = [
                "parkrunID": id,
                "qrCodeImageData": imageData,
                "showQRImmediately": true  // Special flag for immediate QR display
            ]
            
            // Add user name if available
            if !userName.isEmpty {
                data["userName"] = userName
            }
            
            // Use transferUserInfo for reliability when watch might not be immediately reachable
            WCSession.default.transferUserInfo(data)
            print("QR display data transferred to watch: \(id)")
            
            // Also try immediate message if reachable
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(data, replyHandler: { response in
                    print("QR display message sent successfully: \(response)")
                }, errorHandler: { error in
                    print("Error sending QR display message: \(error)")
                })
            }
        } else {
            print("Session not activated for QR display")
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
