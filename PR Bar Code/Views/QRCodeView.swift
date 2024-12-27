import SwiftUI
import CoreImage.CIFilterBuiltins
import SwiftData

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
    @State private var selectedTab: Int = 0 // 0 = Personal Info, 1 = Location Info
    @State private var selectedCodeType: Int = 0 // 0 = QR Code, 1 = Barcode

    private let context = CIContext()
    private let qrCodeFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isEditing || parkrunInfoList.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Selector for Personal and Location Information
                            Picker("Section", selection: $selectedTab) {
                                Text("Personal Info").tag(0)
                                Text("Location Info").tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()

                            // Display Selected Section
                            if selectedTab == 0 {
                                personalInfoSection
                            } else if selectedTab == 1 {
                                locationInfoSection
                            }
                        }
                        .padding()

                        // QR Code and Barcode Selector and Display
                        qrCodeAndBarcodeSection
                    }
                    .navigationTitle(isEditing ? "Edit Parkrun Info" : "Add Parkrun Info")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            cancelEdit()
                        }.disabled(parkrunInfoList.isEmpty),
                        trailing: Button("Save") {
                            saveParkrunInfo()
                        }
                    )
                } else {
                    // Display Saved Data
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Selector for Personal and Location Information
                            Picker("Section", selection: $selectedTab) {
                                Text("Personal Info").tag(0)
                                Text("Location Info").tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()

                            // Display Selected Section
                            if selectedTab == 0 {
                                personalInfoSection
                            } else if selectedTab == 1 {
                                locationInfoSection
                            }

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

            TextField("Enter Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            TextField("Parkrun ID (e.g., A12345)", text: $inputText)
                .keyboardType(.asciiCapable)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .frame(maxWidth: .infinity) // Stretches section to fit the screen
    }

    // MARK: - Location Info Section
    private var locationInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Location Information")
                .font(.headline)
                .padding(.bottom, 5)

            TextField("Enter Home Parkrun", text: $homeParkrun)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            Picker("Country", selection: $selectedCountryCode) {
                ForEach(Country.allCases, id: \.rawValue) { country in
                    Text(country.name).tag(country.rawValue)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .frame(maxWidth: .infinity) // Stretches section to fit the screen
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

// MARK: - Reusable CodeSectionView
struct CodeSectionView: View {
    let title: String
    let image: UIImage?
    let size: CGSize

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
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
