//
//  OnboardingView.swift
//  PR Bar Code
//
//  Created by Matthew Gardner on 13/06/2025.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var showBarcodeEntry = false
    @State private var showCountrySelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Main content
                VStack(spacing: 20) {
                    Text("Enter your barcode to see personalised results")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        showBarcodeEntry = true
                    }) {
                        Text("Add barcode")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.adaptiveParkrunGreen)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showCountrySelection = true
                    }) {
                        Text("I don't have a barcode")
                            .font(.body)
                            .foregroundColor(.primary)
                            .underline()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationTitle("Me")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showBarcodeEntry) {
            BarcodeEntryView(isPresented: $showBarcodeEntry, onboardingPresented: $isPresented)
        }
        .sheet(isPresented: $showCountrySelection) {
            CountrySelectionView(isPresented: $showCountrySelection)
        }
    }
}

struct BarcodeEntryView: View {
    @Binding var isPresented: Bool
    @Binding var onboardingPresented: Bool
    @State private var barcodeText: String = ""
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Input field
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Barcode number, which starts with an A", text: $barcodeText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Search button
                Button(action: {
                    searchBarcode()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text("Search")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(barcodeText.isEmpty ? Color.gray : Color.adaptiveParkrunGreen)
                    .cornerRadius(12)
                }
                .disabled(barcodeText.isEmpty || isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Add Your Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Me") {
                        isPresented = false
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Search Result"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func normalizeInput(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only add "A" if it's just numbers (no "A" prefix already)
        if trimmed.range(of: #"^\d+$"#, options: .regularExpression) != nil {
            return "A" + trimmed
        }
        
        // Handle "A 67982" format (A followed by space and numbers)
        if trimmed.range(of: #"^[Aa]\s+\d+$"#, options: .regularExpression) != nil {
            let numbersOnly = trimmed.replacingOccurrences(of: #"[Aa]\s+"#, with: "", options: .regularExpression)
            return "A" + numbersOnly
        }
        
        // Convert lowercase "a" to uppercase "A" (but don't add extra "A")
        if trimmed.lowercased().hasPrefix("a") {
            return "A" + String(trimmed.dropFirst())
        }
        
        return trimmed.uppercased()
    }
    
    private func searchBarcode() {
        guard !barcodeText.isEmpty else { return }
        
        // Normalize the input before processing
        let normalizedInput = normalizeInput(barcodeText)
        
        isLoading = true
        
        // Validate if it's a proper Parkrun ID format
        if normalizedInput.range(of: #"^A\d+$"#, options: .regularExpression) != nil {
            // Valid Parkrun ID format - close onboarding and pass to main view with direct confirmation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
                isPresented = false
                onboardingPresented = false
                
                // Post notification to main view to handle the barcode and show confirmation
                NotificationCenter.default.post(
                    name: NSNotification.Name("SetParkrunIDWithConfirmation"), 
                    object: normalizedInput
                )
            }
        } else {
            // Invalid format or search by name
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isLoading = false
                alertMessage = "Please enter a valid Parkrun ID starting with 'A' followed by numbers (e.g., A12345)"
                showAlert = true
            }
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
