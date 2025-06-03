import SceneKit
import SpriteKit
import GLKit // Required for GLKQuaternionSlerp

class BoatController: NSObject {
    // MARK: - Properties
    
    var boatNode: SCNNode
    var cameraNode: SCNNode // This is the node with the SCNCamera component
    
    private var cameraPivotNode: SCNNode! //A pivot node for smooth camera transforms
    
    // Camera follow settings
    private let cameraDistance: Float = 11.0
    private let cameraHeight: Float = 3.5
    private let cameraPositionSmoothingFactor: Float = 0.3
    private let cameraOrientationSmoothingFactor: Float = 0.05
    
    // Physics properties
    private let rotationForce: Float = 30.0
    private let forwardForce: Float = 50.0
    private let verticalForce: Float = 20.0
    
    // --- REVISED: Timer control for continuous actions ---
    private var lastPaddleLeftTime: TimeInterval = 0
    private var lastPaddleRightTime: TimeInterval = 0
    private var lastMoveUpTime: TimeInterval = 0
    private var lastMoveDownTime: TimeInterval = 0
    
    // Interval for applying actions when keys are held (e.g., 10 times per second)
    private let actionInterval: TimeInterval = 0.1
    // --- END REVISED ---
    
    // Keep track of key states
    private var leftKeyDown = false
    private var rightKeyDown = false
    private var upKeyDown = false
    private var downKeyDown = false
    
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
        
        physicsBody.mass = 10.0
        physicsBody.friction = 0.1
        physicsBody.restitution = 0.2
        physicsBody.angularDamping = 1 // Increased slightly, can experiment
        physicsBody.damping = 0.3        // Increased slightly, can experiment
        physicsBody.isAffectedByGravity = false
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

        // --- REVISED: Key Handling ---
        private func setupKeyHandling() {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
                guard let self = self else { return event }
                
                // For arrow keys, we handle continuous action in the update() method.
                // We consume the initial press and repeats to prevent default system behavior.
                switch event.keyCode {
                case 123: // Left arrow key
                    if !event.isARepeat { // Only set flag on initial press
                        self.leftKeyDown = true
                    }
                    return nil // Consume the event (initial press and repeats)
                case 124: // Right arrow key
                    if !event.isARepeat {
                        self.rightKeyDown = true
                    }
                    return nil // Consume the event
                case 126: // Up arrow key
                    if !event.isARepeat {
                        self.upKeyDown = true
                    }
                    return nil // Consume the event
                case 125: // Down arrow key
                    if !event.isARepeat {
                        self.downKeyDown = true
                    }
                    return nil // Consume the event
                default:
                    return event // Not our key, pass it on
                }
            }
            
            NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event -> NSEvent? in
                guard let self = self else { return event }
                switch event.keyCode {
                case 123: // Left arrow key
                    self.leftKeyDown = false
                    return nil // Consume the event
                case 124: // Right arrow key
                    self.rightKeyDown = false
                    return nil // Consume the event
                case 126: // Up arrow key
                    self.upKeyDown = false
                    return nil // Consume the event
                case 125: // Down arrow key
                    self.downKeyDown = false
                    return nil // Consume the event
                default:
                    return event // Not our key, pass it on
                }
            }
        }
        // --- END REVISED Key Handling ---

    // ... (rest of BoatController) ...    // --- END REVISED Key Handling ---
    
    // MARK: - Direct Action Methods (for discrete calls, e.g., from Player swings or timed keyboard input)
    public func performLeftPaddleAction() {
        applyRotation(direction: -1)
        applyForwardForce(paddleSide: .left)
    }
    
    public func performRightPaddleAction() {
        applyRotation(direction: 1)
        applyForwardForce(paddleSide: .right)
    }

    public func performAscendAction() {
        applyVerticalForce(direction: 1)
    }

    public func performDescendAction() {
        applyVerticalForce(direction: -1)
    }
    
    // MARK: - Physics Application (Low-level helpers, unchanged)
    
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

    private func applyVerticalForce(direction: Float) {
        let forceVector = SCNVector3(0, CGFloat(direction * verticalForce), 0)
        boatNode.physicsBody?.applyForce(forceVector, asImpulse: true)
    }
    
    public func snapCameraToBoat() {
            guard let pivot = cameraPivotNode else {
                print("Warning: Camera pivot node not available for snapping.")
                return
            }
            let targetPosition = boatNode.worldPosition
            let targetOrientation = boatNode.worldOrientation

            pivot.worldPosition = targetPosition
            pivot.worldOrientation = targetOrientation
            
            print("Camera snapped to boat's new position/orientation.")
        }

    // MARK: - Update Method (REVISED)
    
    public func update(currentTime: TimeInterval) { // Takes currentTime from renderer
        // --- Apply physics based on key states and timing ---
        if leftKeyDown {
            if currentTime - lastPaddleLeftTime >= actionInterval {
                performLeftPaddleAction()
                lastPaddleLeftTime = currentTime
            }
        }
        if rightKeyDown {
            if currentTime - lastPaddleRightTime >= actionInterval {
                performRightPaddleAction()
                lastPaddleRightTime = currentTime
            }
        }
        if upKeyDown {
            if currentTime - lastMoveUpTime >= actionInterval {
                performAscendAction()
                lastMoveUpTime = currentTime
            }
        }
        if downKeyDown {
            if currentTime - lastMoveDownTime >= actionInterval {
                performDescendAction()
                lastMoveDownTime = currentTime
            }
        }

        // --- Camera Update Logic (remains the same) ---
        guard let pivot = cameraPivotNode, boatNode.physicsBody != nil else { return }

        let targetPosition = boatNode.presentation.worldPosition // Already using presentation node, good!
        pivot.worldPosition = SCNVector3.lerp(start: pivot.worldPosition,
                                              end: targetPosition,
                                              t: cameraPositionSmoothingFactor)

        let targetOrientation = boatNode.presentation.worldOrientation // Already using presentation node, good!
        
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
