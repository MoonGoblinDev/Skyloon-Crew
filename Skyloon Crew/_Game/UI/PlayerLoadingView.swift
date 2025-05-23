import SwiftUI
import SceneKit

struct BearModelView: View {
    // ... (BearModelView remains unchanged as its scaling is handled by its parent frame) ...
    let playerColor: Color
    private var scene: SCNScene?

    init(playerColor: Color) {
        self.playerColor = playerColor
        if let modelScene = SCNScene(named: "art.scnassets/Bear 2.scn") {
            self.scene = Self.processScene(modelScene, with: playerColor, animationFileName: "idle.dae", modelPath: "art.scnassets/Bear/Idle.dae")
        } else {
            print("Error: Could not load 'Bear/Bear.dae'.")
            self.scene = nil
        }
    }

    private static func processScene(_ modelScene: SCNScene, with swiftUIColor: Color, animationFileName: String, modelPath: String) -> SCNScene? {
        var nodeToModify: SCNNode? = nil
        func findMainNode(_ node: SCNNode) -> SCNNode? {
            if (node.name ?? "").lowercased().contains("armature") { return node }
            if node.geometry != nil { return node }
            for child in node.childNodes { if let found = findMainNode(child) { return found } }
            return nil
        }
        nodeToModify = findMainNode(modelScene.rootNode) ?? modelScene.rootNode.childNodes.first ?? modelScene.rootNode
        guard let finalNodeToModify = nodeToModify else { return modelScene }
        #if os(macOS)
        let scnColor = NSColor(swiftUIColor)
        #else
        let scnColor = UIColor(swiftUIColor)
        #endif
        finalNodeToModify.enumerateHierarchy { (node, _) in
            if let geometry = node.geometry {
                geometry.materials.forEach { material in
                    material.diffuse.contents = scnColor
                    material.lightingModel = .phong
                    material.shininess = 2.0
                }
            }
        }
        return modelScene
    }

    var body: some View {
        if let validScene = scene {
            SceneView(scene: validScene, options: [.rendersContinuously])
            .background(Color.clear)
        } else {
            Text("Error loading 3D model").foregroundColor(.red)
            .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.gray.opacity(0.2))
        }
    }
}


struct WaitingForPlayerView: View {
    @ObservedObject var connectionManager: ConnectionManager
    var navigateToGame: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let titleFontSize = max(24, min(geometry.size.width * 0.055, geometry.size.height * 0.08))
            let topSpacerHeight = geometry.size.height * 0.04
            
            let numPlayers = CGFloat(max(1, connectionManager.players.count))
            let idealColumnSpacing = geometry.size.width * 0.04
            // Calculate width for columns, ensuring they don't get too cramped
            let totalHorizontalPadding = idealColumnSpacing * 2 // Padding on left/right of the HStack
            let totalInterColumnSpacing = idealColumnSpacing * (numPlayers - 1)
            let availableWidthForColumns = geometry.size.width - totalHorizontalPadding - totalInterColumnSpacing
            let columnWidth = max(geometry.size.width * 0.15, availableWidthForColumns / numPlayers) // Each column at least 15% of total width
            let columnHeight = geometry.size.height * 0.55 // Columns take up a good portion of height

            let startButtonFontSize = max(18, min(geometry.size.width * 0.03, geometry.size.height * 0.04))
            let startButtonHPad = startButtonFontSize * 1.2
            let startButtonVPad = startButtonFontSize * 0.6
            let startButtonCornerRadius = startButtonFontSize * 0.5
            let bottomPaddingForButton = geometry.size.height * 0.05

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Waiting for Player")
                        .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .foregroundColor(.white)
                        .padding(titleFontSize * 0.2) // Padding relative to font
                    Spacer()
                }
                .background(GameColorScheme().secondaryBackground)
                .frame(maxWidth: .infinity)
                
                Spacer().frame(height: topSpacerHeight)

                HStack(alignment: .bottom, spacing: idealColumnSpacing) {
                    ForEach(connectionManager.players) { player in
                        PlayerColumnView(player: player)
                            .frame(width: columnWidth, height: columnHeight)
                    }
                }
                .padding(.horizontal, idealColumnSpacing) // Ensure side padding for the HStack
                .padding(.bottom, geometry.size.height * 0.03)
                
                Spacer() // Pushes button towards bottom

                Button(action: { navigateToGame() }) {
                    HStack {
                        Text("Start Adventure")
                            .font(.system(size: startButtonFontSize, weight: .medium, design: .rounded))
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, startButtonHPad)
                    .padding(.vertical, startButtonVPad)
                    .foregroundColor(GameColorScheme().primaryText)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(startButtonCornerRadius)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, bottomPaddingForButton)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(GameColorScheme().primaryBackground)
            .onAppear {
                connectionManager.startHosting()
            }
        }
        // The .frame(minWidth, idealWidth...) for WaitingForPlayerView itself is set by its parent (ContentView),
        // which is good for window sizing. The internal GeometryReader handles content within that.
    }
}
    

struct WaitingForPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = ConnectionManager()
        // Add sample players for preview if needed
        // manager.players = Player.samplePlayers()
        WaitingForPlayerView(connectionManager: manager, navigateToGame: { })
            .frame(width: 900, height: 700).previewDisplayName("900x700")
        WaitingForPlayerView(connectionManager: manager, navigateToGame: { })
            .frame(width: 1200, height: 800).previewDisplayName("1200x800")
        WaitingForPlayerView(connectionManager: manager, navigateToGame: { })
            .frame(width: 600, height: 900).previewDisplayName("600x900 (Tall)")
    }
}
