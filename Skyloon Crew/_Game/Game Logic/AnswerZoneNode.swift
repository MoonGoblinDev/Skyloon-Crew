// GameLogic/AnswerZoneNode.swift
import SceneKit
import SwiftUI

class AnswerZoneNode: SCNNode {
    let answerText: String
    let isCorrect: Bool
    private var textNode: SCNNode!
    private var sphereNode: SCNNode!

    static let sphereRadius: CGFloat = 5.0
    // Let's make text parameters more prominent for easier tweaking
    static let textFontSize: CGFloat = 3.0      // Increased
    static let textExtrusionDepth: CGFloat = 0.5 // Increased
    static let textVerticalOffset: Float = 1.5  // Offset above sphere + text_half_height

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
        let physicsShape = SCNPhysicsShape(geometry: sphereGeometry, options: [SCNPhysicsShape.Option.keepAsCompound: false]) // keepAsCompound false is good for simple geometry
                
        sphereNode.physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
        sphereNode.physicsBody?.categoryBitMask = PhysicsCategory.answerZone
        sphereNode.physicsBody?.contactTestBitMask = PhysicsCategory.boat
        sphereNode.physicsBody?.collisionBitMask = PhysicsCategory.none // Make it a trigger

        self.addChildNode(sphereNode)

        // Create 3D Text
        let textGeometry = SCNText(string: answerText, extrusionDepth: AnswerZoneNode.textExtrusionDepth)
        textGeometry.font = NSFont.systemFont(ofSize: AnswerZoneNode.textFontSize, weight: .medium) // Slightly bolder
        textGeometry.firstMaterial?.diffuse.contents = NSColor.white
        textGeometry.firstMaterial?.lightingModel = .constant // Make text emissive / ignore scene lighting for visibility
        textGeometry.firstMaterial?.isDoubleSided = true // Ensure visible from back if billboard flips oddly

        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textGeometry.truncationMode = CATextLayerTruncationMode.middle.rawValue
        
        // Adjust container frame based on text size and potential length
        // A wider container frame can help with longer text strings.
        // The height should be sufficient for the font size.
        let approxTextWidth = CGFloat(answerText.count) * AnswerZoneNode.textFontSize * 0.6 // Rough estimate
        let containerWidth = max(approxTextWidth, 10.0) // Ensure a minimum width
        textGeometry.containerFrame = CGRect(x: -containerWidth / 2, y: -AnswerZoneNode.textFontSize / 2, width: containerWidth, height: AnswerZoneNode.textFontSize * 1.5)
        textGeometry.isWrapped = true // Allow wrapping if text is too long for the container

        textNode = SCNNode(geometry: textGeometry)
        
        // Position text above the sphere
        // SCNText's origin is typically at the baseline, horizontally centered.
        // Bounding box min.y is usually around 0 or slightly negative for descenders.
        // Bounding box max.y is the top of the text.
        let (minBounds, maxBounds) = textGeometry.boundingBox
        let textHeight = maxBounds.y - minBounds.y
        
        // Position the text node so its visual center is above the sphere
        textNode.position = SCNVector3(
            x: 0,
            y: 2,
            z: 0
        )
        textNode.name = "AnswerText"


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
