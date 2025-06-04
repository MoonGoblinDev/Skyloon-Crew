// Skyloon Crew/_Game/UI/Screen/GameOverView.swift
import SwiftUI

struct GameOverView: View {
    @ObservedObject var connectionManager: ConnectionManager
    @ObservedObject var infoViewModel: InfoViewModel // Added

    // Action closures
    var onRestartGame: () -> Void
    var onChangeGameMode: () -> Void
    var onBackToTitle: () -> Void
    var onShowLeaderboard: () -> Void // Can be a print statement for now

    var body: some View {
        ZStack {
            Color.black.opacity(0) // Transparent background
            GameCanvas(title:"Game Over") {
                VStack(spacing: 20) { // Added spacing
                    Text("Final Score: \(infoViewModel.score)") // Display score
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(GameColorScheme().primaryText)
                        .padding(.bottom, 10)

                    HStack(spacing: 15){ // Added spacing for player stats
                        ForEach(connectionManager.players.filter { $0.connectionState == .connected }) { player in // Show only connected players
                            PlayerStats(name: player.playerName,character: player.character, swing: player.totalSwing, colorHex: player.playerColorHex) // Pass color
                        }
                    }
                    .padding(.bottom, 20)

                    // Game Action Buttons
                    VStack(spacing: 15) { // Group buttons for better layout potentially
                        HStack(spacing: 15) {
                            GameButton(
                                state: GameButtonState.green, // Changed color for restart
                                action: {
                                    GameSoundManager.shared.playUI(.buttonClick)
                                    onRestartGame()
                                }) {
                                Text.gameFont("Restart Game", fontSize: 24) // Adjusted font size
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .buttonStyle(PlainButtonStyle())

                            GameButton(
                                state: GameButtonState.blue, // Changed color
                                action: {
                                    GameSoundManager.shared.playUI(.buttonClick)
                                    onChangeGameMode()
                                }) {
                                Text.gameFont("Change Mode", fontSize: 24) // Adjusted font size
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        HStack(spacing: 15) {
                            GameButton(
                                state: GameButtonState.orange, // Changed color
                                action: {
                                    GameSoundManager.shared.playUI(.buttonClick)
                                    onShowLeaderboard()
                                }) {
                                Text.gameFont("Leaderboard", fontSize: 24) // Adjusted font size
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .buttonStyle(PlainButtonStyle())

                            GameButton(
                                state: GameButtonState.red, // Changed color for back to title
                                action: {
                                    GameSoundManager.shared.playUI(.buttonClick)
                                    onBackToTitle()
                                }) {
                                Text.gameFont("Title Screen", fontSize: 24) // Adjusted font size
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
            }
            .padding()
        }
    }
}

struct PlayerStats: View {
    let name: String
    let character: String
    let swing: Int
    let colorHex: String // Added color

    var body: some View {
        VStack {
            // Display BearModelView or colored circle
            if let playerUIColor = Color(hex: colorHex) {
                BearModelView(character: character)
                    .frame(width: 80, height: 100) // Adjust size as needed
                    .padding()
            } else {
                Circle() // Fallback
                    .fill(Color.gray)
                    .frame(width: 80, height: 80)
                    .padding()
            }
            
            Text.gameFont(name)
            Text.gameFont("Swings: \(swing)", fontSize: 20)
        }
        .frame(minWidth: 180, idealWidth: 200, maxWidth: 220, minHeight: 250, maxHeight: 300) // Flexible sizing
        .background(
            Image("UI_Bar")
                .resizable(
                    capInsets: EdgeInsets(top: 29, leading: 29, bottom: 29, trailing: 29),
                    resizingMode: .stretch
                )
        )
        .padding(.horizontal, 5) // Add some horizontal padding between player stats
    }
}


struct GameOverPreview: PreviewProvider {
    static var previews: some View {
        let manager = ConnectionManager()
        manager.players = Player.samplePlayers() // Use sample players for preview
        let infoModel = InfoViewModel()
        infoModel.score = 150
        infoModel.isGameOver = true
        
        return GameOverView(
            connectionManager: manager,
            infoViewModel: infoModel,
            onRestartGame: { print("Preview: Restart Game") },
            onChangeGameMode: { print("Preview: Change Game Mode") },
            onBackToTitle: { print("Preview: Back to Title") },
            onShowLeaderboard: { print("Preview: Show Leaderboard") }
        )
        .frame(width: 1300, height: 700).previewDisplayName("1000x700")
        .background(Color.gray.opacity(0.3)) // Add a background to see the canvas
    }
}
