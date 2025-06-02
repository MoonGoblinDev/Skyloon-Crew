//
//  Enum+Sound.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 01/06/25.
//


// MARK: - Sound Types
enum SoundType {
    case ui
    case sfx
    case bgm
}

enum UISounds: String, CaseIterable {
    case buttonClick = "button_click"
    case buttonHover = "button_hover"
    case menuOpen = "menu_open"
    case menuClose = "menu_close"
    case notification = "notification"
    case error = "error"
    case success = "success"
}

enum SFXSounds: String, CaseIterable {
    case explosion = "explosion"
    case laser = "laser"
    case pickup = "pickup"
    case jump = "jump"
    case footstep = "footstep"
    case sword = "sword"
    case magic = "magic"
}

enum BGMSounds: String, CaseIterable {
    case mainMenu = "main_menu"
    case gameplay = "gameplay"
    case wind = "wind"
    case victory = "victory"
    case gameOver = "game_over"
}
