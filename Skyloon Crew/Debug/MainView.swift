// Challenge2/Views/MainView.swift
import SwiftUI

struct MainView: View {
    @ObservedObject private var connectionManager = ConnectionManager()
    
    var body: some View {
        VStack(spacing: Constants.UI.standardSpacing) { // Use constant
            Text(Constants.appName) // Use constant
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ConnectionStatusView(connectionManager: connectionManager)
                .frame(maxWidth: .infinity)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Constants.UI.tilePadding), // Use constant
                GridItem(.flexible(), spacing: Constants.UI.tilePadding)
            ], spacing: Constants.UI.tilePadding) {
                ForEach(connectionManager.players) { player in
                    PlayerTileView(player: player)
                        .frame(minHeight: 200, maxHeight: 250) // Adjusted height
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Instructions:")
                    .font(.headline)
                
                Text("1. Press 'Start Hosting' to begin accepting connections.")
                Text("2. Launch the Tennis Controller app on iPhones.")
                Text("3. Motion data will appear in the player tiles once connected.")
                
                if connectionManager.isHosting {
                    Text("Currently hosting a game session.")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                }
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(NSColor.textBackgroundColor)) // Consider custom color from Constants
            .cornerRadius(8)
            
            #if DEBUG
            Divider()
                .padding(.vertical, 10)
            
            Button("Simulate Motion Data") { // Renamed
                simulateMotionData()
            }
            .disabled(!connectionManager.isHosting)
            #endif
        }
        .padding(Constants.UI.contentPadding) // Use constant
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            // connectionManager.startHosting() // Optional: auto-start hosting
        }
    }
    
    #if DEBUG
    private func simulateMotionData() { // Renamed
        for (index, _) in connectionManager.players.enumerated() { // Iterate using index
            let player = connectionManager.players[index]
            if player.connectionState == .connected {
                let randomMotionData = GyroData(
                    accelerationX: Double.random(in: -2.0...2.0),      // Simulating Gs
                    accelerationY: Double.random(in: -2.0...2.0),
                    accelerationZ: Double.random(in: -2.0...2.0) + (Bool.random() ? 0.0 : 1.0), // Simulating various states of gravity presence
                    rotationX: Double.random(in: -7.0...7.0),        // Radians/sec
                    rotationY: Double.random(in: -7.0...7.0),
                    rotationZ: Double.random(in: -7.0...7.0),
                    roll: Double.random(in: -Double.pi...Double.pi),  // Radians
                    pitch: Double.random(in: -Double.pi/2...Double.pi/2),
                    yaw: Double.random(in: -Double.pi...Double.pi)
                )
                // Ensure updateGyroData is called on the main thread if Player is an ObservableObject and currentGyroData is @Published
                // Player's updateGyroData already dispatches to main
                player.updateGyroData(randomMotionData)
            }
        }
    }
    #endif
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .frame(width: 900, height: 700)
    }
}
