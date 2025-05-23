import SwiftUI
import MultipeerConnectivity

struct PlayerTileView: View {
    @ObservedObject var player: Player
    
    private let rotationRange: (min: Double, max: Double) = (-7.0, 7.0)
    private let accelerationRange: (min: Double, max: Double) = (-2.5, 2.5) // Gs
    private let rollYawRange: (min: Double, max: Double) = (-Double.pi, Double.pi)
    private let pitchRange: (min: Double, max: Double) = (-Double.pi / 2, Double.pi / 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(player.playerName)
                    .font(.headline)
                    .bold()
                    .foregroundColor(Color(hex: player.playerColorHex))
                Spacer()
                ConnectionStatusIndicator(state: player.connectionState)
            }
            
            Divider()
            
            Group {
                Text("Device:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(player.deviceName.isEmpty ? "Not Connected" : player.deviceName)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.bottom, 2)

            // Detected Motion Display
            if player.connectionState == .connected { // Only show if connected
                HStack {
                    Text("Swing Count:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(player.totalSwing)")
                        .font(.caption.bold())
                        .foregroundColor(.green) // Optional: color code motion
                        .animation(.easeInOut, value: player.totalSwing) // Animate text change
                }
                .padding(.bottom, 4)
            }
            
            VStack {
                Text("Real-time Data:") // Changed title slightly
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if player.connectionState == .connected {
                    ScrollView(.vertical, showsIndicators: true) {
                        Text(player.currentGyroData.formattedValues)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rotation (rad/s)")
                                .font(.caption2).foregroundColor(.gray)
                            DataVisualizer(
                                value1: player.currentGyroData.rotationX, value2: player.currentGyroData.rotationY, value3: player.currentGyroData.rotationZ,
                                labels: ("RX","RY","RZ"), colors: (.red, .green, .blue),
                                ranges: (rotationRange, rotationRange, rotationRange)
                            ).frame(height: 25)
                            
                            Text("Acceleration (Gs)")
                                .font(.caption2).foregroundColor(.gray).padding(.top, 2)
                            DataVisualizer(
                                value1: player.currentGyroData.accelerationX, value2: player.currentGyroData.accelerationY, value3: player.currentGyroData.accelerationZ,
                                labels: ("AX","AY","AZ"), colors: (.orange, .purple, .yellow),
                                ranges: (accelerationRange, accelerationRange, accelerationRange)
                            ).frame(height: 25)
                            
                            Text("Attitude (rad)")
                                .font(.caption2).foregroundColor(.gray).padding(.top, 2)
                            DataVisualizer(
                                value1: player.currentGyroData.roll, value2: player.currentGyroData.pitch, value3: player.currentGyroData.yaw,
                                labels: ("Roll","Pitch","Yaw"), colors: (.cyan, .orange, .brown),
                                ranges: (rollYawRange, pitchRange, rollYawRange)
                            ).frame(height: 25)
                        }
                    }
                    .frame(maxHeight: .infinity)
                     
                } else {
                    Text("No data available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(10)
        .background(Constants.UI.backgroundColor) // Use constant
        .cornerRadius(Constants.UI.tileCornerRadius) // Use constant
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.tileCornerRadius) // Use constant
                .stroke(connectionStateColor(player.connectionState), lineWidth: 2)
        )
        .animation(.default, value: player.connectionState) // Animate changes based on connection state
        .animation(.default, value: player.currentGyroData) // Animate changes based on GyroData for visualizations
    }
    
    private func connectionStateColor(_ state: ConnectionState) -> Color {
        switch state {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return Color.gray.opacity(0.7) // Slightly different for disconnected
        }
    }
    
}
#Preview {
    PlayerTileView(
        player: Player(
            playerNumber: 1,
            playerName: "A",
            playerColorHex: Color.red.toHex(),
            peerID: MCPeerID(displayName: "Test"),
            deviceName: "Test",
            connectionState: .disconnected,
            lastDetectedMotion:"Idle"
        )
    )
}

