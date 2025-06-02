// Boat3D/App/ContentView.swift
import SwiftUI

enum ActiveGameScreen: CaseIterable {
    case start
    case gameMode
    case playerLoading
    case inGame
}

struct ContentView: View {
    @StateObject var connectionManager = ConnectionManager()
    @State private var currentScreen: ActiveGameScreen = .start
    private let transitionAnimation: Animation = .easeInOut(duration: 0.4) // Define your preferred animation

    var body: some View {
        GeometryReader { geometry in
            SkyboxView(textureName: "Skybox", rotationDuration: 120)
                .edgesIgnoringSafeArea(.all)
            ZStack {
                // 2. Conditionally show SlidingUIPanel or GameSceneRepresentable
                if currentScreen == .inGame {
                    GameSceneRepresentable(connectionManager: connectionManager)
                        .edgesIgnoringSafeArea(.all)
                        // Transition for GameSceneRepresentable appearing
                        .transition(.opacity.animation(transitionAnimation))
                        .zIndex(2) // Higher zIndex if it needs to overlap during transition
                } else {
                    SlidingUIPanel(
                        currentScreen: $currentScreen,
                        connectionManager: connectionManager,
                        geometry: geometry,
                        transitionAnimation: transitionAnimation
                    )
                    // Transition for the entire panel when switching to/from .inGame
                    .transition(.opacity.animation(transitionAnimation)) // Example: fade out/in panel
                    .zIndex(1) // Above Skybox, potentially below GameScene during transitions
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Add a hidden button to capture the Escape key press for back navigation
        .background(
            Button("") {
                navigateBack()
            }
            .keyboardShortcut(.escape, modifiers: []) // Listen for Escape key without modifiers
            .frame(width: 0, height: 0) // Make the button invisible
            .opacity(0)
            .allowsHitTesting(false) // Ensure it doesn't interfere with other UI interactions
        )
    }

    public func navigateBack() {

        withAnimation(transitionAnimation) {
            switch currentScreen {
            case .inGame:
                currentScreen = .playerLoading
                // When returning from game to UI, restart the main menu BGM
                GameSoundManager.shared.playBGM(.mainMenu, fadeIn: true)
            case .playerLoading:
                currentScreen = .gameMode
                // BGM should already be .mainMenu, no change needed if it's playing
            case .gameMode:
                currentScreen = .start
                // BGM should already be .mainMenu, no change needed if it's playing
            case .start:
                // Already at the first screen, do nothing.
                // Alternatively, you could implement app quit confirmation here if desired.
                print("Already at start screen. No back action.")
                break
            }
        }
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
