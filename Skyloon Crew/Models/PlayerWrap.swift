


//
//  Untitled.swift
//  Challenge2
//
//  Created by Reza Juliandri on 22/05/25.
//

import Foundation

struct PlayerWrap: Codable {
    var id = UUID()
    var name: String
    var colorHex: String
    var character: String
}


enum CharactersEnum: String, CaseIterable{
    case black_bear = "Black Bear";
    case panda = "Panda";
    case brown_bear = "Brown Bear";
    case polar_bear = "Polar Bear";
    case red_panda = "Red Panda";
    case koala = "Koala";
    
    func getImage() -> String {
        switch self {
            case .panda:
            return "character_panda"
        default:
            return "character_bear"
        }
    }
}

