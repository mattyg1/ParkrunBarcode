import SwiftUI
import CoreImage.CIFilterBuiltins
import SwiftData

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

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

    private let context = CIContext()
    private let qrCodeFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isEditing || parkrunInfoList.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Personal Information Section
                            personalInfoSection
                            
                            // QR Code and Barcode Selector and Display
                            qrCodeAndBarcodeSection
                        }
                        .padding()
                    }
                    .navigationTitle(isEditing ? "Edit Parkrun Info" : "Add Parkrun Info")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            cancelEdit()
                        }.disabled(parkrunInfoList.isEmpty),
                        trailing: Button("Confirm") {
                            if !inputText.isEmpty && inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil {
                                if name.isEmpty {
                                    // Fetch data first, then show confirmation dialog
                                    fetchParkrunnerName(id: inputText) {
                                        self.showConfirmationDialog = true
                                    }
                                } else {
                                    // Data already available, show confirmation dialog
                                    showConfirmationDialog = true
                                }
                            } else {
                                alertMessage = "Please enter a valid Parkrun ID first."
                                showAlert = true
                            }
                        }
                    )
                } else {
                    // Display Saved Data
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Personal Information Section
                            personalInfoSection
                            
                            // QR Code and Barcode Selector and Display
                            qrCodeAndBarcodeSection
                        }
                        .padding()
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Please confirm your details:")
                    Text("Parkrun ID: \(inputText)")
                    if !name.isEmpty {
                        Text("Name: \(name)")
                    }
                    if !totalParkruns.isEmpty {
                        Text("Total Parkruns: \(totalParkruns)")
                    }
                    if !lastParkrunDate.isEmpty && !lastParkrunTime.isEmpty && !lastParkrunEvent.isEmpty {
                        Text("Last Parkrun: \(lastParkrunEvent)")
                        Text("Date: \(lastParkrunDate), Time: \(lastParkrunTime)")
                    }
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
    }

    // MARK: - Personal Info Section
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Personal Information")
                .font(.headline)
                .padding(.bottom, 5)

            if isEditing {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
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
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        
                        // Helper text
                        if !inputText.isEmpty && inputText.range(of: #"^A\d+$"#, options: .regularExpression) == nil {
                            Text("ID must start with 'A' followed by numbers")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 10)
                        } else if isLoadingName {
                            Text("Looking up runner details...")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.leading, 10)
                        } else if !name.isEmpty && inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil {
                            Text("Details found - ready to save")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.leading, 10)
                        } else if inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil {
                            Text("Press Confirm to lookup details")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.leading, 10)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(name.isEmpty ? "Auto-filled from Parkrun ID" : name)
                            .font(.body)
                            .foregroundColor(name.isEmpty ? .secondary : .primary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(10)
                    }
                    
                    // Show total parkruns if available
                    if !totalParkruns.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Total Parkruns")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(totalParkruns)
                                .font(.body)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(10)
                        }
                    }
                    
                    // Show last parkrun table if data is available
                    if !lastParkrunDate.isEmpty && !lastParkrunTime.isEmpty && !lastParkrunEvent.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.tertiarySystemBackground))
                            }
                            .cornerRadius(10)
                        }
                    }
                }
            } else {
                // Read-only display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Parkrun ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(inputText.isEmpty ? "Not set" : inputText)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(name.isEmpty ? "Not set" : name)
                        .font(.body)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Parkruns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalParkruns.isEmpty ? "Not set" : totalParkruns)
                        .font(.body)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(10)
                }
                
                if !lastParkrunDate.isEmpty && !lastParkrunTime.isEmpty && !lastParkrunEvent.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemBackground))
                        }
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .frame(maxWidth: .infinity)
    }


    // MARK: - QR Code and Barcode Section
    private var qrCodeAndBarcodeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Parkrun Codes")
                .font(.headline)
                .padding(.bottom, 5)

            Picker("Code Type", selection: $selectedCodeType) {
                Text("QR Code").tag(0)
                Text("Barcode").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            HStack {
                if selectedCodeType == 0 {
                    CodeSectionView(
                        title: "QR Code",
                        image: generateQRCode(from: inputText),
                        size: CGSize(width: 200, height: 200)
                    )
                } else {
                    CodeSectionView(
                        title: "Barcode",
                        image: generateBarcode(from: inputText),
                        size: CGSize(width: 300, height: 100)
                    )
                }
            }
            .frame(maxWidth: .infinity) // Center align QR/Barcode
            .padding()
        }
        .padding()
    }

    // MARK: - Functions
    private func loadInitialData() {
        if let savedInfo = parkrunInfoList.first {
            inputText = savedInfo.parkrunID
            name = savedInfo.name
            homeParkrun = savedInfo.homeParkrun
            selectedCountryCode = savedInfo.country ?? Country.unitedKingdom.rawValue
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
        } else {
            let newInfo = ParkrunInfo(parkrunID: inputText, name: name, homeParkrun: homeParkrun, country: selectedCountryCode)
            modelContext.insert(newInfo)
        }

        do {
            try modelContext.save()
            isEditing = false
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
        
        // Extract runner name from h2 tag: <h2>Matt GARDNER <span style="font-weight: normal;" title="parkrun ID">(A79156)</span></h2>
        if let nameRegex = try? NSRegularExpression(pattern: #"<h2>([^<]+?)\s*<span[^>]*title="parkrun ID"[^>]*>"#, options: [.caseInsensitive]) {
            let nameMatches = nameRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = nameMatches.first, let nameRange = Range(match.range(at: 1), in: html) {
                name = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Extract total parkruns from h3 tag: <h3>279 parkruns total</h3>
        if let totalRegex = try? NSRegularExpression(pattern: #"<h3>(\d+)\s+parkruns?\s+total</h3>"#, options: [.caseInsensitive]) {
            let totalMatches = totalRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = totalMatches.first, let totalRange = Range(match.range(at: 1), in: html) {
                totalRuns = String(html[totalRange])
            }
        }
        
        // Extract most recent parkrun data from first row of results table
        // Looking for pattern like: <td><a href="..." target="_top">Ganger Farm parkrun</a></td><td><a href="...">07/06/2025</a></td><td>64</td><td>76</td><td>25:14</td>
        if let recentRegex = try? NSRegularExpression(pattern: #"<td><a href="[^"]*"[^>]*>([^<]+)</a></td><td><a href="[^"]*results/\d+/"[^>]*>(\d{2}/\d{2}/\d{4})</a></td><td>\d+</td><td>\d+</td><td>([^<]+)</td>"#, options: [.caseInsensitive]) {
            let recentMatches = recentRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = recentMatches.first {
                if let eventRange = Range(match.range(at: 1), in: html) {
                    lastEvent = String(html[eventRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if let dateRange = Range(match.range(at: 2), in: html) {
                    lastDate = String(html[dateRange])
                }
                if let timeRange = Range(match.range(at: 3), in: html) {
                    lastTime = String(html[timeRange])
                }
            }
        }
        
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
