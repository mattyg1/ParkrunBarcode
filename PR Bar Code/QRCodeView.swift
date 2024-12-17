import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeBarcodeView: View {
    @State private var inputText: String = ""

    private let context = CIContext()
    private let qrCodeFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter text to encode", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)

            if !inputText.isEmpty {
                VStack {
                    Text("QR Code")
                    if let qrCodeImage = generateQRCode(from: inputText) {
                        Image(uiImage: qrCodeImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    } else {
                        Text("Invalid QR Code input or generation failed.")
                            .foregroundColor(.red)
                    }
                }

                VStack {
                    Text("Barcode")
                    if let barcodeImage = generateBarcode(from: inputText) {
                        Image(uiImage: barcodeImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 200, height: 100)
                    } else {
                        Text("Invalid Barcode input or generation failed.")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
    }

    // QR Code Generator
    func generateQRCode(from string: String) -> UIImage? {
        guard !string.isEmpty else {
            print("Input string for QR Code is empty.")
            return nil
        }
        qrCodeFilter.message = Data(string.utf8)
        guard let ciImage = qrCodeFilter.outputImage else {
            print("Failed to generate QR Code image.")
            return nil
        }
        print("QR Code generated successfully.")
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return convertToUIImage(from: transformedImage)
    }

    // Barcode Generator
    func generateBarcode(from string: String) -> UIImage? {
        guard !string.isEmpty else {
            print("Input string for Barcode is empty.")
            return nil
        }
        barcodeFilter.message = Data(string.utf8)
        guard let ciImage = barcodeFilter.outputImage else {
            print("Failed to generate Barcode image.")
            return nil
        }
        print("Barcode generated successfully.")
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: 2, y: 2))
        return convertToUIImage(from: transformedImage)
    }

    // Helper function to convert CIImage to UIImage
    func convertToUIImage(from ciImage: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct QRCodeBarcodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeBarcodeView()
    }
}
