// Skyloon Crew/_Game/GameViewController.swift
import SceneKit
import SwiftUI
import Combine

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
    private let defaultBoatOrientation = SCNQuaternion(x: 0, y: 0, z: 0, w: 1) // No rotation (facing -Z by SCNNode default)

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

        setupScene()
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
        observeConnectionManager()

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
        sceneView.showsStatistics = true

        if let boat = scene.rootNode.childNode(withName: "Boat", recursively: true) {
             self.boatNode = boat
             if boat.physicsBody == nil {
                 print("Warning: Boat physics body not set up by BoatController, ensure it's configured.")
             }
             boat.physicsBody?.categoryBitMask = PhysicsCategory.boat
             boat.physicsBody?.contactTestBitMask = PhysicsCategory.answerZone
        } else {
            fatalError("Boat node not found in scene for physics setup.")
        }

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 200
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
        hostingView.layer?.backgroundColor = .clear
        sceneView.addSubview(hostingView)
    }
    
    // MARK: - Game Restart Logic

    private func prepareForNewGameSceneState() {
        guard let boat = self.boatNode, let boatCtrl = self.boatController else {
            print("Error: Boat node or controller not available for scene reset.")
            return
        }

        print("Preparing scene for new game: Resetting boat state to Pos: \(defaultBoatPosition), Ori: \(defaultBoatOrientation).")

        // Reset boat physics
        if let physicsBody = boat.physicsBody {
            physicsBody.clearAllForces()
            physicsBody.velocity = SCNVector3Zero
            physicsBody.angularVelocity = SCNVector4Zero
        }

        // Reset boat position and orientation
        // These changes will be picked up by SceneKit's rendering loop.
        // The presentation node will update accordingly in the next frame(s).
        boat.position = defaultBoatPosition
        boat.orientation = defaultBoatOrientation
        
        // Snap camera to the new boat state immediately
        boatCtrl.snapCameraToBoat()
    }

    private func triggerFullGameRestart() {
        print("Triggering full game restart...")
        // 1. Reset SceneKit world state (boat, camera)
        // This sets boat.position and boat.orientation directly.
        self.prepareForNewGameSceneState()

        // 2. Reset game logic and start new game.
        // Pass the intended initial boat state to GameManager so it can use these
        // exact values for the *first* answer zone spawn, avoiding reliance on
        // the presentation node reflecting the changes within the same run loop.
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
                print("GameViewController observed player update: \(updatedPlayers.map { $0.playerName })")
                self.updatePlayerBoatControllers(with: updatedPlayers)
            }
            .store(in: &cancellables)
    }

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

// Helper for SCNVector3 cross product if not already available
// (You might have this in SCNVector3+Extensions.swift)
extension SCNVector3 {
    static func cross(_ vector1: SCNVector3, _ vector2: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(vector1.y * vector2.z - vector1.z * vector2.y,
                              vector1.z * vector2.x - vector1.x * vector2.z,
                              vector1.x * vector2.y - vector1.y * vector2.x)
    }
}
