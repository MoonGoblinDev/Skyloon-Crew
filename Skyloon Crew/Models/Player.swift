// Challenge2/Models/Player.swift
import Foundation
import MultipeerConnectivity
import SwiftUI

class Player: Identifiable, ObservableObject {
    let id = UUID()
    var playerNumber: Int
    var playerName: String
    var playerColorHex: String
    var character: String
    var peerID: MCPeerID
    
    @Published var deviceName: String
    @Published var connectionState: ConnectionState
    @Published var currentGyroData: GyroData
    @Published var lastDetectedMotion: String?
    @Published var lastMotionData: [Double] = []
    @Published var totalSwing = 0

    var boatController: BoatController?

    // --- Swing Detection State ---
    private var isMonitoringSwing: Bool = false
    private var pitchAtPotentialStart: Double = 0.0
    private var timeOfPotentialStart: Date?
    private var maxUserAccelerationMagnitudeDuringSwing: Double = 0.0
    private var maxPrimaryRotationRateDuringSwing: Double = 0.0

    // --- Thresholds & Constants ---
    private let maxMotionDataSaved = 100 // For the `lastMotionData` array
    private let SWING_COOLDOWN_DURATION: TimeInterval = 1.0

    // Start Conditions
    private let PITCH_UP_THRESHOLD_MIN: Double = 0.4
    private let PITCH_UP_THRESHOLD_MAX: Double = Double.pi / 2

    // Fast Swing
    private let FAST_SWING_ACCELERATION_TRIGGER_THRESHOLD: Double = 1.8
    private let FAST_SWING_ROTATION_RATE_TRIGGER_THRESHOLD: Double = 2.5
    private let FAST_SWING_MIN_PITCH_CHANGE: Double = 1.0
    private let FAST_SWING_MAX_DURATION: TimeInterval = 1.0
    private let FAST_SWING_MIN_DURATION: TimeInterval = 0.15
    private let PITCH_DOWN_THRESHOLD_MAX: Double = -0.2

    // Slow Swing
    private let SLOW_SWING_INITIAL_ACCEL_MIN_THRESHOLD: Double = 0.25
    private let SLOW_SWING_INITIAL_ROTATION_MIN_THRESHOLD: Double = 0.4
    private let SLOW_SWING_MIN_PITCH_CHANGE: Double = 0.9
    private let SLOW_SWING_MAX_DURATION: TimeInterval = 2.5
    private let SLOW_SWING_MIN_DURATION: TimeInterval = 0.7

    private var isSwingCooldownActive = false

    init(playerNumber: Int, playerName: String, playerColorHex: String, peerID: MCPeerID, deviceName: String = "", connectionState: ConnectionState = .disconnected, lastDetectedMotion: String? = "Idle", boatController: BoatController? = nil, character: CharactersEnum = .panda) {
        self.playerNumber = playerNumber
        self.playerName = playerName
        self.playerColorHex = playerColorHex
        self.peerID = peerID
        self.deviceName = deviceName
        self.connectionState = connectionState
        self.currentGyroData = GyroData()
        self.lastDetectedMotion = lastDetectedMotion
        self.boatController = boatController
        self.character = character.rawValue
    }

    func processMotionDataForSwing(data: GyroData) {
        DispatchQueue.main.async {
            self.currentGyroData = data
        }

        if isSwingCooldownActive {
            return
        }

        let currentPitch = data.pitch
        let currentUserAccelMag = data.accelerationMagnitude
        let currentPrimaryRotationRate = abs(data.rotationX)

        if !isMonitoringSwing {
            let isUpOrientation = currentPitch > PITCH_UP_THRESHOLD_MIN && currentPitch < PITCH_UP_THRESHOLD_MAX
            let isFastMotionTrigger = currentUserAccelMag > FAST_SWING_ACCELERATION_TRIGGER_THRESHOLD ||
                                      currentPrimaryRotationRate > FAST_SWING_ROTATION_RATE_TRIGGER_THRESHOLD
            let isSlowMotionTrigger = currentUserAccelMag > SLOW_SWING_INITIAL_ACCEL_MIN_THRESHOLD ||
                                      currentPrimaryRotationRate > SLOW_SWING_INITIAL_ROTATION_MIN_THRESHOLD

            if isUpOrientation && (isFastMotionTrigger || isSlowMotionTrigger) {
                isMonitoringSwing = true
                pitchAtPotentialStart = currentPitch
                timeOfPotentialStart = data.timestamp
                maxUserAccelerationMagnitudeDuringSwing = currentUserAccelMag
                maxPrimaryRotationRateDuringSwing = currentPrimaryRotationRate
            }
        } else {
            guard let startTime = timeOfPotentialStart else {
                isMonitoringSwing = false
                return
            }

            let elapsedTime = data.timestamp.timeIntervalSince(startTime)
            maxUserAccelerationMagnitudeDuringSwing = max(maxUserAccelerationMagnitudeDuringSwing, currentUserAccelMag)
            maxPrimaryRotationRateDuringSwing = max(maxPrimaryRotationRateDuringSwing, currentPrimaryRotationRate)

            if elapsedTime > SLOW_SWING_MAX_DURATION {
                isMonitoringSwing = false
                return
            }

            let pitchChange = pitchAtPotentialStart - currentPitch
            let endedReasonablyDown = currentPitch < PITCH_DOWN_THRESHOLD_MAX
            var detectedSwingType: String? = nil

            if elapsedTime <= FAST_SWING_MAX_DURATION &&
               pitchChange >= FAST_SWING_MIN_PITCH_CHANGE &&
               endedReasonablyDown &&
               elapsedTime >= FAST_SWING_MIN_DURATION &&
               maxUserAccelerationMagnitudeDuringSwing >= FAST_SWING_ACCELERATION_TRIGGER_THRESHOLD &&
               maxPrimaryRotationRateDuringSwing >= FAST_SWING_ROTATION_RATE_TRIGGER_THRESHOLD {
                detectedSwingType = "FAST"
            }
            else if elapsedTime <= SLOW_SWING_MAX_DURATION &&
                    pitchChange >= SLOW_SWING_MIN_PITCH_CHANGE &&
                    endedReasonablyDown &&
                    elapsedTime >= SLOW_SWING_MIN_DURATION &&
                    (maxUserAccelerationMagnitudeDuringSwing > SLOW_SWING_INITIAL_ACCEL_MIN_THRESHOLD ||
                     maxPrimaryRotationRateDuringSwing > SLOW_SWING_INITIAL_ROTATION_MIN_THRESHOLD) {
                detectedSwingType = "SLOW"
            }

            if let type = detectedSwingType {
                totalSwing += 1
                lastDetectedMotion = "\(type) Swing (\(totalSwing))"
                print("Player \(playerName) (P\(playerNumber)) --- \(type) UP-TO-DOWN SWING DETECTED! --- Total: \(totalSwing)")
                performSwingAction()
                startCooldown()
                isMonitoringSwing = false
            } else if pitchChange < -0.35 {
                isMonitoringSwing = false
            }
        }
    }

    private func performSwingAction() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // ... (boat controller logic) ...
            if let controller = self.boatController {
                if self.playerNumber == 1 || self.playerNumber == 3 {
                    controller.paddleLeft()
                } else if self.playerNumber == 2 || self.playerNumber == 4 {
                    controller.paddleRight()
                }
            }
        }
    }

    private func startCooldown() {
        isSwingCooldownActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + SWING_COOLDOWN_DURATION) { [weak self] in
            guard let self = self else { return }
            self.isSwingCooldownActive = false
        }
    }
    
    // This is the primary entry point for new motion data from the device.
    func updateGyroData(_ data: GyroData) {
        // Process the full GyroData for the specific "up-to-down swing" detection
        self.processMotionDataForSwing(data: data)

    }

    static func samplePlayers() -> [Player] {
        return [
            Player(playerNumber: 1, playerName: "A", playerColorHex: "#FF0000", peerID: MCPeerID(displayName: "iPhone 15"), deviceName: "Player 1 iPhone", connectionState: .connected, lastDetectedMotion: "Smash", boatController: nil),
            Player(playerNumber: 2, playerName: "B", playerColorHex: "#0000FF", peerID: MCPeerID(displayName: "iPhone 14"), deviceName: "Player 2 iPhone", connectionState: .connected, lastDetectedMotion: "Idle", boatController: nil),
            Player(playerNumber: 3, playerName: "C", playerColorHex: "#00FF00", peerID: MCPeerID(displayName: "iPhone 13"), deviceName: "Player 3 iPhone", connectionState: .disconnected, boatController: nil),
            Player(playerNumber: 4, playerName: "D", playerColorHex: "#FFFF00", peerID: MCPeerID(displayName: "iPhone SE"), deviceName: "Player 4 iPhone", connectionState: .connecting, boatController: nil)
        ]
    }
}
