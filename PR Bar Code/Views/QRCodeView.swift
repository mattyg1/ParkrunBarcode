import SwiftUI
import CoreImage.CIFilterBuiltins
import SwiftData

struct QRCodeBarcodeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var parkrunInfoList: [ParkrunInfo]
    
    @State private var inputText: String = ""
    @State private var name: String = ""
    @State private var homeParkrun: String = ""
    @State private var isEditing: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private let context = CIContext()
    private let qrCodeFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isEditing || parkrunInfoList.isEmpty {
                    // Edit Mode or No Saved Data
                    Form {
                        Section(header: Text("Parkrun Details")) {
                            TextField("Parkrun ID (e.g., A12345)", text: $inputText)
                                .keyboardType(.asciiCapable)
                            TextField("Name", text: $name)
                            TextField("Home Parkrun", text: $homeParkrun)
                        }
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
                    VStack(spacing: 20) {
                        Text("Parkrun ID: \(parkrunInfoList.first?.parkrunID ?? "")")
                            .font(.title2)
                        Text("Name: \(parkrunInfoList.first?.name ?? "")")
                        Text("Home Parkrun: \(parkrunInfoList.first?.homeParkrun ?? "")")
                        
                        // QR Code and Barcode Preview
                        CodeSectionView(
                            title: "QR Code",
                            image: generateQRCode(from: parkrunInfoList.first?.parkrunID ?? ""),
                            size: CGSize(width: 200, height: 200)
                        )
                        CodeSectionView(
                            title: "Barcode",
                            image: generateBarcode(from: parkrunInfoList.first?.parkrunID ?? ""),
                            size: CGSize(width: 300, height: 100)
                        )
                    }
                    .navigationTitle("parkrun Info")
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

    // MARK: - Functions
    
    private func loadInitialData() {
        if let savedInfo = parkrunInfoList.first {
            inputText = savedInfo.parkrunID
            name = savedInfo.name
            homeParkrun = savedInfo.homeParkrun
        }
    }
    
    private func saveParkrunInfo() {
        // Validate Parkrun ID
        guard !inputText.isEmpty, inputText.range(of: #"^A\d+$"#, options: .regularExpression) != nil else {
            alertMessage = "Parkrun ID must start with 'A' followed by numbers (e.g., A12345)."
            showAlert = true
            return
        }
        
        // Insert or update data
        if let existingInfo = parkrunInfoList.first {
            existingInfo.parkrunID = inputText
            existingInfo.name = name
            existingInfo.homeParkrun = homeParkrun
        } else {
            let newInfo = ParkrunInfo(parkrunID: inputText, name: name, homeParkrun: homeParkrun)
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

    // QR Code and Barcode Generators
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

// Reusable CodeSectionView
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
            let previewParkrunInfo = ParkrunInfo(parkrunID: "A12345", name: "John Doe", homeParkrun: "Southampton Parkrun")
            context.insert(previewParkrunInfo)

            return QRCodeBarcodeView()
                .modelContainer(previewContainer)
        } catch {
            fatalError("Failed to create SwiftData container for preview: \(error)")
        }
    }
}
