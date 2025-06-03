// Skyloon Crew/_Game/UI/Screen/GameOverlayView.swift
import SwiftUI

struct GameOverlayView: View {
    @ObservedObject var viewModel: InfoViewModel
    @ObservedObject var connectionManager: ConnectionManager // Added

    // Action closures from GameViewController
    var onRestartGame: () -> Void
    var onChangeGameMode: () -> Void
    var onBackToTitle: () -> Void
    var onShowLeaderboard: () -> Void


    var body: some View {
        GeometryReader { geometry in
            let basePadding = max(8, min(geometry.size.width, geometry.size.height) * 0.015)
            let isSmallHeight = geometry.size.height < 400

            VStack(alignment: .center, spacing: basePadding * 0.5) {
                if viewModel.isGameOver {
                    gameOverContent(geometry: geometry, basePadding: basePadding)
                } else {
                    gamePlayContent(geometry: geometry, basePadding: basePadding, isSmallHeight: isSmallHeight)
                }
            }
            .padding(basePadding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .background(Color.black.opacity(0.001))
        }
    }

    @ViewBuilder
    private func gamePlayContent(geometry: GeometryProxy, basePadding: CGFloat, isSmallHeight: Bool) -> some View {
        let questionBoxMaxWidth = geometry.size.width * 0.9
        let questionBoxMaxHeight = geometry.size.height * (isSmallHeight ? 0.3 : 0.2)
        let infoBoxPadding = basePadding * 0.75
        let infoBoxCornerRadius = basePadding * 0.6

        ZStack {
            // Main HUD elements
            VStack(spacing: basePadding * 0.5) {
                HStack {
                    HealthDisplayView(currentHealth: viewModel.health)
                        .padding(.trailing, basePadding * 0.5)
                    Spacer()
                }
                .padding(.bottom, basePadding * 0.25)
                
                Text(viewModel.currentQuestionText)
                    .font(.system(size: 50, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(infoBoxPadding)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(infoBoxCornerRadius)
                    .frame(maxWidth: questionBoxMaxWidth, maxHeight: questionBoxMaxHeight)
                
                Spacer()
                
                HStack {
                    HStack {
                        Image("UI_Icon_Database")
                            .resizable()
                            .frame(width: 40, height: 40)
                        Text("\(viewModel.score)")
                            .font(.system(size: 30, weight: .bold))
                            .minimumScaleFactor(0.7)
                            .foregroundColor(.white)
                            .padding(infoBoxPadding * 0.8)
                            .cornerRadius(infoBoxCornerRadius * 0.8)
                    }
                    .padding(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
                    .background(
                        Image("UI_Bar")
                            .resizable(
                                capInsets: EdgeInsets(top: 29, leading: 29, bottom: 29, trailing: 29),
                                resizingMode: .stretch
                            )
                    )
                    
                    Spacer()
                    
                    HStack{
                        Image("UI_Icon_AlarmClock")
                            .resizable()
                            .frame(width: 40, height: 40)
                        Text("\(viewModel.timeLeft)")
                            .font(.system(size: 30, weight: .bold))
                            .minimumScaleFactor(0.7)
                            .foregroundColor(viewModel.timeLeft <= 10 ? .red : .yellow)
                            .padding(infoBoxPadding * 0.8)
                    }
                    .padding(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
                    .background(
                        Image("UI_Bar")
                            .resizable(
                                capInsets: EdgeInsets(top: 29, leading: 29, bottom: 29, trailing: 29),
                                resizingMode: .stretch
                            )
                    )
                }
            }

            // Game Message (centered)
            // This message (Correct/Wrong/Time's Up) should ideally not show when GameOverView is active.
            // The viewModel.isGameOver condition for showing gameOverContent handles this.
            if !viewModel.gameMessage.isEmpty && !viewModel.isGameOver {
                Text(viewModel.gameMessage)
                    .font(isSmallHeight ? .caption : .headline)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(viewModel.gameMessage.contains("Correct") ? .green : (viewModel.gameMessage.contains("Wrong") || viewModel.gameMessage.contains("Time's Up") ? .orange : .yellow ))
                    .padding(basePadding)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(infoBoxCornerRadius)
                    .shadow(radius: 3)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .frame(maxWidth: geometry.size.width * 0.75)
            }
        }
    }

    @ViewBuilder
    private func gameOverContent(geometry: GeometryProxy, basePadding: CGFloat) -> some View {
        GameOverView(
            connectionManager: connectionManager,
            infoViewModel: viewModel,
            onRestartGame: onRestartGame,
            onChangeGameMode: onChangeGameMode,
            onBackToTitle: onBackToTitle,
            onShowLeaderboard: onShowLeaderboard
        )
        // Ensure GameOverView takes up the full available space if desired
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
}

// Preview
struct GameOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        let previewViewModel = InfoViewModel()
        previewViewModel.score = 100
        previewViewModel.health = 2
        previewViewModel.currentQuestionText = "What is the color of the sky on a sunny day if you are a fish looking up from a puddle of blue paint?"
        previewViewModel.timeLeft = 15
        previewViewModel.gameMessage = "Correct!"

        let gameOverViewModel = InfoViewModel()
        gameOverViewModel.isGameOver = true
        gameOverViewModel.score = 150 // Make sure score is set for GameOver preview
        gameOverViewModel.gameMessage = "Final Score: 150" // This message is now handled inside GameOverView

        let connManager = ConnectionManager()
        connManager.players = Player.samplePlayers() // Add sample players

        return Group {
            GameOverlayView(
                viewModel: previewViewModel,
                connectionManager: connManager, // Pass manager
                onRestartGame: { print("Preview: Restart") },
                onChangeGameMode: { print("Preview: Change Mode") },
                onBackToTitle: { print("Preview: Back to Title") },
                onShowLeaderboard: { print("Preview: Leaderboard") }
            )
            .frame(width: 800, height: 600).previewDisplayName("Gameplay 800x600")
            .preferredColorScheme(.dark)
            
            GameOverlayView(
                viewModel: gameOverViewModel,
                connectionManager: connManager, // Pass manager
                onRestartGame: { print("Preview: Restart") },
                onChangeGameMode: { print("Preview: Change Mode") },
                onBackToTitle: { print("Preview: Back to Title") },
                onShowLeaderboard: { print("Preview: Leaderboard") }
            )
            .frame(width: 1200, height: 800).previewDisplayName("Game Over 1200x800") // Updated name
            .preferredColorScheme(.dark)
        }
    }
}
