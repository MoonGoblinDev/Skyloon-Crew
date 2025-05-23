import SceneKit
import SwiftUI
import Combine // <-- Import Combine

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
    private let connectionManager: ConnectionManager // Store the instance
    private var cancellables = Set<AnyCancellable>() // To store Combine subscriptions
    
    // Default starting state for the boat
    private let defaultBoatPosition = SCNVector3(x: 0, y: 1, z: 0) // Slightly above origin if there's a floor/water
    private let defaultBoatOrientation = SCNQuaternion(x: 0, y: 0, z: 0, w: 1) // No rotation

    // MARK: - Initializer

    // Custom initializer to accept ConnectionManager
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        super.init(nibName: nil, bundle: nil)
    }

    // Required initializer for NSViewController
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
        // Initialize GameManager
        gameManager = GameManager(scene: scene,
                                  boatNode: boatNode,
                                  cameraNode: cameraNode,
                                  infoViewModel: infoViewModel)

        setupSwiftUIOverlay()
        observeConnectionManager()

        sceneView.delegate = self
        scene.physicsWorld.contactDelegate = self

        // Initial game start
        triggerFullGameRestart() // Start the game by triggering a full reset and game manager start
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
        ambientLight.light?.intensity = 200 // You might want to adjust this with a skybox,
                                           // as skyboxes can also contribute to lighting via IBL.
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
        cameraEntityNode.camera?.zFar = 1000 // Skybox is typically rendered "at infinity"
        scene.rootNode.addChildNode(cameraEntityNode)

        boatController = BoatController(boatNode: boatNode, cameraNode: cameraEntityNode)
        sceneView.pointOfView = cameraEntityNode
    }

    private func setupSwiftUIOverlay() {
        let overlayView = GameOverlayView(viewModel: infoViewModel, onRestartGame: { [weak self] in
            self?.triggerFullGameRestart() // Changed to call new restart function
        })
        hostingView = NSHostingView(rootView: overlayView)
        hostingView.frame = sceneView.bounds
        hostingView.autoresizingMask = [.width, .height]
        hostingView.layer?.backgroundColor = .clear
        sceneView.addSubview(hostingView)
    }

    // MARK: - Connection Manager Observation
    private func observeConnectionManager() {
        connectionManager.$players // Observe the @Published players array
            .receive(on: DispatchQueue.main) // Ensure updates are on the main thread
            .sink { [weak self] updatedPlayers in
                guard let self = self else { return }
                print("GameViewController observed player update: \(updatedPlayers.map { $0.playerName })")
                self.updatePlayerBoatControllers(with: updatedPlayers)
            }
            .store(in: &cancellables) // Store subscription to manage its lifecycle
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
    
    private func prepareForNewGameSceneState() {
            guard let boat = self.boatNode, let boatCtrl = self.boatController else {
                print("Error: Boat node or controller not available for scene reset.")
                return
            }

            print("Preparing scene for new game: Resetting boat state.")

            // Reset boat physics
            if let physicsBody = boat.physicsBody {
                physicsBody.clearAllForces()
                physicsBody.velocity = SCNVector3Zero
                physicsBody.angularVelocity = SCNVector4Zero
            }

            // Reset boat position and orientation
            boat.position = defaultBoatPosition
            boat.orientation = defaultBoatOrientation
            // SCNView.prepare is useful if you want to ensure nodes are ready, but not strictly necessary here
            // self.sceneView.prepare([boat], completionHandler: nil)


            // Snap camera to the new boat state
            boatCtrl.snapCameraToBoat()
            
            // GameManager.cleanupCurrentQuestion() will handle removing answer zones.
            // If there were other scene elements dynamically added by GameViewController,
            // they would be removed here. For now, answer zones are the main ones.
        }

        private func triggerFullGameRestart() {
            print("Triggering full game restart...")
            // 1. Reset SceneKit world state (boat, camera)
            self.prepareForNewGameSceneState()

            // 2. Reset game logic and start new game (questions, score, health)
            // GameManager's startGame will call nextQuestion, which calls cleanupCurrentQuestion.
            self.gameManager.startGame()
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

// Assume these are defined elsewhere or add stubs if needed for compilation
// class BoatController { init(boatNode: SCNNode, cameraNode: SCNNode) {} func update() {} }
// class GameManager { init(scene: SCNScene, boatNode: SCNNode, cameraNode: SCNNode, infoViewModel: InfoViewModel) {} func startGame() {} func playerChoseAnswer(collidedZoneNode: SCNNode) {} }
// class InfoViewModel: ObservableObject {}
// struct GameOverlayView: View { var viewModel: InfoViewModel; var onRestartGame: () -> Void; var body: some View { Text("Overlay") } }
// class ConnectionManager: ObservableObject { @Published var players: [Player] = [] }
// class Player: ObservableObject { var playerName: String = ""; var connectionState: ConnectionState = .disconnected; var boatController: BoatController? }
// enum ConnectionState { case connected, disconnected }
// struct PhysicsCategory { static let boat: Int = 1; static let answerZone: Int = 2 }
// class AnswerZoneNode: SCNNode {}
