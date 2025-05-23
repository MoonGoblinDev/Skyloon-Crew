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
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            print("Error: questions.json not found in bundle.")
            self.questions = [] // Ensure questions list is empty if file not found
            // Optionally, update UI to inform user
            infoViewModel.currentQuestionText = "Error: Question data not found."
            infoViewModel.isGameOver = true // Or a specific error state
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.questions = try decoder.decode([Question].self, from: data)
            print("Successfully loaded \(self.questions.count) questions from JSON.")
            // Shuffle once after loading
            self.questions.shuffle()
        } catch {
            print("Error loading or decoding questions.json: \(error)")
            self.questions = [] // Ensure questions list is empty on error
            infoViewModel.currentQuestionText = "Error: Could not load questions."
            infoViewModel.isGameOver = true // Or a specific error state
        }
    }

    func startGame() {
        infoViewModel.health = 3
        infoViewModel.score = 0
        infoViewModel.isGameOver = false
        infoViewModel.gameMessage = ""
        currentQuestionIndex = -1 // So nextQuestion starts from 0

        // Re-load and/or re-shuffle questions if needed, or ensure they are loaded.
        if questions.isEmpty { // Attempt to load again if empty, e.g., if a previous attempt failed but might now succeed.
            loadQuestions()
        } else {
            questions.shuffle() // Re-shuffle for a new game
        }

        if questions.isEmpty {
            // If still empty after attempt, game cannot start.
            print("No questions available to start the game.")
            infoViewModel.currentQuestionText = "No questions available to start the game."
            infoViewModel.isGameOver = true
            return
        }
        
        nextQuestion()
    }

    func nextQuestion() {
        guard let scene = scene, let boatNode = boatNode else { return }
        
        cleanupCurrentQuestion() // Remove old zones and stop timer

        if infoViewModel.health <= 0 {
            gameOver()
            return
        }

        currentQuestionIndex += 1
        if currentQuestionIndex >= questions.count {
            if questions.isEmpty {
                // This case should ideally be caught by startGame or loadQuestions
                infoViewModel.currentQuestionText = "No questions available. Game Over."
                gameOver()
                return
            }
            // All questions answered, loop back to the beginning
            print("All questions answered. Restarting question cycle.")
            currentQuestionIndex = 0
            questions.shuffle() // Re-shuffle for variety on loop
            infoViewModel.gameMessage = "New round of questions!"
             DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                 self?.infoViewModel.gameMessage = ""
             }
        }

        // Ensure we still have a valid index after potential looping/shuffling
        guard questions.indices.contains(currentQuestionIndex) else {
            print("Error: currentQuestionIndex is out of bounds after attempting to loop.")
            gameOver() // Or handle as a critical error
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
        guard let answerZoneContainer = findAnswerZoneContainer(for: collidedZoneNode) else {
            print("Collision with non-answer zone object, or zone already processed.")
            return
        }

        // Check if this specific zone is still considered active.
        // This needs to be done before cleanup.
        guard activeAnswerZones.contains(where: { $0 === answerZoneContainer }) else {
            print("This answer zone has already been processed or cleaned up.")
            return
        }
        
        // --- Immediate action part ---
        let wasCorrect = answerZoneContainer.isCorrect // Store result
        // let chosenAnswerText = answerZoneContainer.answerText // Store text for message (optional)
        
        stopTimer() // Stop timer related to the current question
        cleanupCurrentQuestion() // Remove all answer zones IMMEDIATELY

        // --- Process result and UI update part ---
        if wasCorrect {
            infoViewModel.score += 10
            infoViewModel.gameMessage = "Correct! +10 Points"
            // Play a success sound or animation
        } else {
            infoViewModel.health -= 1
            infoViewModel.gameMessage = "Wrong! -1 Health"
            // Play a failure sound or animation
            if infoViewModel.health <= 0 {
                gameOver() // gameOver also calls cleanup, but it's fine.
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
        // Check if zones are still active; if not, timeout might be for an already answered question.
        guard !activeAnswerZones.isEmpty else {
            print("Timer fired but no active answer zones. Likely already handled.")
            stopTimer()
            return
        }

        stopTimer()
        cleanupCurrentQuestion() // Clean up zones on timeout

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
        cleanupCurrentQuestion() // Ensure zones are cleared
        infoViewModel.isGameOver = true
        // If questions were empty, this message might be overwritten by loadQuestions/startGame.
        if questions.isEmpty && infoViewModel.currentQuestionText.contains("Error") {
             // Keep the error message
        } else {
            infoViewModel.currentQuestionText = "Game Over!"
        }
        infoViewModel.gameMessage = "Final Score: \(infoViewModel.score)"
        // Optionally, navigate to a game over screen or show a prominent UI message
        print("GAME OVER. Final Score: \(infoViewModel.score)")
    }
}
