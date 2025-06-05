// Challenge2/Managers/ConnectionManager.swift
import Foundation
import MultipeerConnectivity
import Combine
import os.log
import SwiftUI

class ConnectionManager: NSObject, ObservableObject {
    private let serviceType = "skyloon" // Consider using Constants.serviceType
    private let logger = Logger(subsystem: "com.yourdomain.TennisGameHost", category: "ConnectionManager")
    
    private var session: MCSession
    private var serviceAdvertiser: MCNearbyServiceAdvertiser
    private var serviceBrowser: MCNearbyServiceBrowser
    
    // Published properties for UI updates
    @Published var players: [Player] = []
    @Published var isHosting: Bool = false
    @Published var browserError: String?
    @Published var advertiserError: String?
    
    // Maximum number of players
    private let maxPlayers = Constants.maxPlayers // Use constant
    

    override init() {
        let localPeerID = MCPeerID(displayName: Host.current().localizedName ?? "Mac Host")
        self.session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        
        self.players = (1...maxPlayers).map { playerNum in
            Player(playerNumber: playerNum, playerName: "Player \(playerNum)", playerColorHex: Color.red.toHex(), peerID: localPeerID, lastDetectedMotion: "Idle") // Initialize with default motion
        }
        
        super.init()
        
        self.session.delegate = self
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
    }
    
    // ... (startHosting, stopHosting, sendDataToAllPeers methods remain the same) ...
    func startHosting() {
        logger.info("Starting to host game session")
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
        isHosting = true
    }
    
    func stopHosting() {
        logger.info("Stopping game session hosting")
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        
        session.connectedPeers.forEach { peerID in
            session.cancelConnectPeer(peerID) // Actively cancel connections
        }

        // It's safer to iterate over a copy if modifying `players` or use indices
        for i in players.indices {
             if players[i].connectionState != .disconnected {
                 // Create a dummy MCPeerID for players that were never truly connected but occupied a slot
                 let placeholderPeerID = MCPeerID(displayName: players[i].peerID.displayName) // Use existing or a placeholder name
                 updatePlayerConnectionState(peerID: placeholderPeerID, state: .disconnected, resetPlayerSlotIndex: i)
             }
        }
        session.disconnect() // Disconnect the session itself
        isHosting = false
    }

    func sendDataToAllPeers(_ data: Data) {
        guard !session.connectedPeers.isEmpty else { return }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            logger.error("Error sending data to peers: \(error.localizedDescription)")
        }
    }
    
    private func findAvailablePlayerSlot() -> Int? {
        for (index, player) in players.enumerated() {
            // A slot is available if it's marked disconnected AND its peerID is the host's (placeholder)
            if player.connectionState == .disconnected && player.peerID.displayName == (Host.current().localizedName ?? "Mac Host") {
                return index
            }
        }
        // If all slots have non-host peer IDs but some are disconnected, we might need to reset one.
        // For robust handling, it's better if slots are explicitly freed.
        // Current logic assumes a slot with host peerID is "truly" empty.
        return players.firstIndex(where: { $0.connectionState == .disconnected })
    }
    
    // Update player connection state
    private func updatePlayerConnectionState(peerID: MCPeerID, state: ConnectionState, resetPlayerSlotIndex: Int? = nil) {
        DispatchQueue.main.async {
            // If resetting a specific slot (e.g., on explicit disconnect or stopHosting)
            if let indexToReset = resetPlayerSlotIndex, self.players.indices.contains(indexToReset) {
                 self.players[indexToReset].connectionState = .disconnected
                 self.players[indexToReset].deviceName = ""
                 self.players[indexToReset].currentGyroData = GyroData() // Reset data
                 self.players[indexToReset].lastDetectedMotion = "Idle"
                 // Reset peerID to host's placeholder to mark slot as truly available
                 self.players[indexToReset].peerID = MCPeerID(displayName: Host.current().localizedName ?? "Mac Host")
                 self.logger.info("Player slot \(self.players[indexToReset].playerNumber) reset and disconnected.")
                 return
            }

            // Standard update logic
            if let index = self.players.firstIndex(where: { $0.peerID.displayName == peerID.displayName && $0.connectionState != .disconnected && $0.connectionState != .connecting }) {
                // Existing connected or connecting player changing state (e.g., to disconnected)
                self.players[index].connectionState = state
                if state == .disconnected {
                    self.players[index].deviceName = "" // Clear device name
                    self.players[index].currentGyroData = GyroData() // Reset data
                    self.players[index].lastDetectedMotion = "Idle" // Reset motion
                     // Reset peerID to host's placeholder to mark slot as truly available
                    self.players[index].peerID = MCPeerID(displayName: Host.current().localizedName ?? "Mac Host")
                    self.logger.info("Player \(peerID.displayName) disconnected. Slot \(self.players[index].playerNumber) freed.")
                }
            } else if state == .connected { // New connection
                 // This case is handled in MCSessionDelegate's .connected state change
            } else if state == .connecting {
                 // This case is handled in MCSessionDelegate's .connecting state change
            }
        }
    }

    // Process received gyro data
    private func processReceivedGyroData(_ data: Data, from peerID: MCPeerID) {
        do {
            let data = try JSONDecoder().decode(SessionWrapperData.self, from: data)
            let gyroData = data.gyro
            
            if let playerIndex = players.firstIndex(where: { $0.peerID == peerID && $0.connectionState == .connected }) {
                // Dispatching to main thread for UI updates if Player properties are @Published
                DispatchQueue.main.async {
                    self.players[playerIndex].updateGyroData(gyroData) // This method already dispatches to main
                    self.players[playerIndex].deviceName = data.device
                    self.players[playerIndex].playerName = data.player.name
                    self.players[playerIndex].playerColorHex = data.player.colorHex
                    
                    print(data.player)
                    
                    // Todo: Check movement gyro
                    //self.players[playerIndex].addMotionData(gyroData.accelerationY)


                }
            }
        } catch {
            logger.error("Error decoding gyro data or predicting motion: \(error.localizedDescription)")
        }
    }
}

// MARK: - MCSessionDelegate
extension ConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            //self.logger.info("Peer \(peerID.displayName) changed state to \(state.rawValue) (\(stateDescription(state)))")
            
            switch state {
            case .connected:
                if let index = self.findAvailablePlayerSlot() {
                    if self.players[index].connectionState != .connected { // Avoid re-assigning if already set up
                        self.players[index].peerID = peerID
                        self.players[index].deviceName = peerID.displayName // Or extract from discoveryInfo if richer
                        self.players[index].connectionState = .connected
                        self.players[index].lastDetectedMotion = "Idle" // Reset motion on connect
                        self.logger.info("Peer \(peerID.displayName) connected as Player \(self.players[index].playerNumber).")
                    }
                } else {
                    self.logger.warning("No available slot for \(peerID.displayName). Max players: \(self.maxPlayers). Connected: \(session.connectedPeers.count)")
                    // Optionally, you might disconnect this peer if no slot is available,
                    // though MCNearbyServiceAdvertiserDelegate should prevent this.
                    session.cancelConnectPeer(peerID)
                }

            case .connecting:
                // Find an available slot to tentatively assign or just log
                if let slotIndex = self.findAvailablePlayerSlot() {
                    // You could mark players[slotIndex].connectionState = .connecting here,
                    // but it's better to wait for .connected to assign the peerID definitely.
                    self.logger.info("Peer \(peerID.displayName) is connecting (potential Player \(self.players[slotIndex].playerNumber)).")
                } else {
                    self.logger.info("Peer \(peerID.displayName) is connecting, but no slots appear free.")
                }

            case .notConnected:
                if let index = self.players.firstIndex(where: { $0.peerID.displayName == peerID.displayName }) {
                    if self.players[index].connectionState != .disconnected {
                        let playerNumber = self.players[index].playerNumber
                        self.players[index].connectionState = .disconnected
                        self.players[index].deviceName = ""
                        self.players[index].currentGyroData = GyroData()
                        self.players[index].lastDetectedMotion = "Idle"
                        // Reset peerID to host to mark slot as available
                        self.players[index].peerID = MCPeerID(displayName: Host.current().localizedName ?? "Mac Host")
                        self.logger.info("Peer \(peerID.displayName) (Player \(playerNumber)) disconnected.")
                    }
                } else {
                     self.logger.info("Peer \(peerID.displayName) became not connected (was not actively tracked or already removed).")
                }
                 // If a peer disconnects, ensure `advertiser.startAdvertisingPeer()` is called if you want to accept new connections,
                 // and `browser.startBrowsingForPeers()` if you want to find new peers.
                 // This might already be handled if `isHosting` is true.

            @unknown default:
                self.logger.error("Unknown session state for \(peerID.displayName): \(state.rawValue)")
            }
        }
    }
    
    private func stateDescription(_ state: MCSessionState) -> String {
        switch state {
        case .notConnected: return "Not Connected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        @unknown default: return "Unknown"
        }
    }

    // ... (other MCSessionDelegate methods: didReceive data, stream, resource) ...
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        processReceivedGyroData(data, from: peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        logger.info("Received stream: \(streamName) from \(peerID.displayName). Not handled.")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        logger.info("Started receiving resource: \(resourceName) from \(peerID.displayName). Not handled.")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error = error {
            logger.error("Error receiving resource \(resourceName) from \(peerID.displayName): \(error.localizedDescription)")
            return
        }
        logger.info("Finished receiving resource \(resourceName) from \(peerID.displayName) at \(localURL?.path ?? "nil"). Not handled.")
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        logger.info("Received invitation from peer: \(peerID.displayName)")
        
        // Check if we have room for more players based on *currently connected* peers in the session
        // and also if there's an "available" slot in our `players` array.
        let connectedPeersCount = session.connectedPeers.count
        let availableSlotExists = players.contains(where: { $0.connectionState == .disconnected && $0.peerID.displayName == (Host.current().localizedName ?? "Mac Host") }) || connectedPeersCount < maxPlayers

        if connectedPeersCount < maxPlayers && availableSlotExists {
            logger.info("Accepting invitation from \(peerID.displayName).")
            invitationHandler(true, session)
        } else {
            //logger.warning("Rejected invitation from \(peerID.displayName). Max players (\(maxPlayers)) reached or no slots: \(connectedPeersCount) connected.")
            invitationHandler(false, nil)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        logger.error("Failed to start advertising: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.advertiserError = error.localizedDescription
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension ConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        logger.info("Found peer: \(peerID.displayName) with info: \(String(describing: info))")
        
        // Invite peer if we have room for more players
        // Check against session.connectedPeers and also ensure we haven't already invited this peer
        // or they are not already connected/connecting.
        guard !session.connectedPeers.contains(peerID) else {
            logger.info("Peer \(peerID.displayName) is already connected or connecting. Won't re-invite.")
            return
        }
        
        // Check if this peerID is already in our players list in a non-disconnected state (e.g. connecting from their side)
        if let existingPlayer = players.first(where: { $0.peerID == peerID && $0.connectionState != .disconnected }) {
            //logger.info("Peer \(peerID.displayName) Player \(existingPlayer.playerNumber) found, already tracked with state \(existingPlayer.connectionState). Won't re-invite.")
            return
        }

        let connectedPeersCount = session.connectedPeers.count
        if connectedPeersCount < maxPlayers {
            logger.info("Inviting peer \(peerID.displayName) to session.")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: Constants.connectionTimeout)
        } else {
            logger.info("Found peer \(peerID.displayName), but max players (\(self.maxPlayers)) reached. Not inviting. Connected: \(connectedPeersCount)")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        logger.info("Lost peer from browser: \(peerID.displayName). Session delegate will handle disconnection if it was connected.")
        // This callback means the peer is no longer advertising or discoverable.
        // The MCSessionDelegate handles actual connection state changes.
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        logger.error("Failed to start browsing: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.browserError = error.localizedDescription
        }
    }
}
