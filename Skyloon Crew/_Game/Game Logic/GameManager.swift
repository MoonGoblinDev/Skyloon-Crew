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

    func startGame() {
        infoViewModel.health = 3
        infoViewModel.score = 0
        infoViewModel.isGameOver = false
        infoViewModel.gameMessage = ""
        currentQuestionIndex = -1

        if questions.isEmpty {
            loadQuestions()
        } else {
            questions.shuffle()
        }

        if questions.isEmpty {
            print("No questions available to start the game.")
            infoViewModel.currentQuestionText = "No questions available to start the game."
            infoViewModel.isGameOver = true
            return
        }
        
        nextQuestion()
    }

    func nextQuestion() {
        guard let scene = scene, let boatNode = boatNode else { return }
        
        cleanupCurrentQuestion()

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
        spawnAnswerZones(for: question, aroundBoat: boatNode) // Pass the boatNode
        startTimer()
    }

    private func spawnAnswerZones(for question: Question, aroundBoat boat: SCNNode) {
        guard let scene = scene else { return }
        activeAnswerZones.removeAll()

        let boatPos = boat.presentation.worldPosition
        let boatForward = boat.presentation.worldFront // -Z axis in world space
        let boatRight = boat.presentation.worldRight   // +X axis in world space

        // Project to XZ plane for horizontal layout, and normalize
        var horizontalForward = SCNVector3(boatForward.x, 0, boatForward.z).normalized()
        if horizontalForward.length() < 0.001 { // Avoid division by zero if boat points straight up/down
            horizontalForward = SCNVector3(0, 0, -1) // Default forward
        }
        var horizontalRight = SCNVector3(boatRight.x, 0, boatRight.z).normalized()
        if horizontalRight.length() < 0.001 {
            horizontalRight = SCNVector3(1, 0, 0) // Default right
        }

        let spawnDistanceInFront: Float = 300.0 // Increased distance for larger zones
        // Spacing = diameter of sphere + a gap (e.g., 1/2 radius as gap)
        let spacingBetweenZoneCenters: Float = Float(AnswerZoneNode.sphereRadius * 4.0 + AnswerZoneNode.sphereRadius * 0.5)
        
        let numberOfAnswers = Float(question.answers.count)
        
        // Y position for the center of the answer zones.
        // Let's keep them at the boat's current Y level for now.
        // Player will need to adjust boat's height to reach them.
        let zoneLineY = boatPos.y

        // Calculate the center point of the line of answers
        let lineCenterPoint = SCNVector3(
            boatPos.x + horizontalForward.x * CGFloat(spawnDistanceInFront),
            zoneLineY,
            boatPos.z + horizontalForward.z * CGFloat(spawnDistanceInFront)
        )

        let totalLineWidth = (numberOfAnswers - 1.0) * spacingBetweenZoneCenters
        let offsetForFirstZone = -totalLineWidth / 2.0 // Start from the left

        var availableColors = answerZoneColors
        availableColors.shuffle()

        for (index, answerText) in question.answers.enumerated() {
            let displacementFromLineCenter = offsetForFirstZone + Float(index) * spacingBetweenZoneCenters
            
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
    }

    private func gameOver() {
        cleanupCurrentQuestion()
        infoViewModel.isGameOver = true
        if questions.isEmpty && infoViewModel.currentQuestionText.contains("Error") {
        } else {
            infoViewModel.currentQuestionText = "Game Over!"
        }
        infoViewModel.gameMessage = "Final Score: \(infoViewModel.score)"
        print("GAME OVER. Final Score: \(infoViewModel.score)")
    }
}
