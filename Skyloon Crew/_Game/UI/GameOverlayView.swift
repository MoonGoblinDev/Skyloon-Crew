// SwiftUI_UI/GameOverlayView.swift
import SwiftUI

struct GameOverlayView: View {
    @ObservedObject var viewModel: InfoViewModel
    var onRestartGame: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let basePadding = max(8, min(geometry.size.width, geometry.size.height) * 0.015)
            let isSmallHeight = geometry.size.height < 400 // Example threshold for very small screens

            VStack(alignment: .center, spacing: basePadding * 0.5) { // Scaled spacing
                if viewModel.isGameOver {
                    gameOverContent(geometry: geometry, basePadding: basePadding)
                } else {
                    gamePlayContent(geometry: geometry, basePadding: basePadding, isSmallHeight: isSmallHeight)
                }
            }
            .padding(basePadding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .background(Color.black.opacity(0.001)) // Minimal background for gesture hit testing if ever needed
        }
    }

    @ViewBuilder
    private func gamePlayContent(geometry: GeometryProxy, basePadding: CGFloat, isSmallHeight: Bool) -> some View {
        let questionBoxMaxWidth = geometry.size.width * 0.9
        let questionBoxMaxHeight = geometry.size.height * (isSmallHeight ? 0.3 : 0.2) // More space for question on small height screens
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
                .padding(.bottom, basePadding * 0.25) // Less padding if space is tight
                
                Text(viewModel.currentQuestionText)
                    .font(.headline)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(infoBoxPadding)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(infoBoxCornerRadius)
                    .frame(maxWidth: questionBoxMaxWidth, maxHeight: questionBoxMaxHeight)
                
                Spacer() // Pushes score/time to bottom
                
                HStack {
                    Text("Score: \(viewModel.score)")
                        .font(.title2)
                        .minimumScaleFactor(0.7)
                        .foregroundColor(.white)
                        .padding(infoBoxPadding * 0.8) // Slightly smaller padding for these
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(infoBoxCornerRadius * 0.8)
                    
                    Spacer()
                    
                    Text("Time: \(viewModel.timeLeft)")
                        .font(.title3)
                        .minimumScaleFactor(0.7)
                        .foregroundColor(viewModel.timeLeft <= 10 ? .red : .yellow)
                        .padding(infoBoxPadding * 0.8)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(infoBoxCornerRadius * 0.8)
                }
            }

            // Game Message (centered)
            if !viewModel.gameMessage.isEmpty {
                Text(viewModel.gameMessage)
                    .font(isSmallHeight ? .caption : .headline) // Smaller font for message on small screens
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(viewModel.gameMessage.contains("Correct") ? .green : (viewModel.gameMessage.contains("Wrong") || viewModel.gameMessage.contains("Time's Up") ? .orange : .yellow ))
                    .padding(basePadding)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(infoBoxCornerRadius)
                    .shadow(radius: 3)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .frame(maxWidth: geometry.size.width * 0.75) // Constrain width of message
            }
        }
    }

    @ViewBuilder
    private func gameOverContent(geometry: GeometryProxy, basePadding: CGFloat) -> some View {
        let panelMaxWidth = min(450, geometry.size.width * 0.85)
        let panelPadding = basePadding * 1.5
        let panelCornerRadius = basePadding
        let panelSpacing = basePadding * 1.2

        let buttonWidth = panelMaxWidth * 0.55
        let buttonHeight = max(40, min(buttonWidth * 0.28, geometry.size.height * 0.07)) // Dynamic height with min/max
        let buttonCornerRadius = buttonHeight * 0.25

        VStack { // This VStack centers the gameOver panel
            Spacer()
            VStack(spacing: panelSpacing) {
                Text("Game Over!")
                    .font(.system(size: max(24, min(panelMaxWidth * 0.12, geometry.size.height * 0.08)), weight: .bold)) // Scaled large title
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                
                Text(viewModel.gameMessage) // Shows final score
                    .font(.system(size: max(16, min(panelMaxWidth * 0.07, geometry.size.height * 0.05)))) // Scaled title2-like
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, panelPadding * 0.5)
                
                Button(action: { onRestartGame() }) {
                    Text("Restart Game")
                        .font(.system(size: max(16, min(buttonWidth * 0.15, buttonHeight * 0.4)))) // Scaled button text
                        .fontWeight(.semibold)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, basePadding * 0.5) // Internal padding for text
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(buttonCornerRadius)
                        .shadow(radius: 3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(panelPadding)
            .background(Color.black.opacity(0.75))
            .cornerRadius(panelCornerRadius)
            .frame(maxWidth: panelMaxWidth)
            .shadow(color: .black.opacity(0.3), radius: 10)
            Spacer()
        }
        .frame(width: geometry.size.width, height: geometry.size.height) // Ensure centering VStack fills geometry
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
        gameOverViewModel.gameMessage = "Final Score: 150"

        return Group {
            GameOverlayView(viewModel: previewViewModel, onRestartGame: {})
                .frame(width: 800, height: 600).previewDisplayName("Gameplay 800x600")
                .preferredColorScheme(.dark)
            
            GameOverlayView(viewModel: gameOverViewModel, onRestartGame: {})
                 .frame(width: 800, height: 600).previewDisplayName("Game Over 800x600")
                .preferredColorScheme(.dark)

            GameOverlayView(viewModel: previewViewModel, onRestartGame: {})
                .frame(width: 400, height: 300).previewDisplayName("Gameplay 400x300 (Small)")
                .preferredColorScheme(.dark)

            GameOverlayView(viewModel: gameOverViewModel, onRestartGame: {})
                 .frame(width: 400, height: 300).previewDisplayName("Game Over 400x300 (Small)")
                .preferredColorScheme(.dark)
        }
    }
}
