//
//  SlidingUIPanel.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 01/06/25.
//

import SwiftUI

// In ContentView.swift or a new file

struct SlidingUIPanel: View {
    @Binding var currentScreen: ActiveGameScreen
    @Binding var selectedQuestionFile: String // New binding to pass selection up to ContentView
    @ObservedObject var connectionManager: ConnectionManager
    let geometry: GeometryProxy // To get screen width
    let transitionAnimation: Animation

    // Defines the order of screens that can be swiped through
    private var slideableScreens: [ActiveGameScreen] {
        // .inGame is handled separately, not part of this sliding panel
        [.start, .gameMode, .playerLoading]
    }

    private func screenIndex(for screen: ActiveGameScreen) -> Int? {
        slideableScreens.firstIndex(of: screen)
    }

    private func calculateOffsetX() -> CGFloat {
        guard let currentIndex = screenIndex(for: currentScreen) else {
            // Should not happen if this panel is only shown for slideable screens
            return 0
        }
        // To show screen at index `i`, the HStack needs to be offset by `-i * screenWidth`
        return -CGFloat(currentIndex) * geometry.size.width
    }

    var body: some View {
        HStack(spacing: 0) {
            // StartScreenView
            StartScreenView(navigateToGameMode: {
                withAnimation(transitionAnimation) {
                    currentScreen = .gameMode
                }
            })
            .frame(width: geometry.size.width, height: geometry.size.height)
            .id(ActiveGameScreen.start) // Useful for identifying views if needed


            GameModeView(navigateToPlayerLoading: { questionFileForMode in // Closure now accepts question file name
                self.selectedQuestionFile = questionFileForMode // Update the binding
                withAnimation(transitionAnimation) {
                    currentScreen = .playerLoading
                }
            })
            .frame(width: geometry.size.width, height: geometry.size.height)
            .id(ActiveGameScreen.gameMode)

            // WaitingForPlayerView (MUST have its internal SkyboxView removed)
            WaitingForPlayerView(connectionManager: connectionManager, navigateToGame: {
                withAnimation(transitionAnimation) {
                    currentScreen = .inGame // This will trigger ContentView to switch views
                }
            })
            .frame(width: geometry.size.width, height: geometry.size.height)
            .id(ActiveGameScreen.playerLoading)
        }
        // Total width of the HStack is (number of slideable screens * screen width)
        .frame(width: geometry.size.width * CGFloat(slideableScreens.count), height: geometry.size.height)
        .offset(x: calculateOffsetX())
        .clipped() // Very important: clips the content that's off-screen
    }
}
