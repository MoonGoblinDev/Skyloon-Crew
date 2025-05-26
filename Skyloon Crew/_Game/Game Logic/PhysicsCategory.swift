// GameLogic/PhysicsCategory.swift
import Foundation // Not strictly needed for this struct, but good practice

struct PhysicsCategory {
    static let none       : Int = 0       // No category / Do not collide
    static let boat       : Int = 1 << 0  // 00000001 in binary (value 1)
    static let answerZone : Int = 1 << 1  // 00000010 in binary (value 2)
    static let all        : Int = Int.max // Collide with everything
}
