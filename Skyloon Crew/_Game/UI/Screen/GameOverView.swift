//
//  GameOverView.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 02/06/25.
//

import SwiftUI

struct GameOverView: View {
    @ObservedObject var connectionManager: ConnectionManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0)
            GameCanvas(title:"Game Over") {
                VStack() {
                    HStack{
                        ForEach(connectionManager.players) { player in
                            PlayerStats(name: player.playerName, swing: player.totalSwing)
                        }
                    }
                    HStack{
                        GameButton(
                            state: GameButtonState.grey,
                            action: {

                                GameSoundManager.shared.playUI(.success)
                                GameSoundManager.shared.stopBGM(fadeOut: true)
                            }) {
                            HStack {
                                Text.gameFont("Restart Game", fontSize: 30 )
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        
                        GameButton(
                            state: GameButtonState.grey,
                            action: {

                                GameSoundManager.shared.playUI(.success)
                                GameSoundManager.shared.stopBGM(fadeOut: true)
                            }) {
                            HStack {
                                Text.gameFont("Leaderboard", fontSize: 30 )
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        
                        GameButton(
                            state: GameButtonState.grey,
                            action: {

                                GameSoundManager.shared.playUI(.success)
                                GameSoundManager.shared.stopBGM(fadeOut: true)
                            }) {
                            HStack {
                                Text.gameFont("Change Game Mode", fontSize: 30 )
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        
                        GameButton(
                            state: GameButtonState.grey,
                            action: {

                                GameSoundManager.shared.playUI(.success)
                                GameSoundManager.shared.stopBGM(fadeOut: true)
                            }) {
                            HStack {
                                Text.gameFont("Back to title screen", fontSize: 30 )
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                    }
                    

                }
                .padding()
            }
            .padding()
        }
    }
}

struct PlayerStats: View {
    let name: String
    let swing: Int
    
    var body: some View {
        VStack {
            Circle()
                .frame(width: 80, height: 80)
                .padding()
            Text.gameFont(name)
            Text.gameFont("Total Swings: \(swing)", fontSize: 20)
        }
        .frame(width: 200, height: 300)
        .background(
            Image("UI_Bar")
                .resizable(
                    capInsets: EdgeInsets(top: 29, leading: 29, bottom: 29, trailing: 29),
                    resizingMode: .stretch
                )
        )
        .padding()
        
        
    }
}


struct GameOverPreview: PreviewProvider {
    static var previews: some View {
        let manager = ConnectionManager()
        GameOverView(connectionManager: manager)
            .frame(width: 1300, height: 800).previewDisplayName("1200x800")
    }
}
