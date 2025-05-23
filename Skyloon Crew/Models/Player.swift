// Challenge2/Models/Player.swift
import Foundation
import MultipeerConnectivity
import SwiftUI

// Assuming GyroData and Color.toHex() are defined elsewhere in your project.
// If not, you'll need to add their definitions.
// For example:
// struct GyroData { var x: Double = 0.0; var y: Double = 0.0; var z: Double = 0.0 }
// extension Color { func toHex() -> String { /* ... implementation ... */ return "#FF0000" } }
// The BoatController class is also assumed to be defined elsewhere and accessible.

enum ConnectionState: String, Codable {
    case disconnected
    case connecting
    case connected
}

class Player: Identifiable, ObservableObject {
    // ... (other properties remain the same) ...
    let id = UUID()
    var playerNumber: Int
    var playerName: String
    var playerColorHex: String
    var peerID: MCPeerID
    @Published var deviceName: String
    @Published var connectionState: ConnectionState
    @Published var currentGyroData: GyroData
    @Published var lastDetectedMotion: String?
    @Published var lastMotionData: [Double] = []
    @Published var totalSwing = 0
    
    var boatController: BoatController?
    
    private let maxMotionDataSaved = 100
    private var isSwingCooldown = false
    private let swingCooldownDuration = 1.0 // seconds // You might need to tune this
    
    init(playerNumber: Int, playerName: String, playerColorHex: String, peerID: MCPeerID, deviceName: String = "", connectionState: ConnectionState = .disconnected, lastDetectedMotion: String? = "Idle", boatController: BoatController? = nil) {
        self.playerNumber = playerNumber
        self.playerName = playerName
        self.playerColorHex = playerColorHex
        self.peerID = peerID
        self.deviceName = deviceName
        self.connectionState = connectionState
        self.currentGyroData = GyroData()
        self.lastDetectedMotion = lastDetectedMotion
        self.boatController = boatController
    }
    
    func addMotionData(_ newData: Double) {
        if lastMotionData.count >= maxMotionDataSaved {
            lastMotionData.removeFirst()
        }
        lastMotionData.append(newData)
        
        if !isSwingCooldown, // Only attempt to detect a swing if not in cooldown
           let max = lastMotionData.max(),
           let min = lastMotionData.min(),
           (max - min) > 4.0 { // Threshold for detecting a swing
            
            totalSwing += 1
            // DO NOT clear lastMotionData here immediately.
            // lastMotionData.removeAll() // <--- REMOVE THIS LINE
            
            isSwingCooldown = true // Enter cooldown state
            
            // Boat control logic
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if let controller = self.boatController {
                    if self.playerNumber == 1 || self.playerNumber == 3 {
                        print("Player \(self.playerName) (P\(self.playerNumber)) swinging: Attempting to paddle LEFT. Total Swings: \(self.totalSwing)")
                        controller.paddleLeft()
                    } else if self.playerNumber == 2 || self.playerNumber == 4 {
                        print("Player \(self.playerName) (P\(self.playerNumber)) swinging: Attempting to paddle RIGHT. Total Swings: \(self.totalSwing)")
                        controller.paddleRight()
                    }
                } else {
                    print("Player \(self.playerName) (P\(self.playerNumber)) swung, but no BoatController is assigned. Total Swings: \(self.totalSwing)")
                }
            }
            
            // Start cooldown timer. When it finishes, reset the cooldown flag
            // AND clear the motion data to prepare for a fresh detection.
            DispatchQueue.main.asyncAfter(deadline: .now() + swingCooldownDuration) { [weak self] in
                guard let self = self else { return }
                self.isSwingCooldown = false
                self.lastMotionData.removeAll() // <--- CLEAR DATA HERE, WHEN COOLDOWN ENDS
                print("Player \(self.playerName) cooldown ended. Motion data cleared. Ready for next swing.")
            }
        }
    }
    
    // ... (rest of the class remains the same) ...
    func updateGyroData(_ data: GyroData) {
        DispatchQueue.main.async {
            self.currentGyroData = data
        }
    }
    
    static func samplePlayers() -> [Player] {
        // ...
        return [
            Player(playerNumber: 1, playerName: "A", playerColorHex: Color.red.toHex() ?? "#FF0000", peerID: MCPeerID(displayName: "iPhone 15"), deviceName: "Player 1 iPhone", connectionState: .connected, lastDetectedMotion: "Smash", boatController: nil),
            Player(playerNumber: 2, playerName: "B", playerColorHex: Color.blue.toHex() ?? "#0000FF", peerID: MCPeerID(displayName: "iPhone 14"), deviceName: "Player 2 iPhone", connectionState: .connected, lastDetectedMotion: "Idle", boatController: nil),
            Player(playerNumber: 3, playerName: "C", playerColorHex: Color.green.toHex() ?? "#00FF00", peerID: MCPeerID(displayName: "iPhone 13"), deviceName: "Player 3 iPhone", connectionState: .disconnected, boatController: nil),
            Player(playerNumber: 4, playerName: "D", playerColorHex: Color.yellow.toHex() ?? "#FFFF00", peerID: MCPeerID(displayName: "iPhone SE"), deviceName: "Player 4 iPhone", connectionState: .connecting, boatController: nil)
        ]
    }
}
