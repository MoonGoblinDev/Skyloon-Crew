// GameLogic/Question.swift
import Foundation

struct Question: Identifiable, Decodable {
    let id: UUID
    let text: String
    let answers: [String]
    let correctAnswer: String 

    
    enum CodingKeys: String, CodingKey {
        case text
        case answers
        case correctAnswer
    }

    // Custom initializer for Decodable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode properties that exist in the JSON
        self.text = try container.decode(String.self, forKey: .text)
        self.answers = try container.decode([String].self, forKey: .answers)
        self.correctAnswer = try container.decode(String.self, forKey: .correctAnswer)
        
        
        self.id = UUID()

        // Perform validation after decoding all necessary fields
        guard self.answers.contains(self.correctAnswer) else {
            // Create a more specific decoding error context
            let errorContext = DecodingError.Context(codingPath: [CodingKeys.correctAnswer], // Or decoder.codingPath
                                                     debugDescription: "Correct answer '\(self.correctAnswer)' must be one of the provided answers: \(self.answers) for question: '\(self.text)'.")
            throw DecodingError.dataCorrupted(errorContext)
        }
    }

    // Custom init for programmatic creation (e.g., for testing or defaults if JSON fails)
    // This initializer is not directly used by JSONDecoder.
    init(id: UUID = UUID(), text: String, answers: [String], correctAnswer: String) {
        self.id = id
        self.text = text
        // Ensure the correct answer is one of the provided answers for programmatic creation
        guard answers.contains(correctAnswer) else {
            // For programmatic fatalError is acceptable as it's a developer error.
            fatalError("Correct answer '\(correctAnswer)' must be one of the provided answers: \(answers) for question: '\(text)'.")
        }
        self.answers = answers
        self.correctAnswer = correctAnswer
    }
}
