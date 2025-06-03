// Challenge2/Models/Player.swift
import Foundation
import MultipeerConnectivity
import SwiftUI
import SceneKit // << ADD SceneKit import

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
    weak var assignedWingNode: SCNNode? // << ADDED

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
        let currentPrimaryRotationRate = abs(data.rotationX) // Assuming rotationX is primary for paddle swing direction

        if !isMonitoringSwing {
            // Check for potential start of a swing
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
                // print("Player \(playerName): Potential swing start. Pitch: \(String(format: "%.2f", currentPitch)), AccelMag: \(String(format: "%.2f", currentUserAccelMag)), RotRate: \(String(format: "%.2f", currentPrimaryRotationRate))")
            }
        } else {
            // Monitor ongoing potential swing
            guard let startTime = timeOfPotentialStart else {
                isMonitoringSwing = false // Should not happen if isMonitoringSwing is true
                return
            }

            let elapsedTime = data.timestamp.timeIntervalSince(startTime)
            maxUserAccelerationMagnitudeDuringSwing = max(maxUserAccelerationMagnitudeDuringSwing, currentUserAccelMag)
            maxPrimaryRotationRateDuringSwing = max(maxPrimaryRotationRateDuringSwing, currentPrimaryRotationRate)

            // Timeout for swing detection
            if elapsedTime > SLOW_SWING_MAX_DURATION { // Use the longest possible duration as a hard timeout
                // print("Player \(playerName): Swing timed out. Elapsed: \(String(format: "%.2f", elapsedTime))s")
                isMonitoringSwing = false
                return
            }

            // Check for swing completion criteria
            let pitchChange = pitchAtPotentialStart - currentPitch
            let endedReasonablyDown = currentPitch < PITCH_DOWN_THRESHOLD_MAX

            var detectedSwingType: String? = nil

            // Fast Swing detection
            if elapsedTime <= FAST_SWING_MAX_DURATION &&
               pitchChange >= FAST_SWING_MIN_PITCH_CHANGE &&
               endedReasonablyDown &&
               elapsedTime >= FAST_SWING_MIN_DURATION &&
               maxUserAccelerationMagnitudeDuringSwing >= FAST_SWING_ACCELERATION_TRIGGER_THRESHOLD &&
               maxPrimaryRotationRateDuringSwing >= FAST_SWING_ROTATION_RATE_TRIGGER_THRESHOLD {
                detectedSwingType = "FAST"
            }
            // Slow Swing detection (else if to ensure only one type is picked)
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
                DispatchQueue.main.async { // Ensure UI updates are on main thread
                    self.lastDetectedMotion = "\(type) Swing (\(self.totalSwing))"
                }
                print("Player \(playerName) (P\(playerNumber)) --- \(type) UP-TO-DOWN SWING DETECTED! --- Total: \(totalSwing)")
                performSwingAction() // This will now include wing animation
                startCooldown()
                isMonitoringSwing = false // Reset for next swing
            } else if pitchChange < -0.35 { // Abort if pitch goes up significantly (reset)
                // print("Player \(playerName): Swing aborted (pitch went up). PitchChange: \(String(format: "%.2f", pitchChange))")
                isMonitoringSwing = false
            }
        }
    }

    private func performSwingAction() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Boat movement logic
            if let controller = self.boatController {
                if self.playerNumber == 1 || self.playerNumber == 3 { // Left side players
                    controller.paddleLeft()
                } else if self.playerNumber == 2 || self.playerNumber == 4 { // Right side players
                    controller.paddleRight()
                }
            }

            // Wing animation logic
            guard let wingNode = self.assignedWingNode else {
                // print("Player \(self.playerName) has no assigned wing node for animation.")
                return
            }

            let animationDuration: TimeInterval = 0.25 // Duration for one way rotation
            let rotationAngle = CGFloat.pi / 6 // 30 degrees

            // Action to rotate wing out
            let rotateOutAction = SCNAction.rotate(by: rotationAngle, around: SCNVector3(0, 0, 1), duration: animationDuration)
            rotateOutAction.timingMode = .easeInEaseOut

            // Action to rotate wing back in
            let rotateInAction = SCNAction.rotate(by: -rotationAngle, around: SCNVector3(0, 0, 1), duration: animationDuration)
            rotateInAction.timingMode = .easeInEaseOut

            // Sequence the actions
            let wingAnimation = SCNAction.sequence([rotateOutAction, rotateInAction])

            // Run the animation, using a key to prevent multiple overlapping animations if called rapidly
            // (though swing cooldown should prevent this)
            wingNode.runAction(wingAnimation, forKey: "wingPaddleAnimationPlayer\(self.playerNumber)")
            // print("Player \(self.playerName) animating wing: \(wingNode.name ?? "Unnamed Wing")")
        }
    }

    private func startCooldown() {
        isSwingCooldownActive = true
        // print("Player \(playerName): Swing cooldown started.")
        DispatchQueue.main.asyncAfter(deadline: .now() + SWING_COOLDOWN_DURATION) { [weak self] in
            guard let self = self else { return }
            self.isSwingCooldownActive = false
            // print("Player \(self.playerName): Swing cooldown ended.")
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
