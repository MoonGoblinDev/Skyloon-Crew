// GameLogic/Question.swift
import Foundation

struct Question: Identifiable {
    let id = UUID()
    let text: String
    let answers: [String] // All possible answer choices
    let correctAnswer: String // The text of the correct answer

    init(text: String, answers: [String], correctAnswer: String) {
        self.text = text
        // Ensure the correct answer is one of the provided answers
        guard answers.contains(correctAnswer) else {
            fatalError("Correct answer must be one of the provided answers.")
        }
        self.answers = answers
        self.correctAnswer = correctAnswer
    }
}
