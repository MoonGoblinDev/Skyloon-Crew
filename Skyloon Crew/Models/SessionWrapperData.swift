//
//  SessionWrapperData.swift
//  Challenge2
//
//  Created by Reza Juliandri on 22/05/25.
//

import Foundation

struct SessionWrapperData: Codable{
    var id: UUID = UUID()
    var player: PlayerWrap
    var gyro: GyroData
    var device: String
}

