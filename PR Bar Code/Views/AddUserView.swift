//
//  AddUserView.swift
//  PR Bar Code
//
//  Created by Claude Code on 13/06/2025.
//

import SwiftUI

struct AddUserView: View {
    @Binding var isPresented: Bool
    let onUserAdded: (String) -> Void
    
    @State private var parkrunID: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter Parkrun ID")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Add another parkrun participant to switch between users")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Parkrun ID (e.g., A12345)", text: $parkrunID)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.asciiCapable)
                            .autocapitalization(.none)
                        
                        if parkrunID.range(of: #"^A\d+$"#, options: .regularExpression) != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if !parkrunID.isEmpty {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text("Format: A followed by numbers (e.g., A12345)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Button(action: addUser) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                        Text("Add User")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidParkrunID ? Color.green : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!isValidParkrunID)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Invalid Parkrun ID"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var isValidParkrunID: Bool {
        parkrunID.range(of: #"^A\d+$"#, options: .regularExpression) != nil
    }
    
    private func addUser() {
        guard isValidParkrunID else {
            alertMessage = "Please enter a valid Parkrun ID starting with 'A' followed by numbers (e.g., A12345)"
            showAlert = true
            return
        }
        
        onUserAdded(parkrunID)
        isPresented = false
    }
}

#Preview {
    AddUserView(isPresented: .constant(true)) { _ in }
}