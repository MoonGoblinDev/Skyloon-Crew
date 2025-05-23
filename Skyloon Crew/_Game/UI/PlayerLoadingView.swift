import SwiftUI
import SceneKit // Import SceneKit for 3D models

// 2. Bear 3D Model View
struct BearModelView: View {
    let playerColor: Color
    private var scene: SCNScene?

    init(playerColor: Color) {
        self.playerColor = playerColor
        // Try to load and process the scene.
        // The path "Bear/Bear.dae" assumes "Bear.dae" is inside a "Bear" folder,
        // which itself is inside the "art.scnassets" catalog.
        // Similarly, "Bear/idle.dae" for the animation.
        if let modelScene = SCNScene(named: "art.scnassets/Bear 2.scn") {
            //print("Successfully loaded 'Bear/Bear.dae'.")
            self.scene = Self.processScene(modelScene, with: playerColor, animationFileName: "idle.dae", modelPath: "art.scnassets/Bear/Idle.dae")
        } else {
            print("Error: Could not load 'Bear/Bear.dae'. Ensure 'art.scnassets' is an asset catalog and the path 'Bear/Bear.dae' is correct within it (including case-sensitivity).")
            self.scene = nil
        }
    }

    // Helper function to process the loaded scene (apply color, animation, etc.)
    private static func processScene(_ modelScene: SCNScene, with swiftUIColor: Color, animationFileName: String, modelPath: String) -> SCNScene? {
        // 2. Find the main node to color and animate.
        var nodeToModify: SCNNode? = nil
        
        func findMainNode(_ node: SCNNode) -> SCNNode? {
            if (node.name ?? "").lowercased().contains("armature") {
                return node
            }
            if node.geometry != nil {
                return node
            }
            for child in node.childNodes {
                if let found = findMainNode(child) {
                    return found
                }
            }
            return nil
        }

        nodeToModify = findMainNode(modelScene.rootNode) ?? modelScene.rootNode.childNodes.first ?? modelScene.rootNode
        
        guard let finalNodeToModify = nodeToModify else {
            print("Error: Could not find a suitable node in '\(modelPath)'.")
            return modelScene // Return scene as is, maybe something shows up
        }

        // 3. Apply color to the model's materials
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
            SceneView(
                scene: validScene,
                options: [
                    // .allowsCameraControl, // Enable for debugging
                    .rendersContinuously // Important for animations
                    // .autoenablesDefaultLighting is false by default if lights are added manually
                ]
            )
            .background(Color.clear)
        } else {
            Text("Error loading 3D model")
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.2))
        }
    }
}




struct WaitingForPlayerView: View {
    @ObservedObject var connectionManager: ConnectionManager
    var navigateToGame: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            HStack{
                Spacer()
                Text("Waiting for Player")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
            .background(GameColorScheme().secondaryBackground)
            .frame(maxWidth: .infinity, alignment: .top)
            
            Spacer().frame(height: 30)

            HStack(alignment: .bottom, spacing: 50) {
                ForEach(connectionManager.players) { player in
                    PlayerColumnView(player: player)
                }
            }
            .padding(.bottom, 20)
            
            Button(action: {
                navigateToGame()
            }) {
                HStack {
                    Text("Start Adventure")
                        .font( .system(size: 25, weight: .medium, design: .rounded))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(GameColorScheme().primaryText)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(15)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .frame(minWidth: 800, idealWidth: 900, maxWidth: .infinity,
               minHeight: 600, idealHeight: 700, maxHeight: .infinity)
        .background(GameColorScheme().primaryBackground)
        .onAppear {
            connectionManager.startHosting()
        }
    }
}
    

struct WaitingForPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingForPlayerView(connectionManager: .init(), navigateToGame: { })
    }
}
