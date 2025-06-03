import SwiftUI
import SceneKit

struct WaitingForPlayerView: View {
    @ObservedObject var connectionManager: ConnectionManager
    var navigateToGame: () -> Void

    var body: some View {
        GeometryReader { geometry in
            
            let numPlayers = CGFloat(max(1, connectionManager.players.count))
            let idealColumnSpacing = geometry.size.width * 0.04
            // Calculate width for columns, ensuring they don't get too cramped
            let totalHorizontalPadding = idealColumnSpacing * 2 // Padding on left/right of the HStack
            let totalInterColumnSpacing = idealColumnSpacing * (numPlayers - 1)
            let availableWidthForColumns = geometry.size.width - totalHorizontalPadding - totalInterColumnSpacing
            let columnWidth = max(geometry.size.width * 0.15, availableWidthForColumns / numPlayers) // Each column at least 15% of total width
            let columnHeight = geometry.size.height * 0.55 // Columns take up a good portion of height

            let startButtonFontSize = max(18, min(geometry.size.width * 0.03, geometry.size.height * 0.04))
            let startButtonCornerRadius = startButtonFontSize * 0.5
            let bottomPaddingForButton = geometry.size.height * 0.05

            ZStack {
                Color.black.opacity(0)
                GameCanvas(title:"Waiting for Player") {
                    HStack() {
                        Grid(alignment: .top, horizontalSpacing: 0, verticalSpacing: 0) {
                            GridRow {
                                PlayerColumnView(player: connectionManager.players[0])
                                    .frame(width: columnWidth, height: columnHeight - 130)
                                PlayerColumnView(player: connectionManager.players[1])
                                    .frame(width: columnWidth, height: columnHeight - 130)
                            }
                            GridRow {
                                PlayerColumnView(player: connectionManager.players[2])
                                    .frame(width: columnWidth, height: columnHeight - 130)
                                PlayerColumnView(player: connectionManager.players[3])
                                    .frame(width: columnWidth, height: columnHeight - 130)
                            }
                        }
                        
                        VStack {
                            ZStack {
                                Image("QR")
                                    .resizable()
                                    .frame(maxWidth: columnWidth * 2, maxHeight: columnWidth * 2)
                                    
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .padding(10)
                            }
                            .background(
                                Image("UI_Bar")
                                    .resizable(
                                        capInsets: EdgeInsets(top: 29, leading: 29, bottom: 29, trailing: 29),
                                        resizingMode: .stretch
                                    )
                                    
                            ).padding()
                            GameButton(
                                state: GameButtonState.grey,
                                action: {
                                    navigateToGame()
                                    GameSoundManager.shared.playUI(.success)
                                    GameSoundManager.shared.stopBGM(fadeOut: true)
                                }) {
                                    HStack {
                                        Text.gameFont("Start Adventure", fontSize: startButtonFontSize * 1.4 )
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                        }

                    }
                    .padding()
                    .onAppear {
                        connectionManager.startHosting()
                    }
                }
            }
        }
    }
}
    

struct WaitingForPlayerView_Previews: PreviewProvider {
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
