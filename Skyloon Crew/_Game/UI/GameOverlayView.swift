// SwiftUI_UI/GameOverlayView.swift
import SwiftUI

struct GameOverlayView: View {
    @ObservedObject var viewModel: InfoViewModel
    var onRestartGame: () -> Void // Callback to restart the game

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            if viewModel.isGameOver {
                gameOverContent
            } else {
                gamePlayContent
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Align content to top
        .background(Color.black.opacity(0.01)) // Almost transparent, for gesture receiving if needed
    }

    @ViewBuilder
    private var gamePlayContent: some View {
        
        ZStack {
            VStack{
                HStack {
                    HealthDisplayView(currentHealth: viewModel.health)
                        .padding(.trailing)
                    Spacer()
                }
                .padding(.vertical, 5)
                
                // Question Text
                Text(viewModel.currentQuestionText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                
                Spacer()
                
                HStack {
                    Text("Score: \(viewModel.score)")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Timer
                    Text("Time: \(viewModel.timeLeft)")
                        .font(.title3)
                        .foregroundColor(viewModel.timeLeft <= 10 ? .red : .yellow) // Highlight when time is low
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                }
                .padding(.vertical, 5)
            }
            // Game Message (Correct/Wrong/Time's Up)
            if !viewModel.gameMessage.isEmpty {
                Text(viewModel.gameMessage)
                    .font(.headline)
                    .foregroundColor(viewModel.gameMessage.contains("Correct") ? .green : (viewModel.gameMessage.contains("Wrong") || viewModel.gameMessage.contains("Time's Up") ? .orange : .white )) // Color logic
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .scale))
            }
        }

    }

    @ViewBuilder
    private var gameOverContent: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Text("Game Over!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(viewModel.gameMessage) // Shows final score
                    .font(.title2)
                    .foregroundColor(.white)
                
                Button(action: {
                    onRestartGame()
                }) {
                    // The whole background is tappable
                    Rectangle()
                        .overlay(
                            Text("Restart Game")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                        )
                        .frame(width: 200, height: 50)
                        .cornerRadius(10)
                        .foregroundColor(.blue)
                    
                }
                .buttonStyle(PlainButtonStyle()) // Prevents default button padding/border
                .edgesIgnoringSafeArea(.all)
                
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(15)
            .frame(maxWidth: 400)
            
            Spacer()
        } // Limit width of game over panel
        
    }
}

// Preview
struct GameOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        // REMOVED: let SCNView = SCNView()

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
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
            
            GameOverlayView(viewModel: gameOverViewModel, onRestartGame: {})
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}
