// SwiftUI_UI/InfoViewModel.swift
import SwiftUI
import Combine

class InfoViewModel: ObservableObject {
    @Published var score: Int = 0
    @Published var health: Int = 3
    @Published var currentQuestionText: String = "Loading question..."
    @Published var timeLeft: Int = 30
    @Published var isGameOver: Bool = false
    @Published var gameMessage: String = "" 
}
