import SceneKit
import SpriteKit
import GLKit // Required for GLKQuaternionSlerp




class BoatController: NSObject {
    // MARK: - Properties
    
    var boatNode: SCNNode
    var cameraNode: SCNNode // This is the node with the SCNCamera component
    
    private var cameraPivotNode: SCNNode! // New: A pivot node for smooth camera transforms
    
    // Camera follow settings
    private let cameraDistance: Float = 15.0
    private let cameraHeight: Float = 8.0
    private let cameraPositionSmoothingFactor: Float = 0.1 // Lower value = smoother/slower
    private let cameraOrientationSmoothingFactor: Float = 0.05 // Lower value = smoother/slower
    
    // Physics properties
    private let rotationForce: Float = 2.0
    private let forwardForce: Float = 5.0
    private let verticalForce: Float = 3.0 // New: Force for up/down movement
    
    // Paddling timer control
    private var canPaddleLeft = true
    private var canPaddleRight = true
    private let paddlingInterval: TimeInterval = 0.1
    
    // New: Vertical movement timer control
    private var canMoveUp = true
    private var canMoveDown = true
    private let verticalMovementInterval: TimeInterval = 0.1 // Similar to paddling
    
    // Keep track of key states
    private var leftKeyDown = false
    private var rightKeyDown = false
    private var upKeyDown = false   // New
    private var downKeyDown = false // New
    
    // MARK: - Initialization
    
    init(boatNode: SCNNode, cameraNode: SCNNode) {
        self.boatNode = boatNode
        self.cameraNode = cameraNode
        
        super.init()
        
        setupPhysics()
        setupCamera()
        setupKeyHandling()
    }
    
    // MARK: - Setup
    
    private func setupPhysics() {
        let shape = SCNPhysicsShape(node: boatNode, options: [SCNPhysicsShape.Option.keepAsCompound: true])
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        
        physicsBody.mass = 5.0
        physicsBody.friction = 0.1
        physicsBody.restitution = 0.2
        physicsBody.angularDamping = 0.1
        physicsBody.damping = 0.05
        physicsBody.isAffectedByGravity = false // Important for controlled vertical movement
        boatNode.physicsBody = physicsBody
    }
    
    private func setupCamera() {
        cameraPivotNode = SCNNode()
        guard let sceneRoot = cameraNode.parent else {
            fatalError("Camera node must be part of the scene graph before BoatController is initialized.")
        }
        sceneRoot.addChildNode(cameraPivotNode)
        
        cameraNode.removeFromParentNode()
        cameraPivotNode.addChildNode(cameraNode)
        
        cameraNode.position = SCNVector3(x: 0, y: CGFloat(cameraHeight), z: CGFloat(cameraDistance))
        cameraNode.look(at: SCNVector3(0, 5, -cameraDistance * 0.25))
        
        if boatNode.physicsBody != nil {
            cameraPivotNode.worldPosition = boatNode.presentation.worldPosition
            cameraPivotNode.worldOrientation = boatNode.presentation.worldOrientation
        } else {
            cameraPivotNode.worldPosition = boatNode.worldPosition
            cameraPivotNode.worldOrientation = boatNode.worldOrientation
        }
    }
    
    private func setupKeyHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            guard let self = self else { return event }
            if self.handleKeyDown(event) { return nil }
            return event
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event -> NSEvent? in
            guard let self = self else { return event }
            if self.handleKeyUp(event) { return nil }
            return event
        }
    }
    
    // MARK: - Key Handling
    private func handleKeyDown(_ event: NSEvent) -> Bool {
        // Ignore repeated key down events if we are already processing the key
        if event.isARepeat {
            // For continuous actions triggered by the timer, we don't need to re-trigger on repeat here.
            // The timer-based repeat handles holding the key.
            // However, if you wanted an action on *every* OS key repeat event, you'd handle it here.
            // For now, we only care about the initial press to start the timed action.
            switch event.keyCode {
            case 123, 124, 125, 126: return true // Consume known repeat events
            default: return false
            }
        }

        switch event.keyCode {
        case 123: // Left arrow key
            if !leftKeyDown { // Process only if not already down (prevents re-triggering from system repeat)
                leftKeyDown = true
                paddleLeft()
            }
            return true
        case 124: // Right arrow key
            if !rightKeyDown {
                rightKeyDown = true
                paddleRight()
            }
            return true
        case 126: // Up arrow key (New)
            if !upKeyDown {
                upKeyDown = true
                ascend()
            }
            return true
        case 125: // Down arrow key (New)
            if !downKeyDown {
                downKeyDown = true
                descend()
            }
            return true
        default:
            return false
        }
    }
    
    private func handleKeyUp(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 123: // Left arrow key
            leftKeyDown = false
            return true
        case 124: // Right arrow key
            rightKeyDown = false
            return true
        case 126: // Up arrow key (New)
            upKeyDown = false
            return true
        case 125: // Down arrow key (New)
            downKeyDown = false
            return true
        default:
            return false
        }
    }
    
    // MARK: - Paddling Controls
    public func paddleLeft() {
        guard canPaddleLeft else { return }
        applyRotation(direction: -1)
        applyForwardForce(paddleSide: .left)
        canPaddleLeft = false
        DispatchQueue.main.asyncAfter(deadline: .now() + paddlingInterval) { [weak self] in
            self?.canPaddleLeft = true
            if self?.leftKeyDown == true { self?.paddleLeft() }
        }
    }
    
    public func paddleRight() {
        guard canPaddleRight else { return }
        applyRotation(direction: 1)
        applyForwardForce(paddleSide: .right)
        canPaddleRight = false
        DispatchQueue.main.asyncAfter(deadline: .now() + paddlingInterval) { [weak self] in
            self?.canPaddleRight = true
            if self?.rightKeyDown == true { self?.paddleRight() }
        }
    }

    // MARK: - Vertical Movement Controls (New)
    private func ascend() {
        guard canMoveUp else { return }
        applyVerticalForce(direction: 1) // Positive direction for up
        canMoveUp = false
        DispatchQueue.main.asyncAfter(deadline: .now() + verticalMovementInterval) { [weak self] in
            self?.canMoveUp = true
            if self?.upKeyDown == true { self?.ascend() }
        }
    }

    private func descend() {
        guard canMoveDown else { return }
        applyVerticalForce(direction: -1) // Negative direction for down
        canMoveDown = false
        DispatchQueue.main.asyncAfter(deadline: .now() + verticalMovementInterval) { [weak self] in
            self?.canMoveDown = true
            if self?.downKeyDown == true { self?.descend() }
        }
    }
    
    // MARK: - Physics Application
    
    private func applyRotation(direction: Float) {
        let torque = SCNVector4(0, 1, 0, direction * rotationForce)
        boatNode.physicsBody?.applyTorque(torque, asImpulse: true)
    }
    
    private enum PaddleSide {
        case left
        case right
    }
    
    private func applyForwardForce(paddleSide: PaddleSide) {
        let boatPresentation = boatNode.presentation
        let worldForward = boatPresentation.convertVector(SCNVector3(0, 0, -1), to: nil)
        let worldRight   = boatPresentation.convertVector(SCNVector3(1, 0, 0), to: nil)
        
        let sidePushScale: CGFloat = paddleSide == .left ? 0.15 : -0.15
        var combinedDirection = worldForward + (worldRight * sidePushScale)
        combinedDirection.y = 0 // Keep movement in the XZ plane for forward paddling
        
        let normalizedForceDirection = combinedDirection.normalized()

        if normalizedForceDirection.length() < 0.001 {
            var pureForward = worldForward
            pureForward.y = 0
            if pureForward.length() < 0.001 { return }

            let fallbackForce = pureForward.normalized() * CGFloat(forwardForce)
            boatNode.physicsBody?.applyForce(fallbackForce, asImpulse: true)
            return
        }

        let force = normalizedForceDirection * CGFloat(forwardForce)
        boatNode.physicsBody?.applyForce(force, asImpulse: true)
    }

    // New: Apply vertical force
    private func applyVerticalForce(direction: Float) {
        // Force directly along the world Y-axis
        let forceVector = SCNVector3(0, CGFloat(direction * verticalForce), 0)
        boatNode.physicsBody?.applyForce(forceVector, asImpulse: true)
    }

    // MARK: - Update Method
    
    public func update() {
        guard let pivot = cameraPivotNode, boatNode.physicsBody != nil else { return }

        let targetPosition = boatNode.presentation.worldPosition
        pivot.worldPosition = SCNVector3.lerp(start: pivot.worldPosition,
                                              end: targetPosition,
                                              t: cameraPositionSmoothingFactor)

        let targetOrientation = boatNode.presentation.worldOrientation
        
        let startQuat = GLKQuaternionMake(Float(pivot.worldOrientation.x),
                                          Float(pivot.worldOrientation.y),
                                          Float(pivot.worldOrientation.z),
                                          Float(pivot.worldOrientation.w))

        let endQuat = GLKQuaternionMake(Float(targetOrientation.x),
                                        Float(targetOrientation.y),
                                        Float(targetOrientation.z),
                                        Float(targetOrientation.w))

        let slerpedQuat_GLK = GLKQuaternionSlerp(startQuat, endQuat, cameraOrientationSmoothingFactor)

        pivot.worldOrientation = SCNVector4(x: CGFloat(slerpedQuat_GLK.x),
                                            y: CGFloat(slerpedQuat_GLK.y),
                                            z: CGFloat(slerpedQuat_GLK.z),
                                            w: CGFloat(slerpedQuat_GLK.w))
    }
}
