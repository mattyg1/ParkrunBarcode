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

// Add custom color scheme with dark mode support
extension Color {
    static let parkrunGreen = Color(red: 0.2, green: 0.6, blue: 0.2)
    static let parkrunLightGreen = Color(red: 0.9, green: 1.0, blue: 0.9)
    static let cardBackground = Color(.systemBackground)
    static let secondaryCardBackground = Color(.secondarySystemBackground)
    
    // Dark mode enhanced colors
    static let parkrunGreenDark = Color(red: 0.3, green: 0.7, blue: 0.3)
    static let parkrunLightGreenDark = Color(red: 0.1, green: 0.2, blue: 0.1)
    static let cardBackgroundDark = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let secondaryCardBackgroundDark = Color(red: 0.15, green: 0.15, blue: 0.15)
    
    // Adaptive colors that work with both light and dark modes
    static var adaptiveParkrunGreen: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(Color.parkrunGreenDark) : UIColor(Color.parkrunGreen)
        })
    }
    
    static var adaptiveParkrunBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(Color.parkrunLightGreenDark) : UIColor(Color.parkrunLightGreen)
        })
    }
    
    static var adaptiveCardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(Color.cardBackgroundDark) : UIColor(Color.cardBackground)
        })
    }
    
    static var adaptiveSecondaryCardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(Color.secondaryCardBackgroundDark) : UIColor(Color.secondaryCardBackground)
        })
    }
    
    // Enhanced text colors for better dark mode readability
    static var adaptivePrimaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        })
    }
    
    static var adaptiveSecondaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor.lightGray : UIColor.gray
        })
    }
}

// Add custom view modifiers
struct CardModifier: ViewModifier {
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.adaptiveCardBackground)
            .cornerRadius(16)
            .shadow(
                color: colorScheme == .dark ? 
                    Color.white.opacity(isPressed ? 0.02 : 0.05) : 
                    Color.black.opacity(isPressed ? 0.05 : 0.1), 
                radius: isPressed ? 3 : 5, 
                x: 0, 
                y: isPressed ? 1 : 2
            )
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
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var inputText: String = ""
    @State private var name: String = ""
    @State private var homeParkrun: String = ""
    @State private var selectedCountryCode: Int = Country.unitedKingdom.rawValue // Default to UK
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
    @State private var isAnimating = false
    @State private var preferredColorScheme: ColorScheme?
    @State private var showNotificationSettings = false
    @State private var showUserSelection = false
    @State private var showAddUser = false
    @State private var selectedUserID: String = ""
    @State private var currentlyViewingUserID: String = "" // Currently displayed user (can be different from default)
    
    // Temporary variables to hold fetched data until user hits Save
    @State private var tempName: String = ""
    @State private var tempTotalParkruns: String = ""
    @State private var tempLastParkrunDate: String = ""
    @State private var tempLastParkrunTime: String = ""
    @State private var tempLastParkrunEvent: String = ""
    @State private var tempLastParkrunEventURL: String = ""

    private let context = CIContext()
    private let qrCodeFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()
    
    // Computed properties for user management
    private var currentUser: ParkrunInfo? {
        // If we're viewing a specific user, return that user
        if !currentlyViewingUserID.isEmpty {
            return parkrunInfoList.first(where: { $0.parkrunID == currentlyViewingUserID })
        }
        
        // Otherwise, return the default user
        if let defaultUser = parkrunInfoList.first(where: { $0.isDefault }) {
            return defaultUser
        }
        return parkrunInfoList.first
    }
    
    private var defaultUser: ParkrunInfo? {
        if let defaultUser = parkrunInfoList.first(where: { $0.isDefault }) {
            return defaultUser
        }
        return parkrunInfoList.first
    }
    
    private var hasMultipleUsers: Bool {
        parkrunInfoList.count > 1
    }
    
    private var availableUsers: [ParkrunInfo] {
        parkrunInfoList.sorted { $0.createdDate < $1.createdDate }
    }
    
    private var confirmationMessage: String {
        var message = "Please confirm your details:\n\nParkrun ID: \(inputText)"
        
        if !tempName.isEmpty {
            message += "\nName: \(tempName)"
        }
        
        print("DEBUG - confirmationMessage: tempTotalParkruns='\(tempTotalParkruns)', isEmpty=\(tempTotalParkruns.isEmpty)")
        if !tempTotalParkruns.isEmpty {
            message += "\nTotal Parkruns: \(tempTotalParkruns)"
        }
        
        print("DEBUG - confirmationMessage: tempLastParkrunDate='\(tempLastParkrunDate)', tempLastParkrunTime='\(tempLastParkrunTime)', tempLastParkrunEvent='\(tempLastParkrunEvent)'")
        if !tempLastParkrunDate.isEmpty && !tempLastParkrunTime.isEmpty && !tempLastParkrunEvent.isEmpty {
            message += "\nLast Parkrun: \(tempLastParkrunEvent)"
            message += "\nDate: \(tempLastParkrunDate), Time: \(tempLastParkrunTime)"
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
                        
                        // Notifications Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notifications")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.adaptiveParkrunGreen)
                            
                            notificationSettingsSection
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
                                    .foregroundColor(.adaptiveParkrunGreen)
                                
                                personalInfoSection
                            }
                            .cardStyle()
                            
                            // QR Code Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Code")
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
                            
                            // Notifications Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notifications")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.adaptiveParkrunGreen)
                                
                                notificationSettingsSection
                            }
                            .cardStyle()
                            
                            // User Selection Card (show at bottom)
                            if !parkrunInfoList.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Parkrun Users")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.adaptiveParkrunGreen)
                                        
                                        Spacer()
                                        
                                        // User count indicator
                                        Text("\(parkrunInfoList.count)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(minWidth: 20, minHeight: 20)
                                            .background(Color.adaptiveParkrunGreen)
                                            .clipShape(Circle())
                                    }
                                    
                                    userSelectionSection
                                }
                                .cardStyle()
                            }
                        }
                        .transition(AnimationConstants.slideTransition)
                    }
                }
                .padding()
                .animation(AnimationConstants.springAnimation, value: isEditing)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            withAnimation(AnimationConstants.springAnimation) {
                                cancelEdit()
                            }
                        }
                    } else {
                        Button(action: toggleTheme) {
                            Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                                .foregroundColor(.adaptiveParkrunGreen)
                                .font(.title3)
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
            .preferredColorScheme(preferredColorScheme)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Invalid Input"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Confirm Details", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
            Button("Save") {
                saveParkrunInfo()
            }
            Button("Cancel", role: .cancel) {
                // Clear temporary variables and return to add barcode screen
                tempName = ""
                tempTotalParkruns = ""
                tempLastParkrunDate = ""
                tempLastParkrunTime = ""
                tempLastParkrunEvent = ""
                tempLastParkrunEventURL = ""
                
                // Clear main variables and return to onboarding
                name = ""
                totalParkruns = ""
                lastParkrunDate = ""
                lastParkrunTime = ""
                lastParkrunEvent = ""
                lastParkrunEventURL = ""
                inputText = ""
                
                // Show onboarding again
                showOnboarding = true
            }
        } message: {
            Text(confirmationMessage)
        }
        .onAppear {
            // Only load initial data if we're not in the middle of onboarding flow
            if !isEditing && tempName.isEmpty {
                loadInitialData()
            }
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
        .sheet(isPresented: $showUserSelection) {
            UserSelectionView(
                users: availableUsers,
                currentUser: currentUser,
                isPresented: $showUserSelection,
                onUserSelected: { user in
                    switchToUser(user)
                },
                onDeleteUser: { user in
                    deleteUser(user)
                },
                onSetDefault: { user in
                    setDefaultUser(user)
                }
            )
        }
        .sheet(isPresented: $showAddUser) {
            AddUserView(isPresented: $showAddUser) { parkrunID in
                addNewUser(parkrunID: parkrunID)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SetParkrunID"))) { notification in
            if let parkrunID = notification.object as? String {
                inputText = parkrunID
                // Clear existing data but don't fetch automatically - wait for user to trigger it
                name = ""
                totalParkruns = ""
                lastParkrunDate = ""
                lastParkrunTime = ""
                lastParkrunEvent = ""
                lastParkrunEventURL = ""
                
                // Clear temporary variables
                tempName = ""
                tempTotalParkruns = ""
                tempLastParkrunDate = ""
                tempLastParkrunTime = ""
                tempLastParkrunEvent = ""
                tempLastParkrunEventURL = ""
                
                // Trigger edit mode to show the new ID
                isEditing = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SetParkrunIDWithConfirmation"))) { notification in
            if let parkrunID = notification.object as? String {
                print("DEBUG: SetParkrunIDWithConfirmation received with ID: \(parkrunID)")
                inputText = parkrunID
                // Clear existing data (both main and temp variables)
                name = ""
                totalParkruns = ""
                lastParkrunDate = ""
                lastParkrunTime = ""
                lastParkrunEvent = ""
                lastParkrunEventURL = ""
                print("DEBUG: Cleared main variables")
                
                // Clear temporary variables
                tempName = ""
                tempTotalParkruns = ""
                tempLastParkrunDate = ""
                tempLastParkrunTime = ""
                tempLastParkrunEvent = ""
                tempLastParkrunEventURL = ""
                print("DEBUG: Cleared temp variables")
                
                // Trigger edit mode to show the new ID
                isEditing = true
                print("DEBUG: Set isEditing = true")
                
                // Fetch data for the ID and show confirmation dialog when done
                fetchParkrunnerName(id: parkrunID) {
                    // Show confirmation dialog after API call completes
                    print("DEBUG: API lookup completed, tempName='\(self.tempName)', name='\(self.name)'")
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
                                if !tempName.isEmpty {
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
                        Text(tempName.isEmpty ? "Auto-filled from Parkrun ID" : tempName)
                            .font(.body)
                            .foregroundColor(tempName.isEmpty ? .secondary : .primary)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(6)
                    }
                    
                    // Show total parkruns if available
                    if !tempTotalParkruns.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Parkruns")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(tempTotalParkruns)
                                .font(.body)
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(6)
                        }
                    }
                    
                    // Show last parkrun table if data is available
                    if !tempLastParkrunDate.isEmpty && !tempLastParkrunTime.isEmpty && !tempLastParkrunEvent.isEmpty {
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
                                            Text(tempLastParkrunEvent)
                                                .font(.body)
                                                .foregroundColor(.blue)
                                                .lineLimit(2)
                                                .minimumScaleFactor(0.7)
                                                .fixedSize(horizontal: false, vertical: true)
                                            
                                            if !tempLastParkrunEventURL.isEmpty {
                                                Image(systemName: "safari")
                                                    .font(.caption2)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(tempLastParkrunEventURL.isEmpty)
                                    .onAppear {
                                        print("DEBUG - Button 1 render: lastParkrunEvent='\(lastParkrunEvent)', lastParkrunEventURL='\(lastParkrunEventURL)', disabled=\(lastParkrunEventURL.isEmpty)")
                                    }
                                    Text(tempLastParkrunDate)
                                        .font(.caption)
                                        .frame(width: 75, alignment: .center)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                    Text(tempLastParkrunTime)
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
                                .onAppear {
                                    print("DEBUG - Button 2 render: lastParkrunEvent='\(lastParkrunEvent)', lastParkrunEventURL='\(lastParkrunEventURL)', disabled=\(lastParkrunEventURL.isEmpty)")
                                }
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
            }
        }
        .padding(10)
        .background(Color.adaptiveCardBackground)
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
    
    // MARK: - User Selection Section
    private var userSelectionSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Active User")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Menu {
                        // User selection options
                        ForEach(availableUsers, id: \.parkrunID) { user in
                            Button(action: {
                                switchToUser(user)
                            }) {
                                HStack {
                                    Text(user.displayName)
                                    if user.parkrunID == currentUser?.parkrunID {
                                        Image(systemName: "eye.fill") // Currently viewing
                                    }
                                    if user.isDefault {
                                        Image(systemName: "star.fill") // Default user
                                    }
                                }
                            }
                        }
                        
                        if !availableUsers.isEmpty {
                            Divider()
                        }
                        
                        // Management options
                        Button(action: {
                            showAddUser = true
                        }) {
                            Label("Add User", systemImage: "plus.circle")
                        }
                        
                        if hasMultipleUsers {
                            Button(action: {
                                showUserSelection = true
                            }) {
                                Label("Manage Users", systemImage: "person.2.circle")
                            }
                        }
                        
                    } label: {
                        HStack {
                            Text(currentUser?.displayName ?? "No User Selected")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .background(Color.adaptiveCardBackground)
    }
    
    // MARK: - Notification Settings Section
    private var notificationSettingsSection: some View {
        VStack(spacing: 12) {
            // Permission status
            HStack {
                Image(systemName: notificationManager.hasPermission ? "bell.fill" : "bell.slash")
                    .foregroundColor(notificationManager.hasPermission ? .green : .red)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(notificationManager.hasPermission ? "Notifications Enabled" : "Notifications Disabled")
                        .font(.body)
                        .fontWeight(.medium)
                    Text(notificationManager.hasPermission ? "You'll receive parkrun reminders and updates" : "Enable to get parkrun reminders and result updates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.horizontal)
            
            // Notification controls
            VStack(spacing: 8) {
                if !notificationManager.hasPermission {
                    Button(action: {
                        Task {
                            await notificationManager.requestNotificationPermission()
                            if notificationManager.hasPermission {
                                setupNotificationsForCurrentUser()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bell.badge")
                                .font(.title3)
                            Text("Enable Notifications")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.adaptiveParkrunGreen)
                        .cornerRadius(12)
                    }
                } else {
                    // Toggle for Saturday reminders
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Saturday Reminders")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Get reminded before parkrun starts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationManager.isNotificationsEnabled)
                            .labelsHidden()
                            .onChange(of: notificationManager.isNotificationsEnabled) { oldValue, newValue in
                                // Save the setting
                                UserDefaults.standard.set(newValue, forKey: "isNotificationsEnabled")
                                
                                if newValue {
                                    notificationManager.scheduleSaturdayReminders()
                                    setupNotificationsForCurrentUser()
                                } else {
                                    notificationManager.cancelSaturdayReminders()
                                }
                            }
                    }
                    
                    // Result notifications info
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Result Updates")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Get notified when new results may be available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color.adaptiveCardBackground)
    }

    // MARK: - Functions
    private func toggleTheme() {
        withAnimation(AnimationConstants.springAnimation) {
            switch preferredColorScheme {
            case .none:
                preferredColorScheme = colorScheme == .dark ? .light : .dark
            case .light:
                preferredColorScheme = .dark
            case .dark:
                preferredColorScheme = .light
            @unknown default:
                preferredColorScheme = .dark
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
    
    // MARK: - User Management Functions
    
    private func switchToUser(_ user: ParkrunInfo) {
        // Temporarily switch to viewing this user (don't change default)
        currentlyViewingUserID = user.parkrunID
        loadInitialData()
        print("Temporarily viewing user: \(user.displayName)")
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
    
    private func addNewUser(parkrunID: String) {
        // Don't change default user when adding - new user is not default unless explicitly set
        
        // Create new user with the given ID (not default by default)
        let newUser = ParkrunInfo(
            parkrunID: parkrunID,
            name: "", // Will be filled when user saves
            homeParkrun: "",
            country: Country.unitedKingdom.rawValue,
            isDefault: false
        )
        
        modelContext.insert(newUser)
        
        do {
            try modelContext.save()
            
            // Temporarily switch to the new user for editing (but don't make them default yet)
            switchToUser(newUser)
            
            // Switch to editing mode for the new user
            isEditing = true
            
            // Fetch data for the new user
            fetchParkrunnerName(id: parkrunID)
            
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
                loadInitialData()
            }
            
            print("Deleted user: \(user.displayName)")
        } catch {
            print("Failed to delete user: \(error)")
        }
    }
    
    private func loadInitialData() {
        print("DEBUG - loadInitialData: Found \(parkrunInfoList.count) users")
        
        // Migrate existing data if needed
        migrateExistingUsersIfNeeded()
        
        // Reset to default user on app startup (clear any temporary viewing)
        if currentlyViewingUserID.isEmpty {
            // If no default user exists but users exist, set the first one as default
            if defaultUser == nil && !parkrunInfoList.isEmpty {
                parkrunInfoList.first?.isDefault = true
                do {
                    try modelContext.save()
                    print("DEBUG - Auto-set first user as default")
                } catch {
                    print("Failed to set default user: \(error)")
                }
            }
        }
        
        if let savedInfo = currentUser {
            inputText = savedInfo.parkrunID
            name = savedInfo.name
            homeParkrun = savedInfo.homeParkrun
            selectedCountryCode = savedInfo.country ?? Country.unitedKingdom.rawValue
            totalParkruns = savedInfo.totalParkruns ?? ""
            lastParkrunDate = savedInfo.lastParkrunDate ?? ""
            lastParkrunTime = savedInfo.lastParkrunTime ?? ""
            lastParkrunEvent = savedInfo.lastParkrunEvent ?? ""
            lastParkrunEventURL = savedInfo.lastParkrunEventURL ?? ""
            
            print("DEBUG - loadInitialData: Loaded user - parkrunID='\(savedInfo.parkrunID)', name='\(savedInfo.name)'")
            print("DEBUG - loadInitialData: totalParkruns='\(savedInfo.totalParkruns ?? "nil")', lastEvent='\(savedInfo.lastParkrunEvent ?? "nil")'")
        } else {
            print("DEBUG - loadInitialData: No current user found")
        }
    }
    
    private func migrateExistingUsersIfNeeded() {
        // Update display names and ensure proper defaults for existing users
        var needsSave = false
        
        for user in parkrunInfoList {
            if user.displayName.isEmpty {
                user.updateDisplayName()
                needsSave = true
            }
        }
        
        // If no user is marked as default, make the first one default
        if !parkrunInfoList.contains(where: { $0.isDefault }) && !parkrunInfoList.isEmpty {
            parkrunInfoList.first?.isDefault = true
            needsSave = true
        }
        
        if needsSave {
            do {
                try modelContext.save()
                print("DEBUG - Migrated existing user data and set default user")
            } catch {
                print("Failed to migrate user data: \(error)")
            }
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
        // Copy data from temporary variables to main variables
        name = tempName
        totalParkruns = tempTotalParkruns
        lastParkrunDate = tempLastParkrunDate
        lastParkrunTime = tempLastParkrunTime
        lastParkrunEvent = tempLastParkrunEvent
        lastParkrunEventURL = tempLastParkrunEventURL
        
        if let existingInfo = currentUser {
            existingInfo.parkrunID = inputText
            existingInfo.name = name
            existingInfo.homeParkrun = homeParkrun
            existingInfo.country = selectedCountryCode
            existingInfo.totalParkruns = totalParkruns.isEmpty ? nil : totalParkruns
            existingInfo.lastParkrunDate = lastParkrunDate.isEmpty ? nil : lastParkrunDate
            existingInfo.lastParkrunTime = lastParkrunTime.isEmpty ? nil : lastParkrunTime
            existingInfo.lastParkrunEvent = lastParkrunEvent.isEmpty ? nil : lastParkrunEvent
            existingInfo.lastParkrunEventURL = lastParkrunEventURL.isEmpty ? nil : lastParkrunEventURL
            existingInfo.updateDisplayName() // Update display name
        } else {
            // For new users, only make them default if this is the first user
            let isFirstUser = parkrunInfoList.isEmpty
            
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
                isDefault: isFirstUser // Only first user is default automatically
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
            
            // Only automatically send to watch for the first user
            if parkrunInfoList.count == 1 {
                // Send to watch with status tracking (first user only)
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
            } else {
                // For additional users, just reset watch sync status
                watchSyncStatus = .idle
                print("Additional user saved. Use 'Send to Watch' button to sync QR code to watch.")
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
                // Accept both HTTP 200 (OK) and 202 (Accepted) responses
                // HTTP 202 is returned by AWS WAF when challenge action is triggered (e.g., VPN usage)
                if httpResponse.statusCode != 200 && httpResponse.statusCode != 202 {
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
                    self.tempName = name
                    print("Successfully extracted name: \(name)")
                }
                if let totalRuns = extractedData.totalRuns {
                    self.tempTotalParkruns = totalRuns
                    print("Total parkruns: \(totalRuns)")
                }
                if let lastDate = extractedData.lastDate {
                    self.tempLastParkrunDate = lastDate
                    print("Last parkrun date: \(lastDate)")
                }
                if let lastTime = extractedData.lastTime {
                    self.tempLastParkrunTime = lastTime
                    print("Last parkrun time: \(lastTime)")
                }
                if let lastEvent = extractedData.lastEvent {
                    self.tempLastParkrunEvent = lastEvent
                    print("Last parkrun event: \(lastEvent)")
                }
                if let lastEventURL = extractedData.lastEventURL {
                    self.tempLastParkrunEventURL = lastEventURL
                    print("Last parkrun event URL: \(lastEventURL)")
                    print("DEBUG - tempLastParkrunEventURL is now set to: '\(self.tempLastParkrunEventURL)'")
                } else {
                    print("DEBUG - No lastEventURL found in extracted data, tempLastParkrunEventURL remains: '\(self.tempLastParkrunEventURL)'")
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
