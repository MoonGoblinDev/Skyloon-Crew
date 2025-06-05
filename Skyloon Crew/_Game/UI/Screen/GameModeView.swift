import SwiftUI

// MARK: - Data Models
struct GameMode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let previewImageName: String
    let description: String
    let questionFileName: String // Stores the base name of the JSON file or a special identifier like "mix_all_categories"
}


// MARK: - Main View
struct GameModeView: View {
    @State private var selectedGameMode: GameMode?
    var navigateToPlayerLoading: (String) -> Void

    // Game modes with corrected questionFileNames (no .json extension)
    // And a special identifier for "Mix"
    let gameModes: [GameMode] = [
        GameMode(name: "Mix", previewImageName: "Skybox", description: "An exciting game mode where the topic of the pathway will be random", questionFileName: "mix_all_categories"), // Special identifier
        GameMode(name: "Trivia", previewImageName: "Skybox", description: "Test your general knowledge with questions spanning various topics and categories.", questionFileName: "trivia_questions"),
        GameMode(name: "Positive Thinking", previewImageName: "Skybox", description: "Explore mindfulness and mental wellness through psychology-based questions and exercises.", questionFileName: "positive_thinking_questions"),
        GameMode(name: "Mathematics", previewImageName: "Skybox", description: "Challenge your numerical skills with math problems ranging from basic to advanced levels.", questionFileName: "mathematics_questions"),
        GameMode(name: "Movies", previewImageName: "Skybox", description: "Dive into the world of cinema with questions about films, actors, directors, and movie trivia.", questionFileName: "movies_questions"),
        GameMode(name: "Gen Z", previewImageName: "Skybox", description: "Navigate pop culture, social media trends, and contemporary topics relevant to Generation Z.", questionFileName: "gen_z_questions"),
    ]

    init(navigateToPlayerLoading: @escaping (String) -> Void) {
        self.navigateToPlayerLoading = navigateToPlayerLoading
        _selectedGameMode = State(initialValue: gameModes.first)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack() {
                HStack {
                    LeftSidebarView(gameModes: gameModes, selectedGameMode: $selectedGameMode)
                        .frame(minWidth: 200, idealWidth: 250, maxWidth: max(350, geometry.size.width * 0.25))
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

// ... (Rest of LeftSidebarView, GameModeButton, MapContentView remain the same as previously corrected) ...


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
    var navigateToPlayerLoading: (String) -> Void // Updated

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
                                Image(gameMode.previewImageName) // Use previewImageName from GameMode
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
                                Text(gameMode.description) // Use description from GameMode
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
                        
                    } else {
                        Text("Select a game mode from the left.")
                            .font(.headline) // Adaptive
                            .foregroundColor(GameColorScheme().primaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if let mode = selectedGameMode {
                            navigateToPlayerLoading(mode.questionFileName) // Pass the base question file name or "mix_all_categories"
                            GameSoundManager.shared.playUI(.success)
                        } else {
                            // Fallback or disable button - for now, defaults to "mix_all_categories" if somehow no mode selected
                            navigateToPlayerLoading("mix_all_categories")
                            GameSoundManager.shared.playUI(.error) // Indicate something might be off
                        }
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
                    .disabled(selectedGameMode == nil) // Disable button if no game mode is selected
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
        GameModeView(navigateToPlayerLoading: { questionFile in
            print("Navigate to Player Loading from preview with question file: \(questionFile)")
        })
            .frame(width: 1000, height: 700)
    }
}
