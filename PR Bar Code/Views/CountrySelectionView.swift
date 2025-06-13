//
//  CountrySelectionView.swift
//  PR Bar Code
//
//  Created by Matthew Gardner on 13/06/2025.
//

import SwiftUI

struct CountrySelectionView: View {
    @Binding var isPresented: Bool
    @State private var searchText: String = ""
    
    private var filteredCountries: [Country] {
        let countries: [Country]
        
        if searchText.isEmpty {
            // Put UK first, then sort the rest alphabetically
            let ukCountry = [Country.unitedKingdom]
            let otherCountries = Country.allCases.filter { $0 != .unitedKingdom }.sorted { $0.name < $1.name }
            countries = ukCountry + otherCountries
        } else {
            countries = Country.allCases.filter { country in
                country.name.localizedCaseInsensitiveContains(searchText)
            }.sorted { country1, country2 in
                // If UK matches search, put it first
                if country1 == .unitedKingdom && country2 != .unitedKingdom {
                    return true
                } else if country1 != .unitedKingdom && country2 == .unitedKingdom {
                    return false
                } else {
                    return country1.name < country2.name
                }
            }
        }
        
        return countries
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Countries list
                List(filteredCountries, id: \.rawValue) { country in
                    CountryRow(country: country, isHighlighted: country == .unitedKingdom) {
                        openParkrunWebsite(for: country)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Your Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func openParkrunWebsite(for country: Country) {
        guard let url = URL(string: country.websiteURL) else {
            print("Invalid URL for country: \(country.name)")
            return
        }
        
        #if os(iOS)
        UIApplication.shared.open(url) { success in
            if success {
                print("Successfully opened \(country.name) parkrun website")
                // Close the country selection and return to onboarding
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPresented = false
                }
            } else {
                print("Failed to open URL for \(country.name)")
            }
        }
        #endif
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search countries...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .foregroundColor(.secondary)
                .font(.caption)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CountryRow: View {
    let country: Country
    let isHighlighted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(country.name)
                            .font(.body)
                            .fontWeight(isHighlighted ? .semibold : .medium)
                            .foregroundColor(.primary)
                        
                        if isHighlighted {
                            Text("POPULAR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(country.websiteURL)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "safari")
                    .foregroundColor(isHighlighted ? .blue : .blue)
                    .font(.title3)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(isHighlighted ? Color.blue.opacity(0.05) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CountrySelectionView(isPresented: .constant(true))
}