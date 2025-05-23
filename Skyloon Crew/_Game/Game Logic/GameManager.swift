// GameLogic/GameManager.swift
import SceneKit
import Combine

class GameManager {
    weak var scene: SCNScene?
    weak var boatNode: SCNNode? // Still useful for subsequent questions
    weak var cameraNode: SCNNode?
    var infoViewModel: InfoViewModel

    private var questions: [Question] = []
    private var currentQuestionIndex: Int = -1
    private var activeAnswerZones: [AnswerZoneNode] = []

    private var gameTimer: Timer?
    private let questionTimeLimit: Int = 30

    private let answerZoneColors: [NSColor] = [
        .systemRed, .systemGreen, .systemBlue, .systemYellow, .systemPurple, .systemOrange
    ]

    // Temporary storage for initial spawn parameters
    private var initialSpawnPositionForFirstQuestion: SCNVector3?
    private var initialSpawnOrientationForFirstQuestion: SCNQuaternion?

    init(scene: SCNScene, boatNode: SCNNode, cameraNode: SCNNode, infoViewModel: InfoViewModel) {
        self.scene = scene
        self.boatNode = boatNode
        self.cameraNode = cameraNode
        self.infoViewModel = infoViewModel
        loadQuestions()
    }

    private func loadQuestions() {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            print("Error: questions.json not found in bundle.")
            self.questions = []
            infoViewModel.currentQuestionText = "Error: Question data not found."
            infoViewModel.isGameOver = true
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.questions = try decoder.decode([Question].self, from: data)
            print("Successfully loaded \(self.questions.count) questions from JSON.")
            self.questions.shuffle()
        } catch {
            print("Error loading or decoding questions.json: \(error)")
            self.questions = []
            infoViewModel.currentQuestionText = "Error: Could not load questions."
            infoViewModel.isGameOver = true
        }
    }

    // Modified startGame to accept initial boat state for the first question
    func startGame(initialBoatPosition: SCNVector3? = nil, initialBoatOrientation: SCNQuaternion? = nil) {
        infoViewModel.health = 3
        infoViewModel.score = 0
        infoViewModel.isGameOver = false
        infoViewModel.gameMessage = ""
        currentQuestionIndex = -1 // Reset for the new game

        // Store initial parameters if provided (for the very first question spawn)
        self.initialSpawnPositionForFirstQuestion = initialBoatPosition
        self.initialSpawnOrientationForFirstQuestion = initialBoatOrientation
        print("GameManager.startGame: Initial spawn params set - Pos: \(String(describing: initialBoatPosition)), Ori: \(String(describing: initialBoatOrientation))")


        if questions.isEmpty {
            loadQuestions()
        } else {
            questions.shuffle() // Re-shuffle for a new game
        }

        if questions.isEmpty {
            print("No questions available to start the game.")
            infoViewModel.currentQuestionText = "No questions available to start the game."
            infoViewModel.isGameOver = true
            return
        }
        
        nextQuestion() // This will now use the initial parameters if it's the first call
    }

    func nextQuestion() {
        guard let scene = scene else { return }
        
        cleanupCurrentQuestion() // Remove old zones and stop timer

        if infoViewModel.health <= 0 {
            gameOver()
            return
        }

        currentQuestionIndex += 1
        if currentQuestionIndex >= questions.count {
            if questions.isEmpty {
                infoViewModel.currentQuestionText = "No questions available. Game Over."
                gameOver()
                return
            }
            print("All questions answered. Restarting question cycle.")
            currentQuestionIndex = 0
            questions.shuffle()
            infoViewModel.gameMessage = "New round of questions!"
             DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                 self?.infoViewModel.gameMessage = ""
             }
        }

        guard questions.indices.contains(currentQuestionIndex) else {
            print("Error: currentQuestionIndex is out of bounds after attempting to loop.")
            gameOver()
            return
        }

        let question = questions[currentQuestionIndex]
        infoViewModel.currentQuestionText = question.text

        // Determine spawn parameters based on whether it's the initial call or subsequent
        let spawnRefPos: SCNVector3
        var boatWorldForward: SCNVector3
        let boatWorldRight: SCNVector3

        // Check if initial parameters are set AND if this is the first question of this game instance (index 0)
        if let initialPos = self.initialSpawnPositionForFirstQuestion,
           let initialOri = self.initialSpawnOrientationForFirstQuestion,
           currentQuestionIndex == 0 {
            
            print("Spawning FIRST question zones using initial reset position: \(initialPos)")
            spawnRefPos = initialPos
            
            // Calculate forward and right vectors from the initial orientation
            // SCNNode's orientation directly gives world orientation if it's a root node or if its parent has identity transform.
            // For precise calculation from quaternion without a node in scene:
            let q = initialOri
            boatWorldForward = SCNVector3(2 * (q.x * q.z + q.w * q.y),
                                          2 * (q.y * q.z - q.w * q.x),
                                          1 - 2 * (q.x * q.x + q.y * q.y)).normalized() // This is +Z local
            boatWorldForward = SCNVector3(-boatWorldForward.x, -boatWorldForward.y, -boatWorldForward.z) // Assuming -Z is "forward" for boats

            boatWorldRight = SCNVector3(1 - 2 * (q.y * q.y + q.z * q.z),
                                         2 * (q.x * q.y + q.w * q.z),
                                         2 * (q.x * q.z - q.w * q.y)).normalized() // This is +X local

            // Crucially, clear these initial parameters so they are only used once per game start
            self.initialSpawnPositionForFirstQuestion = nil
            self.initialSpawnOrientationForFirstQuestion = nil
            print("Initial spawn params consumed and cleared.")

        } else {
            guard let boat = self.boatNode else {
                print("Error: Boat node not available for subsequent question spawning.")
                gameOver() // Or handle error appropriately
                return
            }
            print("Spawning zones based on CURRENT boat presentation node. Pos: \(boat.presentation.worldPosition)")
            spawnRefPos = boat.presentation.worldPosition
            boatWorldForward = boat.presentation.worldFront // worldFront is -Z in world space
            boatWorldRight = boat.presentation.worldRight   // worldRight is +X in world space
        }

        spawnAnswerZones(for: question,
                         spawnReferencePoint: spawnRefPos,
                         boatWorldForward: boatWorldForward,
                         boatWorldRight: boatWorldRight)
        startTimer()
    }

    // spawnAnswerZones now takes explicit reference point and orientation vectors
    private func spawnAnswerZones(for question: Question,
                                  spawnReferencePoint boatPos: SCNVector3,
                                  boatWorldForward: SCNVector3,
                                  boatWorldRight: SCNVector3) {
        guard let scene = scene else { return }
        activeAnswerZones.removeAll() // Clear any previous (should be done by cleanup)

        // Project to XZ plane for horizontal layout, and normalize
        var horizontalForward = SCNVector3(boatWorldForward.x, 0, boatWorldForward.z).normalized()
        if horizontalForward.length() < 0.001 { // Avoid division by zero if boat points straight up/down
            horizontalForward = SCNVector3(0, 0, -1) // Default forward if original is too vertical
        }
        var horizontalRight = SCNVector3(boatWorldRight.x, 0, boatWorldRight.z).normalized()
        if horizontalRight.length() < 0.001 {
             // Derive from forward if right is too vertical or zero (e.g. boat looking straight up/down)
            horizontalRight = SCNVector3.cross(SCNVector3(0,1,0), horizontalForward).normalized()
            if horizontalRight.length() < 0.001 { horizontalRight = SCNVector3(1,0,0) } // Absolute fallback
        }


        let spawnDistanceInFront: Float = 300.0
        let spacingBetweenZoneCenters: Float = Float(AnswerZoneNode.sphereRadius * 5.0 + AnswerZoneNode.sphereRadius * 0.5)
        
        let numberOfAnswers = Float(question.answers.count)
        
        // Y position for the center of the answer zones.
        // Using the Y from the spawnReferencePoint.
        let zoneLineY = boatPos.y

        // Calculate the center point of the line of answers
        let lineCenterPoint = SCNVector3(
            boatPos.x + horizontalForward.x * CGFloat(spawnDistanceInFront),
            zoneLineY,
            boatPos.z + horizontalForward.z * CGFloat(spawnDistanceInFront)
        )

        let totalLineWidth = (numberOfAnswers - 1.0) * spacingBetweenZoneCenters
        let offsetForFirstZone = -totalLineWidth / 2.0 // Start from the left (relative to boat's right)

        var availableColors = answerZoneColors
        availableColors.shuffle()

        for (index, answerText) in question.answers.enumerated() {
            let displacementFromLineCenter = offsetForFirstZone + Float(index) * spacingBetweenZoneCenters
            
            // Position is calculated by moving from lineCenterPoint along the horizontalRight vector
            let position = SCNVector3(
                lineCenterPoint.x + horizontalRight.x * CGFloat(displacementFromLineCenter),
                zoneLineY,
                lineCenterPoint.z + horizontalRight.z * CGFloat(displacementFromLineCenter)
            )
            
            let isCorrect = (answerText == question.correctAnswer)
            let color = availableColors[index % availableColors.count]

            let answerZone = AnswerZoneNode(answerText: answerText,
                                            isCorrect: isCorrect,
                                            color: color,
                                            position: position)
            scene.rootNode.addChildNode(answerZone)
            activeAnswerZones.append(answerZone)
        }
    }

    func playerChoseAnswer(collidedZoneNode: SCNNode) {
        guard let answerZoneContainer = findAnswerZoneContainer(for: collidedZoneNode) else {
            print("Collision with non-answer zone object, or zone already processed.")
            return
        }

        guard activeAnswerZones.contains(where: { $0 === answerZoneContainer }) else {
            print("This answer zone has already been processed or cleaned up.")
            return
        }
        
        let wasCorrect = answerZoneContainer.isCorrect
        
        stopTimer()
        cleanupCurrentQuestion()

        if wasCorrect {
            infoViewModel.score += 10
            infoViewModel.gameMessage = "Correct! +10 Points"
        } else {
            infoViewModel.health -= 1
            infoViewModel.gameMessage = "Wrong! -1 Health"
            if infoViewModel.health <= 0 {
                gameOver()
                return
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.infoViewModel.gameMessage = ""
            self?.nextQuestion()
        }
    }
    
    private func findAnswerZoneContainer(for node: SCNNode) -> AnswerZoneNode? {
        var currentNode: SCNNode? = node
        while currentNode != nil {
            if let answerZone = currentNode as? AnswerZoneNode {
                return answerZone
            }
            currentNode = currentNode?.parent
        }
        return nil
    }

    private func startTimer() {
        infoViewModel.timeLeft = questionTimeLimit
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }

    private func updateTimer() {
        if infoViewModel.timeLeft > 0 {
            infoViewModel.timeLeft -= 1
        } else {
            handleTimeout()
        }
    }

    private func handleTimeout() {
        guard !activeAnswerZones.isEmpty else {
            print("Timer fired but no active answer zones. Likely already handled.")
            stopTimer()
            return
        }

        stopTimer()
        cleanupCurrentQuestion()

        infoViewModel.health -= 1
        infoViewModel.gameMessage = "Time's Up! -1 Health"
        
        if infoViewModel.health <= 0 {
            gameOver()
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.infoViewModel.gameMessage = ""
            self?.nextQuestion()
        }
    }
    
    private func cleanupCurrentQuestion() {
        stopTimer()
        activeAnswerZones.forEach { $0.removeFromParentNode() }
        activeAnswerZones.removeAll()
        // Do NOT clear initialSpawnPositionForFirstQuestion here,
        // it should only be cleared after its first use in nextQuestion().
    }

    private func gameOver() {
        cleanupCurrentQuestion()
        infoViewModel.isGameOver = true
        if questions.isEmpty && infoViewModel.currentQuestionText.contains("Error") {
             // Keep the error message
        } else {
            infoViewModel.currentQuestionText = "Game Over!"
        }
        infoViewModel.gameMessage = "Final Score: \(infoViewModel.score)"
        print("GAME OVER. Final Score: \(infoViewModel.score)")
    }
}
