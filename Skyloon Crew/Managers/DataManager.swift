// Challenge2/Managers/DataManager.swift
import Foundation
import Combine
import os.log

class DataManager: ObservableObject {
    private let logger = Logger(subsystem: "com.yourdomain.TennisGameHost", category: "DataManager")
    
    @Published var gyroDataHistory: [String: [GyroData]] = [:]
    @Published var lastProcessedTimestamp: Date = Date()
    
    @Published var movementStats: [String: MovementStats] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupTimers()
    }
    
    func processGyroData(_ data: GyroData, from playerID: String) {
        DispatchQueue.main.async {
            if self.gyroDataHistory[playerID] == nil {
                self.gyroDataHistory[playerID] = []
            }
            var history = self.gyroDataHistory[playerID] ?? []
            history.append(data)
            if history.count > 100 {
                history.removeFirst(history.count - 100)
            }
            self.gyroDataHistory[playerID] = history
            self.updateMovementStats(for: playerID)
            self.lastProcessedTimestamp = Date()
        }
    }
    
    private func updateMovementStats(for playerID: String) {
        guard let history = gyroDataHistory[playerID], history.count >= 2 else {
            return
        }
        
        let samples = min(10, history.count)
        let recentData = Array(history.suffix(samples))
        
        // Calculate average rotation magnitude
        let avgMagnitude = recentData.map { $0.rotationMagnitude }.reduce(0, +) / Double(recentData.count)
        
        // Calculate max values for each rotation axis
        let maxX = recentData.map { abs($0.rotationX) }.max() ?? 0
        let maxY = recentData.map { abs($0.rotationY) }.max() ?? 0
        let maxZ = recentData.map { abs($0.rotationZ) }.max() ?? 0
        
        let stats = MovementStats(
            averageMagnitude: avgMagnitude, // Represents average rotation magnitude
            maxX: maxX, // Max absolute rotation X
            maxY: maxY, // Max absolute rotation Y
            maxZ: maxZ, // Max absolute rotation Z
            timestamp: Date()
        )
        
        movementStats[playerID] = stats
    }
    
    func clearPlayerData(for playerID: String) {
        DispatchQueue.main.async {
            self.gyroDataHistory.removeValue(forKey: playerID)
            self.movementStats.removeValue(forKey: playerID)
        }
    }
    
    private func setupTimers() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupOldData()
            }
            .store(in: &cancellables)
    }
    
    private func cleanupOldData() {
        let currentTime = Date()
        let staleThreshold: TimeInterval = 300 // 5 minutes
        
        for playerID in gyroDataHistory.keys {
            if let lastStats = movementStats[playerID],
               currentTime.timeIntervalSince(lastStats.timestamp) > staleThreshold {
                clearPlayerData(for: playerID)
                logger.info("Cleared stale data for player: \(playerID)")
            }
        }
    }
}

struct MovementStats {
    var averageMagnitude: Double // Average rotation magnitude
    var maxX: Double // Max rotation X
    var maxY: Double // Max rotation Y
    var maxZ: Double // Max rotation Z
    var timestamp: Date
    
    // Determine if there's significant rotational movement
    var isSignificantMovement: Bool {
        return averageMagnitude > 0.5 // Threshold for rotation magnitude (rad/s)
    }
}
