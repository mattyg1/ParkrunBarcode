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
    @Published var isConnected: Bool = false
    
    private override init() { super.init() }
    
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
        if let parkrunID = message["parkrunID"] as? String {
            print("Watch: Setting parkrunID to: \(parkrunID)")
            DispatchQueue.main.async {
                self.parkrunID = parkrunID
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
        if let parkrunID = userInfo["parkrunID"] as? String {
            print("Watch: Setting parkrunID from userInfo to: \(parkrunID)")
            DispatchQueue.main.async {
                self.parkrunID = parkrunID
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Watch: Received message with reply handler: \(message)")
        if let parkrunID = message["parkrunID"] as? String {
            print("Watch: Setting parkrunID from message to: \(parkrunID)")
            DispatchQueue.main.async {
                self.parkrunID = parkrunID
            }
        }
        // Send acknowledgment back
        replyHandler(["status": "received"])
    }
}

struct ContentView: View {
    @StateObject private var watchManager = WatchConnectivityManager.shared
    
    var body: some View {
        VStack(spacing: 10) {
            if !watchManager.parkrunID.isEmpty {
                Text("Parkrun ID")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(watchManager.parkrunID)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                Text("Show this to scanner")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "barcode")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                
                Text("Waiting for Parkrun ID")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                
                Text(watchManager.isConnected ? "Connected to iPhone" : "Not connected")
                    .font(.caption2)
                    .foregroundColor(watchManager.isConnected ? .green : .red)
            }
        }
        .onAppear {
            watchManager.startSession()
        }
    }
}

#Preview {
    ContentView()
}