// Skyloon Crew/_Game/GameViewController.swift
import SceneKit
import SwiftUI
import Combine

// Helper extension for debugging node paths (place at file level or in a separate extensions file)
fileprivate extension SCNNode {
    func fullPath() -> String {
        if let parent = self.parent {
            // If parent is root, use its name directly, otherwise recurse
            let parentPath = parent.parent == nil ? (parent.name ?? "RootNode") : parent.fullPath()
            return parentPath + "/" + (self.name ?? "SCNNode") // Default to SCNNode if name is nil
        } else {
            // This node is the root node
            return (self.name ?? "RootNode")
        }
    }
}

class GameViewController: NSViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {
    // MARK: - Properties

    var sceneView: SCNView!
    var scene: SCNScene!
    var boatController: BoatController!
    var boatNode: SCNNode!

    // Game Logic
    var gameManager: GameManager!
    var infoViewModel: InfoViewModel!

    // SwiftUI Overlay
    var hostingView: NSHostingView<GameOverlayView>!

    // Connection Manager and Observation
    private let connectionManager: ConnectionManager
    private var cancellables = Set<AnyCancellable>()

    // Default starting state for the boat
    private let defaultBoatPosition = SCNVector3(x: 0, y: 1, z: 0)
    private let defaultBoatOrientation = SCNQuaternion(x: 0, y: 0, z: 0, w: 1)

    // New properties for managing bear models associated with players
    private var playerBearModelNodes: [SCNNode?] = Array(repeating: nil, count: Constants.maxPlayers)
    // Stores deep copies of original materials for each bear model
    private var defaultBearMaterials: [[SCNMaterial]] = Array(repeating: [], count: Constants.maxPlayers)


    // MARK: - Initializer
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(connectionManager:) instead.")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScene() // This will now also find and prepare bear nodes
        setupBoat()

        infoViewModel = InfoViewModel()
        guard let boatNode = self.boatNode, let cameraNode = sceneView.pointOfView else {
             fatalError("Boat node or camera node not found before initializing GameManager.")
        }
        gameManager = GameManager(scene: scene,
                                  boatNode: boatNode,
                                  cameraNode: cameraNode,
                                  infoViewModel: infoViewModel)

        setupSwiftUIOverlay()
        observeConnectionManager() // This will trigger initial bear appearance update

        sceneView.delegate = self
        scene.physicsWorld.contactDelegate = self

        // Initial game start
        triggerFullGameRestart()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        if let hostingView = hostingView {
            hostingView.frame = sceneView.bounds
        }
    }

    // MARK: - Setup
    private func setupScene() {
        sceneView = SCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.width, .height]
        view.addSubview(sceneView)

        guard let scene = SCNScene(named: "art.scnassets/Main Scene.scn") else {
            fatalError("Failed to load Main Scene.scn")
        }
        self.scene = scene
        self.scene.background.contents = "Skybox1"
        sceneView.scene = scene
        sceneView.allowsCameraControl = false
        sceneView.showsStatistics = false

        if let boat = scene.rootNode.childNode(withName: "Boat", recursively: true) {
             self.boatNode = boat
             if boat.physicsBody == nil {
                 print("Warning: Boat physics body not set up by BoatController, ensure it's configured.")
             }
             boat.physicsBody?.categoryBitMask = PhysicsCategory.boat
             boat.physicsBody?.contactTestBitMask = PhysicsCategory.answerZone

            // Find player bear models, store them and their original materials
            for i in 0..<Constants.maxPlayers {
                let playerNumber = i + 1
                // "BearX" (e.g., Bear1, Bear2) are container nodes under the Boat
                if let bearContainerNode = boatNode.childNode(withName: "Bear\(playerNumber)", recursively: false) {
                    // The actual mesh is expected to be a child of BearX, often named "bear"
                    if let actualBearMesh = findActualBearMeshNode(within: bearContainerNode) {
                        self.playerBearModelNodes[i] = actualBearMesh
                        // Store deep copies of original materials for resetting
                        if let materials = actualBearMesh.geometry?.materials {
                            self.defaultBearMaterials[i] = materials.map { $0.copy() as! SCNMaterial }
                        } else {
                            self.defaultBearMaterials[i] = [] // Ensure it's an empty array, not nil
                        }
                        print("Found actual bear model for Bear\(playerNumber): '\(actualBearMesh.name ?? "Unnamed")' (path: \(actualBearMesh.fullPath()))")
                    } else {
                        print("Warning: Could not find geometry sub-node within Bear\(playerNumber) container ('\(bearContainerNode.name ?? "Unnamed")'). Path: \(bearContainerNode.fullPath())")
                    }
                    // Initially hide the BearX container. It will be unhidden when a player connects.
                    bearContainerNode.isHidden = true
                } else {
                    // This is not an error if the scene intentionally has fewer bears than maxPlayers
                    // print("Log: Bear\(playerNumber) container node not found directly under Boat node. This slot may not be used visually.")
                }
            }
        } else {
            fatalError("Boat node not found in scene for physics setup.")
        }

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 200 // Adjusted intensity for potentially darker bear materials
        scene.rootNode.addChildNode(ambientLight)

        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = NSColor.white
        directionalLight.light?.castsShadow = true
        directionalLight.position = SCNVector3(x: 10, y: 20, z: 10)
        directionalLight.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(directionalLight)
    }

    // Helper to find the primary mesh node within a bear container (e.g., BearX -> "bear" (mesh))
    private func findActualBearMeshNode(within containerNode: SCNNode) -> SCNNode? {
        // 1. Prioritize a direct child named "bear" (case-insensitive) that has geometry.
        if let specificBearNode = containerNode.childNodes.first(where: { $0.name?.lowercased() == "bear" && $0.geometry != nil }) {
            return specificBearNode
        }

        // 2. Fallback: If no "bear" child, search the hierarchy within containerNode for the *first* node with geometry.
        var geometryNode: SCNNode?
        containerNode.enumerateHierarchy { (node, stop) in
            if node.geometry != nil {
                geometryNode = node // Take the first one found
                stop.pointee = true
                return
            }
        }
        if let foundNode = geometryNode {
            print("Log: Did not find specific 'bear' mesh in '\(containerNode.name ?? "Unnamed")'. Using first geometry node found: '\(foundNode.name ?? "Unnamed")' at path \(foundNode.fullPath())")
            return foundNode
        }

        // 3. Further Fallback: If the containerNode itself has geometry (less common for a group node like "BearX").
        if containerNode.geometry != nil {
            print("Log: Did not find 'bear' mesh or any child geometry in '\(containerNode.name ?? "Unnamed")'. Using container itself as it has geometry.")
            return containerNode
        }
        
        return nil // No suitable mesh node found
    }

    private func setupBoat() {
        guard let boatNode = self.boatNode else {
            fatalError("Failed to find Boat node in scene. It should have been found in setupScene.")
        }

        let cameraEntityNode = SCNNode()
        cameraEntityNode.camera = SCNCamera()
        cameraEntityNode.camera?.zFar = 1000
        scene.rootNode.addChildNode(cameraEntityNode)

        boatController = BoatController(boatNode: boatNode, cameraNode: cameraEntityNode)
        sceneView.pointOfView = cameraEntityNode
    }

    private func setupSwiftUIOverlay() {
        let overlayView = GameOverlayView(viewModel: infoViewModel, onRestartGame: { [weak self] in
            self?.triggerFullGameRestart()
        })
        hostingView = NSHostingView(rootView: overlayView)
        hostingView.frame = sceneView.bounds
        hostingView.autoresizingMask = [.width, .height]
        hostingView.layer?.backgroundColor = .clear // Ensure overlay doesn't block scene visibility
        sceneView.addSubview(hostingView)
    }
    
    // MARK: - Game Restart Logic

    private func prepareForNewGameSceneState() {
        guard let boat = self.boatNode, let boatCtrl = self.boatController else {
            print("Error: Boat node or controller not available for scene reset.")
            return
        }

        print("Preparing scene for new game: Resetting boat state to Pos: \(defaultBoatPosition), Ori: \(defaultBoatOrientation).")

        if let physicsBody = boat.physicsBody {
            physicsBody.clearAllForces()
            physicsBody.velocity = SCNVector3Zero
            physicsBody.angularVelocity = SCNVector4Zero
        }
        boat.position = defaultBoatPosition
        boat.orientation = defaultBoatOrientation
        boatCtrl.snapCameraToBoat()
    }

    private func triggerFullGameRestart() {
        print("Triggering full game restart...")
        self.prepareForNewGameSceneState()
        self.gameManager.startGame(
            initialBoatPosition: self.defaultBoatPosition,
            initialBoatOrientation: self.defaultBoatOrientation
        )
    }

    // MARK: - Connection Manager Observation
    private func observeConnectionManager() {
        connectionManager.$players
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedPlayers in
                guard let self = self else { return }
                // Log player connection states for debugging
                let playerStates = updatedPlayers.map { "P\($0.playerNumber)-\($0.playerName):\($0.connectionState)" }.joined(separator: ", ")
                print("GameVC observed players: [\(playerStates)]")
                
                self.updatePlayerBoatControllers(with: updatedPlayers)
                self.updateBearAppearances(with: updatedPlayers) // New call to update bear models
            }
            .store(in: &cancellables)
    }

    // Method to update player-specific boat controllers (existing)
    private func updatePlayerBoatControllers(with players: [Player]) {
        guard let boatCtrl = self.boatController else {
            print("BoatController not yet initialized. Will assign on next player update or after setupBoat.")
            return
        }

        players.forEach { player in
            if player.connectionState == .connected {
                if player.boatController == nil {
                    print("Assigning boat controller to \(player.playerName) in GameViewController")
                    player.boatController = boatCtrl
                }
            } else {
                if player.boatController != nil {
                     print("Unassigning boat controller from \(player.playerName) in GameViewController")
                     player.boatController = nil
                }
            }
        }
    }
    
    // New method to update bear model colors and visibility based on player connection
    private func updateBearAppearances(with players: [Player]) {
        guard let boat = self.boatNode else {
            print("Error: Boat node not available for updating bear appearances.")
            return
        }

        for i in 0..<Constants.maxPlayers {
            let playerNumber = i + 1 // Player numbers are 1-based (e.g., 1, 2, 3, 4)
            
            // Get the "BearX" container node (e.g., "Bear1", "Bear2")
            guard let bearContainerNode = boat.childNode(withName: "Bear\(playerNumber)", recursively: false) else {
                // This slot might not have a visual representation if scene has fewer bears than maxPlayers
                continue
            }
            
            // Get the actual mesh node for this bear (e.g., the "bear" sub-node with geometry)
            guard let actualBearMeshNode = self.playerBearModelNodes[i] else {
                // If no mesh node was stored (e.g., findActualBearMeshNode failed), ensure container is hidden.
                bearContainerNode.isHidden = true
                continue
            }

            // Check if there is a connected player for this specific playerNumber
            if let player = players.first(where: { $0.playerNumber == playerNumber && $0.connectionState == .connected }) {
                // Player IS connected for this slot:
                bearContainerNode.isHidden = false // Make the BearX container visible
                
                if let playerColor = Color(hex: player.playerColorHex) {
                    let nsPlayerColor = NSColor(playerColor)
                    
                    // Check if update is necessary to avoid redundant material changes
                    if !(actualBearMeshNode.geometry?.materials.first?.diffuse.contents as? NSColor == nsPlayerColor) {
                        // Create new materials based on defaults, then apply player color
                        // This ensures each player bear has its own material instance.
                        let newMaterials = self.defaultBearMaterials[i].map { originalMaterial -> SCNMaterial in
                            let newPlayerMaterial = originalMaterial.copy() as! SCNMaterial
                            newPlayerMaterial.diffuse.contents = nsPlayerColor
                            // You might want to adjust other properties like shininess or lighting model here if needed
                            // e.g., newPlayerMaterial.lightingModel = .phong
                            //       newPlayerMaterial.shininess = 10.0 (0-128)
                            return newPlayerMaterial
                        }
                        actualBearMeshNode.geometry?.materials = newMaterials
                        print("Updated Bear\(playerNumber) (mesh: '\(actualBearMeshNode.name ?? "")') color for \(player.playerName) to \(player.playerColorHex).")
                    }
                } else {
                    print("Warning: Invalid hex color '\(player.playerColorHex)' for player \(player.playerName). Resetting Bear\(playerNumber) to default materials.")
                    // If color is invalid, reset to original materials
                    actualBearMeshNode.geometry?.materials = self.defaultBearMaterials[i].map { $0.copy() as! SCNMaterial }
                }
            } else {
                // Player is NOT connected for this slot (or player object not found for this number):
                bearContainerNode.isHidden = true // Hide the BearX container
                
                // Reset materials to default if they aren't already
                // Check by comparing current materials count and first material's diffuse content (simplistic check)
                let currentMaterials = actualBearMeshNode.geometry?.materials ?? []
                let defaultMaterialsForSlot = self.defaultBearMaterials[i]
                
                var needsReset = currentMaterials.count != defaultMaterialsForSlot.count
                if !needsReset && !currentMaterials.isEmpty && !defaultMaterialsForSlot.isEmpty {
                    if (currentMaterials.first!.diffuse.contents as? NSColor) != (defaultMaterialsForSlot.first!.diffuse.contents as? NSColor) {
                        needsReset = true
                    }
                } else if currentMaterials.isEmpty && !defaultMaterialsForSlot.isEmpty {
                     needsReset = true // If current is empty but default isn't, reset
                }


                if needsReset {
                    actualBearMeshNode.geometry?.materials = defaultMaterialsForSlot.map { $0.copy() as! SCNMaterial }
                    print("Hid Bear\(playerNumber) (mesh: '\(actualBearMeshNode.name ?? "")') and reset its materials (no connected player or player disconnected).")
                }
            }
        }
    }

    // MARK: - SCNSceneRendererDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        boatController?.update()
    }

    // MARK: - SCNPhysicsContactDelegate
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB

        var boat: SCNNode?
        var answerZoneSphere: SCNNode?

        if nodeA.physicsBody?.categoryBitMask == PhysicsCategory.boat && nodeB.physicsBody?.categoryBitMask == PhysicsCategory.answerZone {
            boat = nodeA
            answerZoneSphere = nodeB
        } else if nodeB.physicsBody?.categoryBitMask == PhysicsCategory.boat && nodeA.physicsBody?.categoryBitMask == PhysicsCategory.answerZone {
            boat = nodeB
            answerZoneSphere = nodeA
        }

        if boat != nil, let zoneSphere = answerZoneSphere {
             if let answerZoneContainer = zoneSphere.parent as? AnswerZoneNode {
                  DispatchQueue.main.async {
                      self.gameManager.playerChoseAnswer(collidedZoneNode: answerZoneContainer)
                  }
             } else if let answerZoneContainerViaName = findAnswerZoneContainerInParents(node: zoneSphere) {
                 DispatchQueue.main.async {
                     self.gameManager.playerChoseAnswer(collidedZoneNode: answerZoneContainerViaName)
                 }
             }
        }
    }

    private func findAnswerZoneContainerInParents(node: SCNNode) -> AnswerZoneNode? {
        var currentNode: SCNNode? = node
        while currentNode != nil {
            if let answerZone = currentNode as? AnswerZoneNode {
                return answerZone
            }
            currentNode = currentNode?.parent
        }
        return nil
    }
}


