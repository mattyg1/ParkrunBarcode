//
//  QRCodeGenerationTests.swift
//  PR Bar CodeTests
//
//  Created by Claude Code on 15/06/2025.
//

import Testing
import Foundation
import CoreImage
import UIKit
@testable import FiveKQRCode

struct QRCodeGenerationTests {
    
    @Test("QR code filter initialization")
    func testQRCodeFilterInitialization() {
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        
        #expect(qrCodeFilter != nil)
        #expect(qrCodeFilter.inputKeys.contains("inputMessage"))
    }
    
    @Test("Barcode filter initialization")
    func testBarcodeFilterInitialization() {
        let barcodeFilter = CIFilter.code128BarcodeGenerator()
        
        #expect(barcodeFilter != nil)
        #expect(barcodeFilter.inputKeys.contains("inputMessage"))
    }
    
    @Test("QR code data input validation")
    func testQRCodeDataInput() {
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        let testString = "A12345"
        let testData = Data(testString.utf8)
        
        qrCodeFilter.message = testData
        
        // Verify the filter accepts the data
        #expect(qrCodeFilter.message == testData)
    }
    
    @Test("Barcode data input validation")
    func testBarcodeDataInput() {
        let barcodeFilter = CIFilter.code128BarcodeGenerator()
        let testString = "A12345"
        let testData = Data(testString.utf8)
        
        barcodeFilter.message = testData
        
        // Verify the filter accepts the data
        #expect(barcodeFilter.message == testData)
    }
    
    @Test("QR code output image generation")
    func testQRCodeOutputGeneration() {
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        let testString = "A12345"
        let testData = Data(testString.utf8)
        
        qrCodeFilter.message = testData
        
        let outputImage = qrCodeFilter.outputImage
        #expect(outputImage != nil)
        
        if let image = outputImage {
            #expect(image.extent.width > 0)
            #expect(image.extent.height > 0)
        }
    }
    
    @Test("Barcode output image generation")
    func testBarcodeOutputGeneration() {
        let barcodeFilter = CIFilter.code128BarcodeGenerator()
        let testString = "A12345"
        let testData = Data(testString.utf8)
        
        barcodeFilter.message = testData
        
        let outputImage = barcodeFilter.outputImage
        #expect(outputImage != nil)
        
        if let image = outputImage {
            #expect(image.extent.width > 0)
            #expect(image.extent.height > 0)
        }
    }
    
    @Test("Empty string handling")
    func testEmptyStringHandling() {
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        let emptyData = Data("".utf8)
        
        qrCodeFilter.message = emptyData
        
        let outputImage = qrCodeFilter.outputImage
        #expect(outputImage != nil) // QR codes can be generated for empty strings
    }
    
    @Test("QR code scaling transformation")
    func testQRCodeScaling() {
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        let testData = Data("A12345".utf8)
        
        qrCodeFilter.message = testData
        
        guard let ciImage = qrCodeFilter.outputImage else {
            Issue.record("Failed to generate QR code image")
            return
        }
        
        let scaleTransform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: scaleTransform)
        
        #expect(scaledImage.extent.width == ciImage.extent.width * 10)
        #expect(scaledImage.extent.height == ciImage.extent.height * 10)
    }
    
    @Test("Barcode scaling transformation")
    func testBarcodeScaling() {
        let barcodeFilter = CIFilter.code128BarcodeGenerator()
        let testData = Data("A12345".utf8)
        
        barcodeFilter.message = testData
        
        guard let ciImage = barcodeFilter.outputImage else {
            Issue.record("Failed to generate barcode image")
            return
        }
        
        let scaleTransform = CGAffineTransform(scaleX: 2, y: 2)
        let scaledImage = ciImage.transformed(by: scaleTransform)
        
        #expect(scaledImage.extent.width == ciImage.extent.width * 2)
        #expect(scaledImage.extent.height == ciImage.extent.height * 2)
    }
    
    @Test("CIContext initialization")
    func testCIContextInitialization() {
        let context = CIContext()
        
        #expect(context != nil)
    }
    
    @Test("CGImage conversion from CIImage")
    func testCGImageConversion() {
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        let testData = Data("A12345".utf8)
        
        qrCodeFilter.message = testData
        
        guard let ciImage = qrCodeFilter.outputImage else {
            Issue.record("Failed to generate QR code image")
            return
        }
        
        let context = CIContext()
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        
        #expect(cgImage != nil)
        
        if let image = cgImage {
            #expect(image.width > 0)
            #expect(image.height > 0)
        }
    }
    
    @Test("UIImage creation from CGImage")
    func testUIImageCreation() {
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        let testData = Data("A12345".utf8)
        
        qrCodeFilter.message = testData
        
        guard let ciImage = qrCodeFilter.outputImage else {
            Issue.record("Failed to generate QR code image")
            return
        }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            Issue.record("Failed to create CGImage")
            return
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        #expect(uiImage.size.width > 0)
        #expect(uiImage.size.height > 0)
    }
    
    @Test("Different parkrun ID formats")
    func testDifferentParkrunIDFormats() {
        let testIDs = ["A1", "A12345", "A999999", "A123456789"]
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        
        for testID in testIDs {
            let testData = Data(testID.utf8)
            qrCodeFilter.message = testData
            
            let outputImage = qrCodeFilter.outputImage
            #expect(outputImage != nil, "Failed to generate QR code for ID: \(testID)")
            
            if let image = outputImage {
                #expect(image.extent.width > 0)
                #expect(image.extent.height > 0)
            }
        }
    }
    
    @Test("Special characters in input")
    func testSpecialCharacters() {
        let specialInputs = ["A12345!", "A12345@", "A12345#", "A12345$"]
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        
        for input in specialInputs {
            let testData = Data(input.utf8)
            qrCodeFilter.message = testData
            
            let outputImage = qrCodeFilter.outputImage
            #expect(outputImage != nil, "Failed to generate QR code for input: \(input)")
        }
    }
    
    @Test("Unicode character handling")
    func testUnicodeCharacters() {
        let unicodeInputs = ["A12345😀", "A12345🏃‍♂️", "A12345🎯"]
        let qrCodeFilter = CIFilter.qrCodeGenerator()
        
        for input in unicodeInputs {
            let testData = Data(input.utf8)
            qrCodeFilter.message = testData
            
            let outputImage = qrCodeFilter.outputImage
            #expect(outputImage != nil, "Failed to generate QR code for unicode input: \(input)")
        }
    }
}