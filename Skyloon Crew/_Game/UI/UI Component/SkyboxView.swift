import SwiftUI
import SceneKit

struct SkyboxView: NSViewRepresentable {
    var textureName: String
    var rotationDuration: TimeInterval

    // 1. Make Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // 2. Coordinator Class
    class Coordinator: NSObject {
        var parent: SkyboxView
        var lastConfiguredTextureName: String?
        var lastConfiguredRotationDuration: TimeInterval?
        weak var skyboxNode: SCNNode? // Keep a weak reference to the node for updates

        init(_ parent: SkyboxView) {
            self.parent = parent
        }

        func setupSkybox(on node: SCNNode, textureName: String, duration: TimeInterval) {
            // Apply texture
            if let skyTexture = NSImage(named: textureName) {
                node.geometry?.firstMaterial?.diffuse.contents = skyTexture
            } else {
                print("Error: Skybox texture '\(textureName)' not found in setupSkybox.")
                node.geometry?.firstMaterial?.diffuse.contents = NSColor.red // Fallback
            }
            self.lastConfiguredTextureName = textureName

            // Apply/Update rotation
            node.removeAllActions() // Remove existing rotation if any
            let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: duration)
            let infiniteRotation = SCNAction.repeatForever(rotation)
            node.runAction(infiniteRotation)
            self.lastConfiguredRotationDuration = duration
        }
    }

    // 3. makeNSView
    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = SCNScene()
        scnView.scene = scene
        scnView.backgroundColor = .clear
        scnView.isPlaying = true
        // scnView.allowsCameraControl = true // For debugging

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 40, z: 0)
        scene.rootNode.addChildNode(cameraNode)

        let skyboxSphere = SCNSphere(radius: 100)
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.lightingModel = .constant
        skyboxSphere.materials = [material]

        let skyboxNode = SCNNode(geometry: skyboxSphere)
        scene.rootNode.addChildNode(skyboxNode)
        
        // Store reference to the node in the coordinator
        context.coordinator.skyboxNode = skyboxNode

        // Initial setup using coordinator
        context.coordinator.setupSkybox(on: skyboxNode, textureName: textureName, duration: rotationDuration)

        return scnView
    }

    // 4. updateNSView
    func updateNSView(_ nsView: SCNView, context: Context) {
        // Retrieve the skyboxNode from the coordinator
        guard let skyboxNode = context.coordinator.skyboxNode else {
            print("Warning: Skybox node not found in coordinator during update.")
            return
        }


        // Check if textureName changed
        if context.coordinator.lastConfiguredTextureName != textureName {
            if let newTexture = NSImage(named: textureName) {
                skyboxNode.geometry?.firstMaterial?.diffuse.contents = newTexture
                context.coordinator.lastConfiguredTextureName = textureName
                print("Skybox texture updated to: \(textureName)")
            } else {
                print("Error: New skybox texture '\(textureName)' not found in updateNSView. Keeping old texture.")
                // Optionally, you might want to revert parent.textureName to coordinator.lastConfiguredTextureName
                // or set a default error texture.
            }
        }

        // Check if rotationDuration changed
        if context.coordinator.lastConfiguredRotationDuration != rotationDuration {
            skyboxNode.removeAllActions() // Remove existing rotation
            let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: rotationDuration)
            let infiniteRotation = SCNAction.repeatForever(rotation)
            skyboxNode.runAction(infiniteRotation)
            context.coordinator.lastConfiguredRotationDuration = rotationDuration
            print("Skybox rotation duration updated to: \(rotationDuration)")
        }
        
    }
}
