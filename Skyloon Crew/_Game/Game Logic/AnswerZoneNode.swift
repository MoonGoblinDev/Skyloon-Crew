// GameLogic/AnswerZoneNode.swift
import SceneKit
import SwiftUI

class AnswerZoneNode: SCNNode {
    let answerText: String
    let isCorrect: Bool
    private var textNode: SCNNode!
    private var sphereNode: SCNNode!

    static let sphereRadius: CGFloat = 15.0
    static let textFontSize: CGFloat = 16.0
    static let textExtrusionDepth: CGFloat = 1.0
    static let textGapAboveSphere: Float = 3.0

    init(answerText: String, isCorrect: Bool, color: NSColor, position: SCNVector3) {
        self.answerText = answerText
        self.isCorrect = isCorrect
        super.init()

        self.position = position
        self.name = "AnswerZoneContainer"

        // Create the sphere
        let sphereGeometry = SCNSphere(radius: AnswerZoneNode.sphereRadius)
        sphereGeometry.firstMaterial?.diffuse.contents = color
        sphereGeometry.firstMaterial?.transparency = 0.7

        sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.name = "AnswerZoneSphere"

        // Setup physics for the sphere
        let physicsShape = SCNPhysicsShape(geometry: sphereGeometry, options: [SCNPhysicsShape.Option.keepAsCompound: false])
                
        sphereNode.physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
        sphereNode.physicsBody?.categoryBitMask = PhysicsCategory.answerZone
        sphereNode.physicsBody?.contactTestBitMask = PhysicsCategory.boat
        sphereNode.physicsBody?.collisionBitMask = PhysicsCategory.none // Make it a trigger

        self.addChildNode(sphereNode)

        // Create 3D Text
        let textGeometry = SCNText(string: answerText, extrusionDepth: AnswerZoneNode.textExtrusionDepth)
        textGeometry.font = NSFont.systemFont(ofSize: AnswerZoneNode.textFontSize, weight: .heavy) // Bolder for visibility
        textGeometry.firstMaterial?.diffuse.contents = NSColor.black
        textGeometry.firstMaterial?.lightingModel = .constant
        textGeometry.firstMaterial?.isDoubleSided = true

        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textGeometry.truncationMode = CATextLayerTruncationMode.middle.rawValue
        
        let approxTextWidth = CGFloat(answerText.count) * AnswerZoneNode.textFontSize * 0.7 // Rough estimate for container
        let containerWidth = max(approxTextWidth, CGFloat(AnswerZoneNode.sphereRadius)) // Ensure container can be at least sphere radius wide
        textGeometry.containerFrame = CGRect(x: -containerWidth / 2, y: -AnswerZoneNode.textFontSize * 0.75, width: containerWidth, height: AnswerZoneNode.textFontSize * 1.5)
        textGeometry.isWrapped = true

        textNode = SCNNode(geometry: textGeometry)
        textNode.name = "AnswerText"
        
        // Position text above the sphere
        let (minBounds, _) = textGeometry.boundingBox
        let textBaselineYPosition = Float(AnswerZoneNode.sphereRadius) + AnswerZoneNode.textGapAboveSphere - Float(minBounds.y)
        
        textNode.position = SCNVector3(
            x: 0,
            y: CGFloat(textBaselineYPosition),
            z: 0
        )

        // Make text always face the camera (Billboard constraint)
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = .Y // Only rotate around Y to stay upright
        textNode.constraints = [billboardConstraint]

        self.addChildNode(textNode)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
