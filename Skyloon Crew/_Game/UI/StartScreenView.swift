// Skyloon Crew/_Game/UI/StartScreenView.swift
import SwiftUI

struct StartScreenView: View {
    @State private var textOffsetYState: CGFloat = 0 // Holds the target for animation
    
    var navigateToGameMode: () -> Void // Callback for navigation

    var body: some View {
        GeometryReader { geometry in
            let logoSize = min(geometry.size.width, geometry.size.height) * 0.45 // Slightly larger logo
            let fontSize = max(12, min(geometry.size.width * 0.018, geometry.size.height * 0.03)) // Adjusted font scaling
            let paddingSize = fontSize * 0.6
            let cornerRadiusSize = fontSize * 0.4
            let spacerHeight = geometry.size.height * 0.12
            // Target for animation, calculated once unless geometry.size changes
            let animationTargetOffset = -geometry.size.height * 0.008

            ZStack {
                SkyboxView(textureName: "Skybox", rotationDuration: 120)
                    .edgesIgnoringSafeArea(.all)
                    
                VStack {
                    Spacer()
                    Image("Logo1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoSize, height: logoSize)
                    Text("Tap anywhere to start")
                        .font(.system(size: fontSize, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .padding(paddingSize)
                        .offset(y: textOffsetYState) // Animate using the state variable
                        .animation(
                            Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), // Slightly slower
                            value: textOffsetYState
                        )
                    Spacer().frame(height: spacerHeight)
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                navigateToGameMode()
            }
            .onAppear {
                self.textOffsetYState = animationTargetOffset
            }
            .onChange(of: geometry.size) { newSize in // Or specific dimension if only one matters
                 self.textOffsetYState = -newSize.height * 0.008 // Recalculate target on size change
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct StartScreenView_Previews: PreviewProvider {
    static var previews: some View {
        StartScreenView(navigateToGameMode: { print("Navigate to Game Mode from preview") })
            .frame(width: 800, height: 600).previewDisplayName("800x600")
        StartScreenView(navigateToGameMode: { print("Navigate to Game Mode from preview") })
            .frame(width: 1200, height: 900).previewDisplayName("1200x900")
        StartScreenView(navigateToGameMode: { print("Navigate to Game Mode from preview") })
            .frame(width: 400, height: 700).previewDisplayName("400x700 (Tall)")
    }
}
