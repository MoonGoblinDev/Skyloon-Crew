// GameLogic/GameManager.swift
import SceneKit
import Combine

class GameManager {
    weak var scene: SCNScene?
    weak var boatNode: SCNNode? // To get player's position
    weak var cameraNode: SCNNode? // To help with text orientation if not using billboard
    var infoViewModel: InfoViewModel // Published properties for UI

    private var questions: [Question] = []
    private var currentQuestionIndex: Int = -1
    private var activeAnswerZones: [AnswerZoneNode] = []

    private var gameTimer: Timer?
    private let questionTimeLimit: Int = 30 // Seconds

    // Colors for answer zones - ensure you have enough for max answers
    private let answerZoneColors: [NSColor] = [
        .systemRed, .systemGreen, .systemBlue, .systemYellow, .systemPurple, .systemOrange
    ]

    init(scene: SCNScene, boatNode: SCNNode, cameraNode: SCNNode, infoViewModel: InfoViewModel) {
        self.scene = scene
        self.boatNode = boatNode
        self.cameraNode = cameraNode
        self.infoViewModel = infoViewModel
        loadQuestions()
    }

    private func loadQuestions() {
        // Hardcode some questions for now. In a real game, load from a file (JSON, Plist).
        questions = [
            Question(text: "What is 2 + 2?", answers: ["3", "4", "5"], correctAnswer: "4"),
            Question(text: "Capital of France?", answers: ["Berlin", "Madrid", "Paris"], correctAnswer: "Paris"),
            Question(text: "Which planet is red?", answers: ["Mars", "Venus", "Jupiter"], correctAnswer: "Mars"),
            Question(text: "What is H2O?", answers: ["Salt", "Sugar", "Water"], correctAnswer: "Water")
        ]
        questions.shuffle() // Randomize question order
    }

    func startGame() {
        infoViewModel.health = 3
        infoViewModel.score = 0
        infoViewModel.isGameOver = false
        infoViewModel.gameMessage = ""
        currentQuestionIndex = -1 // So nextQuestion starts from 0
        nextQuestion()
    }

    func nextQuestion() {
        guard let scene = scene, let boatNode = boatNode else { return }
        
        cleanupCurrentQuestion() // Remove old zones and stop timer

        currentQuestionIndex += 1
        if currentQuestionIndex >= questions.count {
            // Game finished all questions, or could loop/show score
            infoViewModel.currentQuestionText = "Game Complete! Final Score: \(infoViewModel.score)"
            infoViewModel.isGameOver = true // Or a different state for "won"
            infoViewModel.timeLeft = 0
            return
        }
        if infoViewModel.health <= 0 {
            gameOver()
            return
        }

        let question = questions[currentQuestionIndex]
        infoViewModel.currentQuestionText = question.text
        spawnAnswerZones(for: question, around: boatNode.presentation.worldPosition)
        startTimer()
    }

    private func spawnAnswerZones(for question: Question, around center: SCNVector3) {
        guard let scene = scene else { return }
        activeAnswerZones.removeAll() // Clear any previous (should be done by cleanup)

        let spawnDistance: Float = 30.0 // How far from the player center
        let angleStep = (2.0 * .pi) / Float(question.answers.count) // Distribute answers in a circle

        var availableColors = answerZoneColors
        availableColors.shuffle()

        for (index, answerText) in question.answers.enumerated() {
            let angle = Float(index) * angleStep
            let x = center.x + CGFloat(spawnDistance) * CGFloat(cos(angle))
            let z = center.z + CGFloat(spawnDistance) * CGFloat(sin(angle))
            // Keep Y at a manageable height, e.g., slightly above water if you have water
            let y = center.y // Or a fixed Y like 2.0

            let position = SCNVector3(x, y, z)
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
        // Find the AnswerZoneNode from the actual SCNNode that was hit (which might be the sphere)
        guard let answerZoneContainer = findAnswerZoneContainer(for: collidedZoneNode) else {
            print("Collision with non-answer zone object, or zone already processed.")
            return
        }

        // Prevent processing the same collision multiple times if events fire rapidly
        guard activeAnswerZones.contains(where: { $0 === answerZoneContainer }) else {
            print("This answer zone has already been processed.")
            return
        }
        
        stopTimer()

        if answerZoneContainer.isCorrect {
            infoViewModel.score += 10
            infoViewModel.gameMessage = "Correct! +10 Points"
            // Play a success sound or animation
        } else {
            infoViewModel.health -= 1
            infoViewModel.gameMessage = "Wrong! -1 Health"
            // Play a failure sound or animation
            if infoViewModel.health <= 0 {
                gameOver()
                return // Don't proceed to next question if game over
            }
        }
        
        // Show message briefly then proceed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.infoViewModel.gameMessage = "" // Clear message
            self?.nextQuestion()
        }
    }
    
    // Helper to find the main AnswerZoneNode from a child node (like the sphere)
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
        gameTimer?.invalidate() // Invalidate any existing timer
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
        stopTimer()
        infoViewModel.health -= 1
        infoViewModel.gameMessage = "Time's Up! -1 Health"
        // Play timeout sound
        
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
    }

    private func gameOver() {
        cleanupCurrentQuestion()
        infoViewModel.isGameOver = true
        infoViewModel.currentQuestionText = "Game Over!"
        infoViewModel.gameMessage = "Final Score: \(infoViewModel.score)"
        // Optionally, navigate to a game over screen or show a prominent UI message
        print("GAME OVER. Final Score: \(infoViewModel.score)")
    }

    // This function is no longer strictly needed if SCNBillboardConstraint is used on text.
    // Kept for reference if manual orientation was ever required.
    // func updateActiveAnswerZoneTextOrientations() {
    //     guard let cameraNode = cameraNode else { return }
    //     let cameraPosition = cameraNode.presentation.worldPosition
    //     activeAnswerZones.forEach { zone in
    //         // zone.makeTextFaceCamera(cameraPosition: cameraPosition) // If AnswerZoneNode had this method
    //     }
    // }
}
