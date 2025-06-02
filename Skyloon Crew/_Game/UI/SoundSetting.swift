//
//  SoundSetting.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 02/06/25.
//

import SwiftUI

struct SoundSettingsView: View {
    @ObservedObject var soundManager = GameSoundManager.shared
    
    var body: some View {
        Form {
            Section("Master Volume") {
                HStack {
                    Text("Volume")
                    Slider(value: $soundManager.masterVolume, in: 0...1)
                    Button(soundManager.isMasterMuted ? "🔇" : "🔊") {
                        soundManager.isMasterMuted.toggle()
                    }
                }
            }
            
            Section("UI Sounds") {
                HStack {
                    Text("Volume")
                    Slider(value: $soundManager.uiVolume, in: 0...1)
                    Button(soundManager.isUIMuted ? "🔇" : "🔊") {
                        soundManager.isUIMuted.toggle()
                    }
                }
                
                Button("Test UI Sound") {
                    soundManager.playUI(.buttonClick)
                }
            }
            
            Section("Sound Effects") {
                HStack {
                    Text("Volume")
                    Slider(value: $soundManager.sfxVolume, in: 0...1)
                    Button(soundManager.isSFXMuted ? "🔇" : "🔊") {
                        soundManager.isSFXMuted.toggle()
                    }
                }
                
                Button("Test SFX Sound") {
                    soundManager.playSFX(.explosion)
                }
            }
            
            Section("Background Music") {
                HStack {
                    Text("Volume")
                    Slider(value: $soundManager.bgmVolume, in: 0...1)
                    Button(soundManager.isBGMMuted ? "🔇" : "🔊") {
                        soundManager.isBGMMuted.toggle()
                    }
                }
                
                HStack {
                    Button("Play BGM") {
                        soundManager.playBGM(.mainMenu)
                    }
                    
                    Button("Stop BGM") {
                        soundManager.stopBGM()
                    }
                }
            }
        }
        .onAppear {
            soundManager.loadSettings()
        }
        .onDisappear {
            soundManager.saveSettings()
        }
    }
}

#Preview {
    SoundSettingsView()
}
