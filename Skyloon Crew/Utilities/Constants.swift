import Foundation
import SwiftUI

enum Constants {
    // App information
    static let appName = "Skyloon Game Host"
    static let appVersion = "1.0.0"
    
    // Network configuration
    static let serviceType = "skyloon"
    static let maxPlayers = 4
    static let connectionTimeout: TimeInterval = 30
    
    // UI Configuration
    struct UI {
        // Colors
        static let tileBorderColor = Color.gray.opacity(0.3)
        static let backgroundColor = Color(NSColor.windowBackgroundColor)
        static let accentColor = Color.blue
        
        // Layout
        static let tileCornerRadius: CGFloat = 10
        static let contentPadding: CGFloat = 20
        static let tilePadding: CGFloat = 16
        static let standardSpacing: CGFloat = 20
        
        // Animations
        static let standardAnimation = Animation.easeInOut(duration: 0.3)
    }
    
}
