// Skyloon Crew/_Game/UI/StartScreenView.swift
import SwiftUI

struct StartScreenView: View {
    @State private var textOffsetYState: CGFloat = 0
    @State private var showMenu: Bool
    @State private var logoOffset: CGFloat = 0
    
    var navigateToGameMode: () -> Void
    
    init(navigateToGameMode: @escaping () -> Void, showMenuInitially: Bool = false) {
        self.navigateToGameMode = navigateToGameMode
        self._showMenu = State(initialValue: showMenuInitially)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let logoSize = min(geometry.size.width, geometry.size.height) * 0.7
            let fontSize = max(12, min(geometry.size.width * 0.018, geometry.size.height * 0.03))
            let paddingSize = fontSize * 0.6
            let spacerHeight = geometry.size.height * 0.12
            let animationTargetOffset = -geometry.size.height * 0.008
            let logoUpwardOffset = -geometry.size.height * 0.08
            
            ZStack {
                VStack {
                    Image("Logo1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoSize, height: logoSize)
                        .offset(y: logoOffset)
                        .animation(.easeOut(duration: 0.3), value: logoOffset)
                    
                    Spacer()
                }
                VStack {
                    Spacer()
                    
                    
                    Spacer().frame(height: spacerHeight * 3)
                    
                    if !showMenu {
                        Text("Tap anywhere to start")
                            .font(.system(size: fontSize, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .padding(paddingSize)
                            .offset(y: textOffsetYState)
                            .animation(
                                Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                value: textOffsetYState
                            )
                    }
                    
                    if showMenu {
                        VStack(spacing: 30) {
                            MenuButton(title: "Start",
                                       color: "Button_Blue",
                                       fontSize: fontSize) {
                                GameSoundManager.shared.playUI(.buttonClick)
                                navigateToGameMode()
                            }
                            
                            MenuButton(title: "Settings",
                                       color: "Button_Orange",
                                       fontSize: fontSize) {
                                GameSoundManager.shared.playUI(.buttonClick)
                                // Handle settings navigation
                                print("Settings tapped")
                            }
                            
                            MenuButton(title: "Exit",
                                       color: "Button_Red",
                                       fontSize: fontSize) {
                                GameSoundManager.shared.playUI(.buttonClick)
                                // Handle exit
                                print("Exit tapped")
                            }
                        }
                        .opacity(showMenu ? 1 : 0)
                        .animation(.easeIn(duration: 0.4).delay(0.1), value: showMenu)
                    }
                    
                    Spacer().frame(height: spacerHeight)
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onTapGesture {
                if !showMenu {
                    GameSoundManager.shared.playUI(.menuOpen)
                    withAnimation {
                        showMenu = true
                        logoOffset = logoUpwardOffset
                    }
                }
            }
            .onAppear {
                self.textOffsetYState = animationTargetOffset
            }
            .onChange(of: geometry.size) { newSize in
                self.textOffsetYState = -newSize.height * 0.008
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            GameSoundManager.shared.playBGM(.mainMenu, fadeIn: true)
        }
    }
}

struct MenuButton: View {
    let title: String
    let color: String
    let fontSize: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action:
            action) {
            Text(title)
                .font(.system(size: fontSize * 1.2, weight: .bold, design: .default))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Image(color)
                        .resizable(
                            capInsets: EdgeInsets(top: 14, leading: 14, bottom: 18, trailing: 14),
                            resizingMode: .stretch
                        )
                        .frame(width: 400)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct StartScreenView_Previews: PreviewProvider {
    static var previews: some View {
        StartScreenView(navigateToGameMode: { print("Navigate to Game Mode from preview") }, showMenuInitially: true)
            .frame(width: 800, height: 600).previewDisplayName("800x600")
        StartScreenView(navigateToGameMode: { print("Navigate to Game Mode from preview") }, showMenuInitially: true)
            .frame(width: 1200, height: 900).previewDisplayName("1200x900")
        StartScreenView(navigateToGameMode: { print("Navigate to Game Mode from preview") }, showMenuInitially: true)
            .frame(width: 400, height: 700).previewDisplayName("400x700 (Tall)")
    }
}

struct StartScreenViewPreview: View {
    let showMenu: Bool
    let navigateToGameMode: () -> Void
    
    var body: some View {
        StartScreenView(navigateToGameMode: navigateToGameMode)
            .onAppear {
                // Force the menu to show in preview
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // This is a workaround for preview - in actual implementation
                    // you might want to add an initializer parameter to StartScreenView
                }
            }
    }
}
