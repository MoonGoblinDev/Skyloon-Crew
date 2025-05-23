//
//  PlayerColumnView.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 22/05/25.
//
import SwiftUI

struct PlayerColumnView: View {
    @ObservedObject var player: Player

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 30)
                .strokeBorder(Color(hex: player.playerColorHex)!, lineWidth: 5)
                .background(RoundedRectangle(cornerRadius: 30).fill(.white))
                .frame(width: 120, height: 50)
                .overlay {
                    Text(player.playerName)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                }
            
            if player.connectionState == .disconnected{
                BearModelView(playerColor: .black)
                    .frame(width: 100, height: 150)
                    .cornerRadius(10)
                
                Text("Waiting")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .overlay(Capsule().stroke(.black, lineWidth: 2.5))
                    )
            }
            else if player.connectionState == .connected{
                BearModelView(playerColor: Color(hex: player.playerColorHex)!)
                    .frame(width: 100, height: 150)
                    .cornerRadius(10)
                
                Text("Ready")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .overlay(Capsule().stroke(.black, lineWidth: 2.5))
                    )
            }
            

        }
    }
}
