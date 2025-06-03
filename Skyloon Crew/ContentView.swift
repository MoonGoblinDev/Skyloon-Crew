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
            SkyboxView(textureName: "Skybox", rotationDuration: 120) // Default skybox for UI
                .edgesIgnoringSafeArea(.all)
            ZStack {
                // Conditionally show SlidingUIPanel or GameSceneRepresentable
                if currentScreen == .inGame {
                    GameSceneRepresentable(
                        connectionManager: connectionManager,
                        onChangeGameModeAction: handleChangeGameMode,
                        onBackToTitleAction: handleBackToTitle,
                        onShowLeaderboardAction: handleShowLeaderboard
                    )
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
        .onAppear { // Handle initial BGM based on currentScreen
            updateBGMForCurrentScreen(screen: currentScreen, isInitialAppear: true)
        }
        .onChange(of: currentScreen) { newScreen in // Handle BGM changes on screen transitions
            updateBGMForCurrentScreen(screen: newScreen)
        }
    }

    // Function to update BGM based on the current screen
    private func updateBGMForCurrentScreen(screen: ActiveGameScreen, isInitialAppear: Bool = false) {
        switch screen {
        case .start, .gameMode, .playerLoading:
            // Play main menu BGM only if it's not already playing or if it's the initial app launch for these screens
            if GameSoundManager.shared.currentBGM != .mainMenu || isInitialAppear {
                GameSoundManager.shared.playBGM(.mainMenu, fadeIn: true)
            }
        case .inGame:
            // Play gameplay BGM only if it's not already playing or if it's the initial app launch for this screen
             if GameSoundManager.shared.currentBGM != .gameplay || isInitialAppear {
                GameSoundManager.shared.playBGM(.gameplay, fadeIn: true)
            }
        // Add cases for other screens like .leaderboard if they have specific BGM
        // case .leaderboard:
        //    GameSoundManager.shared.playBGM(.someOtherMusic, fadeIn: true)
        }
    }


    // Standard back navigation (e.g., via Escape key)
    public func navigateBack() {
        withAnimation(transitionAnimation) {
            switch currentScreen {
            case .inGame:
                currentScreen = .playerLoading
                // BGM change will be handled by onChange(of: currentScreen)
            case .playerLoading:
                // If coming from .inGame, connectionManager.stopHosting() might be relevant here
                // depending on game flow (e.g. if player loading also means exiting a hosted game session)
                // For now, assume it's just UI navigation back.
                currentScreen = .gameMode
            case .gameMode:
                currentScreen = .start
            case .start:
                print("Already at start screen. No back action.")
                // macOS apps usually don't quit on Escape from the main screen.
                // You could implement a quit confirmation dialog here if desired.
                break
            // Add cases for other screens like .leaderboard if they can be navigated back from
            // case .leaderboard:
            //    currentScreen = .gameMode // or wherever leaderboard is accessed from
            }
        }
    }

    // MARK: - Actions from GameOverView (via GameViewController)

    func handleChangeGameMode() {
        print("ContentView: Handling Change Game Mode")
        withAnimation(transitionAnimation) {
            currentScreen = .gameMode
            // BGM change will be handled by onChange(of: currentScreen)
        }
    }

    func handleBackToTitle() {
        print("ContentView: Handling Back to Title Screen")
        withAnimation(transitionAnimation) {
            currentScreen = .start
            // BGM change will be handled by onChange(of: currentScreen)
        }
    }

    func handleShowLeaderboard() {
        print("ContentView: Handling Show Leaderboard (Placeholder)")
        // Implement navigation to a leaderboard screen if it exists
        // Example:
        // withAnimation(transitionAnimation) {
        //     currentScreen = .leaderboard // Assuming .leaderboard is an ActiveGameScreen case
        // }
        // For now, this action does nothing visual beyond printing.
    }
}


// In the same file as ContentView or where GameSceneRepresentable is defined
struct GameSceneRepresentable: NSViewControllerRepresentable {
    typealias NSViewControllerType = GameViewController

    let connectionManager: ConnectionManager
    // Action closures to pass to GameViewController
    let onChangeGameModeAction: () -> Void
    let onBackToTitleAction: () -> Void
    let onShowLeaderboardAction: () -> Void


    func makeNSViewController(context: Context) -> GameViewController {
        // Pass the connectionManager to your GameViewController's initializer
        let gameVC = GameViewController(connectionManager: self.connectionManager)
        // Assign the action closures to the GameViewController instance
        gameVC.onChangeGameModeAction = self.onChangeGameModeAction
        gameVC.onBackToTitleAction = self.onBackToTitleAction
        gameVC.onShowLeaderboardAction = self.onShowLeaderboardAction
        return gameVC
    }

    func updateNSViewController(_ nsViewController: GameViewController, context: Context) {
        // If the action closures could change during the lifetime of GameSceneRepresentable
        // (which is unlikely for simple closures passed at init), re-assign them here.
        // For this setup, makeNSViewController is generally sufficient.
         nsViewController.onChangeGameModeAction = self.onChangeGameModeAction
         nsViewController.onBackToTitleAction = self.onBackToTitleAction
         nsViewController.onShowLeaderboardAction = self.onShowLeaderboardAction
    }
}
