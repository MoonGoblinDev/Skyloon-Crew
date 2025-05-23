import SwiftUI

// MARK: - Data Models
struct GameMode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var hasNotification: Bool = false
    let previewImageName: String
    let description: String
}


// MARK: - Main View
struct GameModeView: View {
    @State private var selectedGameMode: GameMode?
    var navigateToPlayerLoading: () -> Void

    let gameModes: [GameMode] = [
        GameMode(name: "Mix", hasNotification: true, previewImageName: "mario_party_preview", description: "An exciting game mode where the topic of the pathway will be random"),
        GameMode(name: "Trivia", previewImageName: "partner_party_preview", description: "An exciting game mode where the topic of the pathway will be a Trivia Question."),
        GameMode(name: "Physcology", previewImageName: "river_survival_preview", description: "An exciting game mode where the topic of the pathway will be a Physcology Question."),
        GameMode(name: "TBA", previewImageName: "sound_stage_preview", description: "Groove to the rhythm in these musical minigames."),
        GameMode(name: "TBA", previewImageName: "minigames_preview", description: "Play all your favorite minigames freely."),
        GameMode(name: "TBA", previewImageName: "online_mariothon_preview", description: "Compete in a series of minigames online."),
        GameMode(name: "TBA", previewImageName: "entrance_preview", description: "Return to the main plaza entrance.")
    ]

    init(navigateToPlayerLoading: @escaping () -> Void) {
        self.navigateToPlayerLoading = navigateToPlayerLoading
        _selectedGameMode = State(initialValue: gameModes.first)
    }

    var body: some View {
        GeometryReader { geometry in // Add GeometryReader for overall view
            let bottomBarHeight = max(50, geometry.size.height * 0.08) // Scaled bottom bar height

            VStack(spacing: 0) {
                HSplitView {
                    LeftSidebarView(gameModes: gameModes, selectedGameMode: $selectedGameMode)
                        .frame(minWidth: 200, idealWidth: 250, maxWidth: max(250, geometry.size.width * 0.25)) // Sidebar can take up to 25%
                        .background(GameColorScheme().menuItemBackground)

                    MapContentView(selectedGameMode: $selectedGameMode, navigateToPlayerLoading: navigateToPlayerLoading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)

                BottomBarView()
                    .frame(height: bottomBarHeight) // Apply scaled height
            }
            .background(GameColorScheme().primaryBackground)
            .edgesIgnoringSafeArea(.top)
        }
    }
}

// MARK: - Left Sidebar (largely unchanged, using adaptive fonts implicitly)
struct LeftSidebarView: View {
    let gameModes: [GameMode]
    @Binding var selectedGameMode: GameMode?
    // private let colorScheme = GameColorScheme() // Already defined

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Game Modes")
                .font(.title2) // Adaptive
                .fontWeight(.semibold)
                .padding(.bottom, 10)
                .foregroundColor(GameColorScheme().primaryText)

            ForEach(gameModes) { mode in
                GameModeButton(
                    mode: mode,
                    isSelected: selectedGameMode?.id == mode.id,
                    action: { selectedGameMode = mode }
                )
            }
            Spacer()
        }
        .padding() // Default padding, scales somewhat with font. Can be made dynamic too.
        .background(GameColorScheme().primaryBackground)
    }
}

struct GameModeButton: View {
    let mode: GameMode
    let isSelected: Bool
    let action: () -> Void
    // private let colorScheme = GameColorScheme() // Already defined

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isSelected {
                    Image(systemName: "play.fill")
                        .foregroundColor(GameColorScheme().selectedMenuText)
                        .transition(.opacity)
                } else {
                    Image(systemName: "play.fill")
                        .foregroundColor(.clear)
                }

                Text(mode.name)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? GameColorScheme().selectedMenuText : GameColorScheme().menuText)
                    .minimumScaleFactor(0.8) // Allow text to shrink a bit

                Spacer()
                
                if mode.hasNotification { // Simplified logic for icon display
                     Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(isSelected ? GameColorScheme().accentRed : GameColorScheme().accentPink)
                        .font(.title3) // Adaptive
                }
            }
            // Consider scaling padding if necessary, e.g., based on geometry.size.width * 0.01
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(isSelected ? GameColorScheme().secondaryBackground : GameColorScheme().menuItemBackground)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Map Content View (Right Pane)
struct MapContentView: View {
    @Binding var selectedGameMode: GameMode?
    var navigateToPlayerLoading: () -> Void
    // private let colorScheme = GameColorScheme() // Already defined

    var body: some View {
        GeometryReader { geometry in // GeometryReader for internal scaling
            let imageMaxWidth = geometry.size.width * 0.85
            let imageMaxHeight = geometry.size.height * 0.50
            
            let descriptionFontSize = max(12, min(geometry.size.width * 0.022, geometry.size.height * 0.035))
            let descriptionPadding = descriptionFontSize * 0.7
            let descriptionCornerRadius = descriptionFontSize * 0.5

            let buttonFontSize = max(16, min(geometry.size.width * 0.03, geometry.size.height * 0.045))
            let buttonHPad = buttonFontSize * 1.4
            let buttonVPad = buttonFontSize * 0.7
            let buttonCornerRadius = buttonFontSize * 0.5
            let buttonBottomPadding = geometry.size.height * 0.05

            VStack {
                Spacer()

                if let gameMode = selectedGameMode {
                    VStack(spacing: max(15, geometry.size.height * 0.03)) {
                        ZStack {
                            Image(gameMode.previewImageName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: imageMaxWidth, maxHeight: imageMaxHeight)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12) // Can be scaled: imageMaxHeight * 0.05
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12) // Scale if image cornerRadius is scaled
                                        .stroke(GameColorScheme().mapBoardOutlineBlue!, lineWidth: max(2, imageMaxWidth * 0.005)) // Scaled line
                                )
                        }
                        .padding(.horizontal, geometry.size.width * 0.02)

                        HStack {
                            if gameMode.description.contains("Star") || gameMode.description.contains("star") {
                                Image(systemName: "star.fill")
                                    .foregroundColor(GameColorScheme().accentYellowStar)
                                    .font(.system(size: descriptionFontSize * 1.1)) // Relative to description font
                            }

                            Text(gameMode.description)
                                .font(.system(size: descriptionFontSize, weight: .medium))
                                .foregroundColor(GameColorScheme().primaryText)
                                .minimumScaleFactor(0.8)
                                .padding(descriptionPadding)
                                .background(
                                    RoundedRectangle(cornerRadius: descriptionCornerRadius)
                                        .fill(GameColorScheme().menuItemBackground!)
                                        .shadow(color: .gray.opacity(0.4), radius: 3, x: 0, y: 2)
                                )
                        }
                        .padding(.horizontal, geometry.size.width * 0.02)
                        .frame(maxWidth: geometry.size.width * 0.9) // Constrain description width
                    }
                    .animation(.easeInOut, value: gameMode.id)
                    
                } else {
                    Text("Select a game mode from the left.")
                        .font(.headline) // Adaptive
                        .foregroundColor(GameColorScheme().primaryText)
                }

                Spacer()

                Button(action: { navigateToPlayerLoading() }) {
                    Text("Start Adventure")
                        .font(.system(size: buttonFontSize, weight: .bold, design: .rounded))
                        .padding(.horizontal, buttonHPad)
                        .padding(.vertical, buttonVPad)
                        .foregroundColor(GameColorScheme().selectedMenuText)
                        .background(GameColorScheme().controllerButtonIcon)
                        .cornerRadius(buttonCornerRadius)
                        .shadow(color: GameColorScheme().primaryText!, radius: 5, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, buttonBottomPadding)
                
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(GameColorScheme().primaryBackground)
        }
    }
}

// MARK: - Placeholder Content for other tabs
struct AdviceContentView: View {
    private let colorScheme = GameColorScheme()
    var body: some View {
        VStack {
            Text("Advice Content")
                .font(.largeTitle)
                .foregroundColor(GameColorScheme().primaryText)
            Text("Tips and tricks for the game will appear here.")
                .font(.title3)
                .foregroundColor(GameColorScheme().menuText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GameColorScheme().primaryBackground.opacity(0.8)) // Slightly different background
    }
}

struct GemsContentView: View {
    private let colorScheme = GameColorScheme()
    var body: some View {
        VStack {
            Text("Gems Collection")
                .font(.largeTitle)
                .foregroundColor(GameColorScheme().primaryText)
            Text("View your collected gems and achievements.")
                .font(.title3)
                .foregroundColor(GameColorScheme().menuText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GameColorScheme().primaryBackground.opacity(0.8))
    }
}


// MARK: - Bottom Bar
struct BottomBarView: View {
    private let colorScheme = GameColorScheme()
    var body: some View {
        HStack {
            Spacer() // Pushes button to the right or center if you add more items
            Spacer() // Centers the button if only one item
        }
        .padding()
        .frame(height: 70) // Increased height for better touch/click area
        .background(GameColorScheme().secondaryBackground) // Darker background for contrast
    }
}


// MARK: - Preview
struct GameModeView_Previews: PreviewProvider {
    static var previews: some View {
        GameModeView(navigateToPlayerLoading: { print("Navigate to Player Loading from preview") })
            .frame(width: 1000, height: 700)
    }
}
