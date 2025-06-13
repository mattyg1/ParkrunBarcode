//
//  ContentView.swift
//  PR Bar Code Watch App Watch App
//
//  Created by Matthew Gardner on 12/06/2025.
//

import SwiftUI
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    @Published var parkrunID: String = ""
    @Published var qrCodeImage: UIImage? = nil
    @Published var isConnected: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let parkrunIDKey = "SavedParkrunID"
    private let qrCodeImageKey = "SavedQRCodeImage"
    
    private override init() { 
        super.init()
        loadSavedData()
    }
    
    func startSession() {
        print("Watch: Starting WC session")
        guard WCSession.isSupported() else { 
            print("Watch: WCSession not supported")
            return 
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch: Session activated with state: \(activationState.rawValue)")
        if let error = error {
            print("Watch: Activation error: \(error)")
        }
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            print("Watch: Connected = \(session.isReachable)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("Watch: Received message: \(message)")
        var dataUpdated = false
        
        if let parkrunID = message["parkrunID"] as? String {
            print("Watch: Setting parkrunID to: \(parkrunID)")
            self.parkrunID = parkrunID
            dataUpdated = true
        }
        
        if let imageData = message["qrCodeImageData"] as? Data,
           let qrImage = UIImage(data: imageData) {
            print("Watch: Setting QR code image")
            self.qrCodeImage = qrImage
            dataUpdated = true
        }
        
        if dataUpdated {
            DispatchQueue.main.async {
                self.saveData()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Watch: Reachability changed to: \(session.isReachable)")
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("Watch: Received user info: \(userInfo)")
        var dataUpdated = false
        
        if let parkrunID = userInfo["parkrunID"] as? String {
            print("Watch: Setting parkrunID from userInfo to: \(parkrunID)")
            DispatchQueue.main.async {
                self.parkrunID = parkrunID
            }
            dataUpdated = true
        }
        
        if let imageData = userInfo["qrCodeImageData"] as? Data,
           let qrImage = UIImage(data: imageData) {
            print("Watch: Setting QR code image from userInfo")
            DispatchQueue.main.async {
                self.qrCodeImage = qrImage
            }
            dataUpdated = true
        }
        
        if dataUpdated {
            DispatchQueue.main.async {
                self.saveData()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Watch: Received message with reply handler: \(message)")
        var dataUpdated = false
        
        if let parkrunID = message["parkrunID"] as? String {
            print("Watch: Setting parkrunID from message to: \(parkrunID)")
            DispatchQueue.main.async {
                self.parkrunID = parkrunID
            }
            dataUpdated = true
        }
        
        if let imageData = message["qrCodeImageData"] as? Data,
           let qrImage = UIImage(data: imageData) {
            print("Watch: Setting QR code image from message")
            DispatchQueue.main.async {
                self.qrCodeImage = qrImage
            }
            dataUpdated = true
        }
        
        if dataUpdated {
            DispatchQueue.main.async {
                self.saveData()
            }
        }
        
        // Send acknowledgment back
        replyHandler(["status": "received"])
    }
    
    // MARK: - Local Storage Functions
    private func loadSavedData() {
        // Load saved Parkrun ID
        if let savedID = userDefaults.string(forKey: parkrunIDKey), !savedID.isEmpty {
            print("Watch: Loading saved Parkrun ID: \(savedID)")
            DispatchQueue.main.async {
                self.parkrunID = savedID
            }
        }
        
        // Load saved QR code image
        if let imageData = userDefaults.data(forKey: qrCodeImageKey),
           let savedImage = UIImage(data: imageData) {
            print("Watch: Loading saved QR code image")
            DispatchQueue.main.async {
                self.qrCodeImage = savedImage
            }
        }
    }
    
    private func saveData() {
        // Save Parkrun ID
        userDefaults.set(parkrunID, forKey: parkrunIDKey)
        print("Watch: Saved Parkrun ID: \(parkrunID)")
        
        // Save QR code image
        if let qrImage = qrCodeImage,
           let imageData = qrImage.pngData() {
            userDefaults.set(imageData, forKey: qrCodeImageKey)
            print("Watch: Saved QR code image")
        }
        
        userDefaults.synchronize()
    }
}

struct ContentView: View {
    @StateObject private var watchManager = WatchConnectivityManager.shared
    @State private var showFullScreenQR = false
    
    var body: some View {
        VStack(spacing: 8) {
            if !watchManager.parkrunID.isEmpty {
                Text("Parkrun ID")
                    .font(.caption)
                    .foregroundColor(.primary)
                
                // Display QR code image received from iOS
                if let qrImage = watchManager.qrCodeImage {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .onTapGesture {
                            showFullScreenQR = true
                        }
                } else {
                    // Fallback to text display
                    Text(watchManager.parkrunID)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .onTapGesture {
                            showFullScreenQR = true
                        }
                }
                
                Text(watchManager.parkrunID)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Show to scanner")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // Connection status indicator
                HStack(spacing: 4) {
                    Image(systemName: watchManager.isConnected ? "iphone.and.watch" : "applewatch")
                        .font(.caption2)
                        .foregroundColor(watchManager.isConnected ? .green : .orange)
                    
                    Text(watchManager.isConnected ? "Live" : "Saved")
                        .font(.caption2)
                        .foregroundColor(watchManager.isConnected ? .green : .orange)
                }
                .padding(.top, 2)
            } else {
                Image(systemName: "barcode")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                
                Text("Waiting for Parkrun ID")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                
                Text(watchManager.isConnected ? "Connected to iPhone" : "Not connected")
                    .font(.caption2)
                    .foregroundColor(watchManager.isConnected ? .green : .red)
            }
        }
        .onAppear {
            watchManager.startSession()
        }
        .sheet(isPresented: $showFullScreenQR) {
            FullScreenQRView(
                qrImage: watchManager.qrCodeImage, 
                parkrunID: watchManager.parkrunID,
                isPresented: $showFullScreenQR
            )
        }
    }
    
}

struct FullScreenQRView: View {
    let qrImage: UIImage?
    let parkrunID: String
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                if let qrImage = qrImage {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                } else {
                    // Fallback when no QR image available
                    VStack(spacing: 8) {
                        Text("Parkrun ID")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text(parkrunID)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .onTapGesture {
            isPresented = false
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 {
                        isPresented = false
                    }
                }
        )
    }
}


#Preview {
    ContentView()
}