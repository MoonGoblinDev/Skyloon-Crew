import SwiftUI

struct GameColorScheme {
    // Backgrounds and UI Elements
    let primaryBackground = Color(hex: "FDF6EE") // Light cream background
    let secondaryBackground = Color(hex: "d5c1ac") // Dark grey for selected menu item
    let menuItemBackground = Color(hex: "F0E6D9") // Lighter cream for unselected menu items
    let menuText = Color(hex: "6B6B6B") // Dark grey for menu text
    let selectedMenuText = Color(hex: "FFFFFF") // White for selected menu text

    // Map Specific Colors
    let mapGrass = Color(hex: "5DCB4A") // Bright green for grass
    let mapPath = Color(hex: "FAD89C") // Light sandy color for the path
    let mapBoardOutlineBlue = Color(hex: "00A0E9") // Blue outline for map elements
    let mapBoardOutlinePink = Color(hex: "EF478F") // Pink outline for map elements
    let mapBoardOutlineRed = Color(hex: "E5332A") // Red outline for map elements
    let mapBoardOutlineYellow = Color(hex: "FCE02E") // Yellow outline for map elements

    // Accent Colors
    let accentRed = Color(hex: "E60012") // Bright red for icons and highlights (like the "!" and tab indicator")
    let accentPink = Color(hex: "EE318C") // Pink for the "!" icon background
    let accentYellowStar = Color(hex: "FFD700") // Yellow for the star icon

    // Text Colors
    let primaryText = Color(hex: "4A4A4A") // Dark grey for general text (like "A board game..."")
    let tabTextActive = Color(hex: "E60012") // Red for active tab text
    let tabTextInactive = Color(hex: "787878") // Grey for inactive tab text

    // Other UI elements
    let bottomBarText = Color(hex: "505050") // Dark grey for bottom bar text ("Close Party Pad"")
    let controllerButtonIcon = Color(hex: "646464") // Grey for controller button icons (SL, SR")
}
