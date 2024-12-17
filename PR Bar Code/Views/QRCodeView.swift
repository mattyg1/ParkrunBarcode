import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeBarcodeView: View {
    @State private var inputText: String = ""
    @State private var showCode: Bool = false
    
    private let context = CIContext()
    private let qrCodeFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Input TextField
                HStack {
                    TextField("Enter text to encode", text: $inputText, onCommit: updateCodes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    // Clear Button
                    Button(action: {
                        inputText = ""
                        showCode = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .imageScale(.large)
                    }
                }
                .padding(.top)

                // Code Previews with Animation
                if showCode {
                    VStack(spacing: 30) {
                        // QR Code Section
                        CodeSectionView(
                            title: "QR Code",
                            image: generateQRCode(from: inputText),
                            size: CGSize(width: 200, height: 200)
                        )

                        // Barcode Section
                        CodeSectionView(
                            title: "Barcode",
                            image: generateBarcode(from: inputText),
                            size: CGSize(width: 300, height: 100)
                        )
                    }
                    .transition(.opacity.combined(with: .scale))
                } else {
                    Spacer()
                    Text("Enter text to generate QR Code & Barcode")
                        .foregroundColor(.secondary)
                    Spacer()
                }

                Spacer()
            }
            .navigationTitle("QR & Barcode Generator")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut, value: showCode)
        }
    }
    
    // Function to update UI when text is entered
    private func updateCodes() {
        showCode = !inputText.isEmpty
    }

    // QR Code Generator
    private func generateQRCode(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }
        qrCodeFilter.message = Data(string.utf8)
        guard let ciImage = qrCodeFilter.outputImage else { return nil }
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return convertToUIImage(from: transformedImage)
    }

    // Barcode Generator
    private func generateBarcode(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }
        barcodeFilter.message = Data(string.utf8)
        guard let ciImage = barcodeFilter.outputImage else { return nil }
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: 2, y: 2))
        return convertToUIImage(from: transformedImage)
    }

    // Helper function to convert CIImage to UIImage
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

struct QRCodeBarcodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeBarcodeView()
    }
}
