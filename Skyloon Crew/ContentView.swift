// Boat3D/App/ContentView.swift
import SwiftUI

enum ActiveGameScreen {
    case start
    case gameMode
    case playerLoading
    case inGame
}

struct ContentView: View {
    @StateObject var connectionManager = ConnectionManager() // Already here
    @State private var currentScreen: ActiveGameScreen = .start

    var body: some View {
        Group {
            switch currentScreen {
            case .start:
                StartScreenView(navigateToGameMode: {
                    currentScreen = .gameMode
                })
            case .gameMode:
                GameModeView(navigateToPlayerLoading: {
                    currentScreen = .playerLoading
                })
            case .playerLoading:
                WaitingForPlayerView(connectionManager: connectionManager, navigateToGame: {
                    currentScreen = .inGame
                }
                )
            case .inGame:
                // Pass the connectionManager instance here
                GameSceneRepresentable(connectionManager: connectionManager)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// In the same file as ContentView or where GameSceneRepresentable is defined

struct GameSceneRepresentable: NSViewControllerRepresentable {
    typealias NSViewControllerType = GameViewController

    let connectionManager: ConnectionManager


    func makeNSViewController(context: Context) -> GameViewController {
        // Pass the connectionManager to your GameViewController's initializer
        let gameVC = GameViewController(connectionManager: self.connectionManager)
        return gameVC
    }

    func updateNSViewController(_ nsViewController: GameViewController, context: Context) {
        
    }
}
