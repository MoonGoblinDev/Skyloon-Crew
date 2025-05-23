import SwiftUI

struct StartScreenView: View {
    @State private var isAnimating: Bool = false
    @State private var textOffsetY: CGFloat = 0
    
    var navigateToGameMode: () -> Void // Callback for navigation

    var body: some View {
        ZStack{
            SkyboxView(textureName: "Skybox", rotationDuration: 120) // Texture name from Assets
                            .edgesIgnoringSafeArea(.all)
                
            VStack{
                Image("Logo1") // Ensure "Logo1" is in your Assets.xcassets
                    .resizable()
                    .scaledToFit() // Use scaledToFit to maintain aspect ratio
                    .frame(width: 300, height: 300)
                Spacer()
                Text("Tap anywhere to start")
                    .font(.system(size: 13, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .padding(10)
                    .cornerRadius(8)
                    .offset(y: textOffsetY)
                    .animation(
                        Animation.easeInOut(duration: 0.7)
                            .repeatForever(autoreverses: true),
                        value: textOffsetY
                    )
                Spacer().frame(height: 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle()) // Make the entire ZStack tappable
        .onTapGesture {
            navigateToGameMode() // Trigger navigation
        }
        .onAppear {
            textOffsetY = -5
        }
    }
}

// Preview needs to be updated to provide the callback
struct StartScreenView_Previews: PreviewProvider { // Renamed from #Preview
    static var previews: some View {
        StartScreenView(navigateToGameMode: { print("Navigate to Game Mode from preview") })
    }
}
