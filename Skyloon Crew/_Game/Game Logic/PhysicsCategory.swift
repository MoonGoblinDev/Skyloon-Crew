// GameLogic/PhysicsCategory.swift
import Foundation // Not strictly needed for this struct, but good practice

struct PhysicsCategory {
    static let none       : Int = 0       // No category / Do not collide
    static let boat       : Int = 1 << 0  // 00000001 in binary (value 1)
    static let answerZone : Int = 1 << 1  // 00000010 in binary (value 2)
    // Add other categories if needed, e.g.:
    // static let environment: Int = 1 << 2  // 00000100 in binary (value 4)
    // static let enemy      : Int = 1 << 3  // 00001000 in binary (value 8)
    // ... and so on, up to 32 unique categories (for UInt32 bitmasks)
    static let all        : Int = Int.max // Collide with everything
}
