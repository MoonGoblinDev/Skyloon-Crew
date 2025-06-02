import SwiftUI

// MARK: - Data Models
struct GameMode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var selected: Bool = false
    let previewImageName: String
    let description: String
}


// MARK: - Main View
struct GameModeView: View {
    @State private var selectedGameMode: GameMode?
    var navigateToPlayerLoading: () -> Void

    let gameModes: [GameMode] = [
        GameMode(name: "Mix", selected: true, previewImageName: "Skybox", description: "An exciting game mode where the topic of the pathway will be random"),
        GameMode(name: "Trivia", previewImageName: "partner_party_preview", description: "An exciting game mode where the topic of the pathway will be a Trivia Question."),
        GameMode(name: "Physcology", previewImageName: "river_survival_preview", description: "An exciting game mode where the topic of the pathway will be a Physcology Question."),
        GameMode(name: "Mathematics", previewImageName: "sound_stage_preview", description: "Groove to the rhythm in these musical minigames."),
        GameMode(name: "Science", previewImageName: "minigames_preview", description: "Play all your favorite minigames freely."),
        GameMode(name: "Biology", previewImageName: "online_mariothon_preview", description: "Compete in a series of minigames online."),
    ]

    init(navigateToPlayerLoading: @escaping () -> Void) {
        self.navigateToPlayerLoading = navigateToPlayerLoading
        _selectedGameMode = State(initialValue: gameModes.first)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack() {
                HStack {
                    LeftSidebarView(gameModes: gameModes, selectedGameMode: $selectedGameMode)
                        .frame(minWidth: 200, idealWidth: 250, maxWidth: max(350, geometry.size.width * 0.25)) // Sidebar can take up to 25%
                        .padding()

                    MapContentView(selectedGameMode: $selectedGameMode, navigateToPlayerLoading: navigateToPlayerLoading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                }
                .frame(maxHeight: .infinity)

            }
        }
    }
}

struct LeftSidebarView: View {
    let gameModes: [GameMode]
    @Binding var selectedGameMode: GameMode?

    var body: some View {
        GameCanvas(title: "Game Modes") {
            VStack(alignment: .leading, spacing: 8) {
                Spacer().frame(height: 16)
                ForEach(gameModes) { mode in
                    GameModeButton(
                        mode: mode,
                        isSelected: selectedGameMode?.id == mode.id,
                        action: {
                            selectedGameMode = mode
                            GameSoundManager.shared.playUI(.buttonClick)
                        }
                    )
                }
                Spacer()
            }
        }
        
    }
}

struct GameModeButton: View {
    let mode: GameMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        GameButton(
            state: isSelected ? .green : .grey,
            disabled: false,
            action: action
        ) {
            HStack() {
                if isSelected {
                    Image(systemName: "play.fill")
                        .foregroundColor(GameColorScheme().selectedMenuText)
                        .transition(.opacity)
                }

                Text.gameFont(mode.name, fontSize: 20 )
                    .minimumScaleFactor(0.8)

                Spacer()

            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
    }
}



// MARK: - Map Content View (Right Pane)
struct MapContentView: View {
    @Binding var selectedGameMode: GameMode?
    var navigateToPlayerLoading: () -> Void

    var body: some View {
        GeometryReader { geometry in 
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

            GameCanvas() {
                
                VStack {
                    Spacer()
                    if let gameMode = selectedGameMode {
                        VStack(spacing: max(15, geometry.size.height * 0.03)) {
                            ZStack {
                                Image(gameMode.previewImageName)
                                    .resizable()
                                    .frame(maxWidth: imageMaxWidth, maxHeight: imageMaxHeight)
                                    
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
                                    
                            )
                            .padding(.horizontal, geometry.size.width * 0.02)
                            
                            HStack {
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
                            .frame(maxWidth: geometry.size.width * 0.9)
                        }
                        .animation(.easeInOut, value: gameMode.id)
                        
                    } else {
                        Text("Select a game mode from the left.")
                            .font(.headline) // Adaptive
                            .foregroundColor(GameColorScheme().primaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        navigateToPlayerLoading()
                        GameSoundManager.shared.playUI(.success)
                    }) {
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
                
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}


// MARK: - Preview
struct GameModeView_Previews: PreviewProvider {
    static var previews: some View {
        GameModeView(navigateToPlayerLoading: { print("Navigate to Player Loading from preview") })
            .frame(width: 1000, height: 700)
    }
}
