//
//  BearModelView.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 03/06/25.
//

import SceneKit
import SwiftUI

struct BearModelView: View {
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
