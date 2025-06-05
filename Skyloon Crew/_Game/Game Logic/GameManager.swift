// GameLogic/GameManager.swift
import SceneKit
import Combine

class GameManager {
    weak var scene: SCNScene?
    weak var boatNode: SCNNode?
    weak var cameraNode: SCNNode?
    var infoViewModel: InfoViewModel

    private let questionFileName: String // This will be "mix_all_categories" or a specific file name
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

    // List of all individual category JSON files (without .json extension)
    // Ensure "questions.json" (your original default/mix) is NOT listed here
    // if "mix_all_categories" is meant to load only the *specific* categories.
    // If your original "questions.json" was a small set and you want to include it in the mix, add "questions" to this list.
    private let allCategoryFiles: [String] = [
        "trivia_questions",
        "positive_thinking_questions",
        "movies_questions",
        "gen_z_questions",
        "mathematics_questions"
        // Add "questions" here if you also want to include the original `questions.json` in the mix.
        // For now, I'm assuming "mix_all_categories" means all *other* specific categories.
    ]


    init(scene: SCNScene, boatNode: SCNNode, cameraNode: SCNNode, infoViewModel: InfoViewModel, questionFileName: String) {
        self.scene = scene
        self.boatNode = boatNode
        self.cameraNode = cameraNode
        self.infoViewModel = infoViewModel
        self.questionFileName = questionFileName
        loadQuestions()
    }

    private func loadQuestions() {
        var allLoadedQuestions: [Question] = []
        var successfullyLoadedAnyFile = false
        var loadErrors: [String] = []

        if self.questionFileName == "mix_all_categories" {
            print("Loading questions for MIX mode from files: \(allCategoryFiles.joined(separator: ", "))")

            for fileName in allCategoryFiles {
                guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
                    let errorMsg = "Error: Question file '\(fileName).json' not found in bundle for MIX mode."
                    print(errorMsg)
                    loadErrors.append(errorMsg)
                    continue // Skip to the next file
                }

                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let categoryQuestions = try decoder.decode([Question].self, from: data)
                    allLoadedQuestions.append(contentsOf: categoryQuestions)
                    successfullyLoadedAnyFile = true // Mark true if at least one file loads
                    print("Successfully loaded \(categoryQuestions.count) questions from '\(fileName).json' for MIX mode.")
                } catch {
                    let errorMsg = "Error loading or decoding '\(fileName).json' for MIX mode: \(error)"
                    print(errorMsg)
                    loadErrors.append(errorMsg)
                }
            }
        } else { // Single file mode (for specific categories like Trivia, Math, etc.)
            guard let url = Bundle.main.url(forResource: self.questionFileName, withExtension: "json") else {
                let errorMsg = "Error: Question file '\(self.questionFileName).json' not found in bundle."
                print(errorMsg)
                self.questions = [] // Ensure questions array is empty on failure
                infoViewModel.currentQuestionText = "Error: Question data not found for \(self.questionFileName)."
                infoViewModel.isGameOver = true
                return
            }

            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                allLoadedQuestions = try decoder.decode([Question].self, from: data)
                successfullyLoadedAnyFile = true // Mark true as we expect this single file to load
                print("Successfully loaded \(allLoadedQuestions.count) questions from '\(self.questionFileName).json'.")
            } catch {
                let errorMsg = "Error loading or decoding '\(self.questionFileName).json': \(error)"
                print(errorMsg)
                loadErrors.append(errorMsg)
                // allLoadedQuestions will remain empty if decoding fails
            }
        }

        // After attempting to load all necessary files
        if !successfullyLoadedAnyFile || allLoadedQuestions.isEmpty {
            self.questions = []
            let finalErrorMsg = loadErrors.isEmpty ? "No questions found." : loadErrors.joined(separator: "\n")
            let modeNameForError = self.questionFileName == "mix_all_categories" ? "MIX Mode" : self.questionFileName
            infoViewModel.currentQuestionText = "Error loading questions for \(modeNameForError). \(finalErrorMsg)"
            infoViewModel.isGameOver = true
            print("Failed to load any questions for mode '\(self.questionFileName)'. Errors: \(finalErrorMsg)")
        } else {
            self.questions = allLoadedQuestions
            self.questions.shuffle()
            print("Total questions loaded and shuffled for mode '\(self.questionFileName)': \(self.questions.count)")
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
        print("GameManager.startGame: Initial spawn params set - Pos: \(String(describing: initialBoatPosition)), Ori: \(String(describing: initialBoatOrientation)) for question source: \(questionFileName)")


        if questions.isEmpty { // This implies loading failed or the file(s) were empty
            // loadQuestions() might have already set an error message.
            if !infoViewModel.currentQuestionText.contains("Error") { // Check if an error is already set
                 infoViewModel.currentQuestionText = "No questions available for \(questionFileName)."
            }
            infoViewModel.isGameOver = true // Ensure game over state is set
            print("No questions available to start the game from source: \(questionFileName).")
            return
        }
        
        // Questions should already be shuffled by loadQuestions if successful.
        // If playing multiple times without re-initializing GameManager, consider re-shuffling here.
        // For now, loadQuestions handles the initial shuffle.
        // self.questions.shuffle()

        nextQuestion()
    }

    func nextQuestion() {
        guard scene != nil else { return }
        
        cleanupCurrentQuestion()

        if infoViewModel.health <= 0 {
            gameOver()
            return
        }

        currentQuestionIndex += 1
        if currentQuestionIndex >= questions.count {
            if questions.isEmpty { // Should have been caught by startGame, but as a safeguard
                let modeName = self.questionFileName == "mix_all_categories" ? "MIX Mode" : self.questionFileName
                infoViewModel.currentQuestionText = "No questions available in \(modeName). Game Over."
                gameOver()
                return
            }
            print("All questions answered from \(questionFileName). Restarting question cycle for this set.")
            currentQuestionIndex = 0
            questions.shuffle() // Re-shuffle when cycling through
            infoViewModel.gameMessage = "New round of questions!"
             DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                 self?.infoViewModel.gameMessage = ""
             }
        }

        guard questions.indices.contains(currentQuestionIndex) else {
            print("Error: currentQuestionIndex is out of bounds after attempting to loop for \(questionFileName).")
            gameOver()
            return
        }

        let question = questions[currentQuestionIndex]
        infoViewModel.currentQuestionText = question.text

        let spawnRefPos: SCNVector3
        var boatWorldForward: SCNVector3
        let boatWorldRight: SCNVector3

        if let initialPos = self.initialSpawnPositionForFirstQuestion,
           let initialOri = self.initialSpawnOrientationForFirstQuestion,
           currentQuestionIndex == 0 {
            
            print("Spawning FIRST question zones using initial reset position: \(initialPos)")
            spawnRefPos = initialPos
            
            let q = initialOri
            boatWorldForward = SCNVector3(2 * (q.x * q.z + q.w * q.y),
                                          2 * (q.y * q.z - q.w * q.x),
                                          1 - 2 * (q.x * q.x + q.y * q.y)).normalized()
            boatWorldForward = SCNVector3(-boatWorldForward.x, -boatWorldForward.y, -boatWorldForward.z)

            boatWorldRight = SCNVector3(1 - 2 * (q.y * q.y + q.z * q.z),
                                         2 * (q.x * q.y + q.w * q.z),
                                         2 * (q.x * q.z - q.w * q.y)).normalized()

            self.initialSpawnPositionForFirstQuestion = nil
            self.initialSpawnOrientationForFirstQuestion = nil
            print("Initial spawn params consumed and cleared.")

        } else {
            guard let boat = self.boatNode else {
                print("Error: Boat node not available for subsequent question spawning.")
                gameOver()
                return
            }
            print("Spawning zones based on CURRENT boat presentation node. Pos: \(boat.presentation.worldPosition)")
            spawnRefPos = boat.presentation.worldPosition
            boatWorldForward = boat.presentation.worldFront
            boatWorldRight = boat.presentation.worldRight
        }

        spawnAnswerZones(for: question,
                         spawnReferencePoint: spawnRefPos,
                         boatWorldForward: boatWorldForward,
                         boatWorldRight: boatWorldRight)
        startTimer()
    }

    private func spawnAnswerZones(for question: Question,
                                  spawnReferencePoint boatPos: SCNVector3,
                                  boatWorldForward: SCNVector3,
                                  boatWorldRight: SCNVector3) {
        guard let scene = scene else { return }
        activeAnswerZones.removeAll()

        var horizontalForward = SCNVector3(boatWorldForward.x, 0, boatWorldForward.z).normalized()
        if horizontalForward.length() < 0.001 {
            horizontalForward = SCNVector3(0, 0, -1)
        }
        var horizontalRight = SCNVector3(boatWorldRight.x, 0, boatWorldRight.z).normalized()
        if horizontalRight.length() < 0.001 {
            horizontalRight = SCNVector3.cross(SCNVector3(0,1,0), horizontalForward).normalized()
            if horizontalRight.length() < 0.001 { horizontalRight = SCNVector3(1,0,0) }
        }

        let spawnDistanceInFront: Float = 300.0
        let spacingBetweenZoneCenters: Float = Float(AnswerZoneNode.sphereRadius * 5.0 + AnswerZoneNode.sphereRadius * 0.5)
        
        var answerOptions: [(text: String, isCorrect: Bool)] = []
        for answerText in question.answers {
            answerOptions.append((text: answerText, isCorrect: (answerText == question.correctAnswer)))
        }
        answerOptions.shuffle()
        
        let numberOfAnswers = Float(answerOptions.count)
        
        let zoneLineY = boatPos.y
        let lineCenterPoint = SCNVector3(
            boatPos.x + horizontalForward.x * CGFloat(spawnDistanceInFront),
            zoneLineY,
            boatPos.z + horizontalForward.z * CGFloat(spawnDistanceInFront)
        )

        let totalLineWidth = (numberOfAnswers - 1.0) * spacingBetweenZoneCenters
        let offsetForFirstZone = -totalLineWidth / 2.0

        var availableColors = answerZoneColors
        availableColors.shuffle()

        for (index, answerOption) in answerOptions.enumerated() {
            let displacementFromLineCenter = offsetForFirstZone + Float(index) * spacingBetweenZoneCenters
            
            let position = SCNVector3(
                lineCenterPoint.x + horizontalRight.x * CGFloat(displacementFromLineCenter),
                zoneLineY,
                lineCenterPoint.z + horizontalRight.z * CGFloat(displacementFromLineCenter)
            )
            
            let color = availableColors[index % availableColors.count]

            let answerZone = AnswerZoneNode(answerText: answerOption.text,
                                            isCorrect: answerOption.isCorrect,
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
        // Keep existing error message if game over was due to loading failure
        if !(infoViewModel.currentQuestionText.lowercased().contains("error") && questions.isEmpty) {
             infoViewModel.currentQuestionText = "Game Over!"
        }
        infoViewModel.gameMessage = "Final Score: \(infoViewModel.score)"
        print("GAME OVER. Final Score: \(infoViewModel.score)")
    }
}
