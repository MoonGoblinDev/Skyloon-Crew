import SwiftUI

struct PlayerColumnView: View {
    @ObservedObject var player: Player

    var body: some View {
        GeometryReader { geometry in
            let totalHeight = geometry.size.height
            let availableWidth = geometry.size.width

            // Define height ratios for each element
            let nameBoxHeightRatio: CGFloat = 0.20
            let modelHeightRatio: CGFloat = 0.52
            let statusHeightRatio: CGFloat = 0.18 // Remaining space for status + spacing

            // Calculate actual heights
            let nameBoxHeight = totalHeight * nameBoxHeightRatio
            let modelHeight = totalHeight * modelHeightRatio
            let statusHeight = totalHeight * statusHeightRatio

            // Calculate font sizes and paddings based on element heights or available width
            let nameFontSize = max(10, min(nameBoxHeight * 0.45, availableWidth * 0.12))
            let nameBoxCornerRadius = nameBoxHeight * 0.3
            let nameBoxLineWidth = max(1.5, nameBoxHeight * 0.08)
            
            // For BearModelView, maintain aspect ratio if possible, or fit into allocated space
            // Let model width be proportional to its height, e.g., 2:3 (width:height)
            let modelTargetWidth = modelHeight * (2.0/3.0)
            let modelRenderWidth = min(availableWidth * 0.90, modelTargetWidth) // Don't exceed column width
            let modelCornerRadius = modelRenderWidth * 0.1
            
            let statusFontSize = max(9, min(statusHeight * 0.35, availableWidth * 0.1))
            let statusPaddingH = statusFontSize * 1.2
            let statusPaddingV = statusFontSize * 0.6
            let statusLineWidth = max(1, statusHeight * 0.07)

            let verticalSpacing = totalHeight * 0.025 // Small spacing between elements

            VStack(alignment: .center, spacing: verticalSpacing) {
                // Player Name Box
                Image("UI_Panel_Window_Blank" )
                    .resizable(
                        capInsets: EdgeInsets(top: 29, leading: 29, bottom: 29, trailing: 29),
                        resizingMode: .stretch
                        )
                    .frame(width: availableWidth * 0.9, height: nameBoxHeight * 0.5)
                    .overlay {
                        Text.gameFont(player.playerName)
                            .minimumScaleFactor(0.5).lineLimit(1)
                            .foregroundColor(.black)
                    }
                    .padding()
                
                // Bear Model
                let colorToShow = player.connectionState == .connected ? Color(hex: player.playerColorHex)! : .black.opacity(0.7)
                BearModelView(playerColor: colorToShow)
                    .frame(width: modelRenderWidth * 1.4, height: modelHeight)
                    .cornerRadius(modelCornerRadius)
                    .opacity(player.connectionState == .connected ? 1.0 : 0.6) // Dim if not connected
                    
                
                // Status Text
                Text(player.connectionState == .connected ? "Ready" : "Waiting")
                    .font(.system(size: statusFontSize, weight: .medium, design: .rounded))
                    .minimumScaleFactor(0.7).lineLimit(1)
                    .foregroundColor(.black)
                    .padding(.horizontal, statusPaddingH)
                    .padding(.vertical, statusPaddingV)
                    .background(
                        Capsule().fill(Color.white.opacity(0.9))
                            .overlay(Capsule().stroke(Color.black.opacity(0.7), lineWidth: statusLineWidth))
                    )
                    .frame(minHeight: statusHeight * 0.8, maxHeight: statusHeight) // Give status text flexible height within its slot
            }
            .frame(width: geometry.size.width, height: geometry.size.height) 
        }
    }
}

struct PlayerColumnView_Preview: PreviewProvider {
    static var previews: some View {
        let manager = ConnectionManager()
        // Add sample players for preview if needed
        // manager.players = Player.samplePlayers()
        WaitingForPlayerView(connectionManager: manager, navigateToGame: { })
            .frame(width: 900, height: 700).previewDisplayName("900x700")
        WaitingForPlayerView(connectionManager: manager, navigateToGame: { })
            .frame(width: 1200, height: 800).previewDisplayName("1200x800")
        WaitingForPlayerView(connectionManager: manager, navigateToGame: { })
            .frame(width: 600, height: 900).previewDisplayName("600x900 (Tall)")
    }
}
