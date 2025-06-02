//
//  GameSoundManager.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 01/06/25.
//

import AVFoundation
import SwiftUI


// MARK: - Game Sound Manager
class GameSoundManager: ObservableObject {
    static let shared = GameSoundManager()
    
    // Audio players for different sound types
    private var uiPlayers: [String: AVAudioPlayer] = [:]
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    private var bgmPlayer: AVAudioPlayer?
    
    // Volume controls (0.0 to 1.0)
    @Published var masterVolume: Float = 1.0 {
        didSet { updateAllVolumes() }
    }
    
    @Published var uiVolume: Float = 0.8 {
        didSet { updateUIVolumes() }
    }
    
    @Published var sfxVolume: Float = 0.9 {
        didSet { updateSFXVolumes() }
    }
    
    @Published var bgmVolume: Float = 0.6 {
        didSet { updateBGMVolume() }
    }
    
    // Mute controls
    @Published var isMasterMuted: Bool = false {
        didSet { updateAllVolumes() }
    }
    
    @Published var isUIMuted: Bool = false {
        didSet { updateUIVolumes() }
    }
    
    @Published var isSFXMuted: Bool = false {
        didSet { updateSFXVolumes() }
    }
    
    @Published var isBGMMuted: Bool = false {
        didSet { updateBGMVolume() }
    }
    
    // Current BGM tracking
    @Published var currentBGM: BGMSounds?
    private var bgmFadeTimer: Timer?
    
    private init() {
        setupAudioSession()
        preloadAllSounds()
    }
    private var isRunningInPreview: Bool {
            #if DEBUG
            return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            #else
            return false
            #endif
        }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
            #if os(iOS)
            do {
                try AVAudioSession.sharedInstance().setCategory(
                    .ambient,
                    mode: .default,
                    options: [.mixWithOthers, .duckOthers]
                )
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to setup audio session: \(error.localizedDescription)")
            }
            #endif
        }
    
    // MARK: - Preload Sounds
    func preloadAllSounds() {
        // Preload UI sounds
        
        guard !isRunningInPreview else {
                    print("🔇 Preview: Skipping sound preloading")
                    return
                }
        
        for sound in UISounds.allCases {
            preloadSound(named: sound.rawValue, type: .ui)
        }
        
        // Preload SFX sounds
        for sound in SFXSounds.allCases {
            preloadSound(named: sound.rawValue, type: .sfx)
        }
        
        // Preload BGM sounds
        for sound in BGMSounds.allCases {
            preloadSound(named: sound.rawValue, type: .bgm)
        }
    }
    
    private func preloadSound(named soundName: String, type: SoundType, fileExtension: String = "wav") {
        guard let path = Bundle.main.path(forResource: soundName, ofType: fileExtension) else {
            print("Sound file \(soundName).\(fileExtension) not found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            
            switch type {
            case .ui:
                player.volume = calculateVolume(base: uiVolume, type: .ui)
                uiPlayers[soundName] = player
            case .sfx:
                player.volume = calculateVolume(base: sfxVolume, type: .sfx)
                sfxPlayers[soundName] = player
            case .bgm:
                player.volume = calculateVolume(base: bgmVolume, type: .bgm)
                player.numberOfLoops = -1 // Loop indefinitely for BGM
                // Don't store BGM in a dictionary since we only play one at a time
                break
            }
        } catch {
            print("Could not preload sound \(soundName): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Play Sounds
    func playUI(_ sound: UISounds) {
        guard !isMasterMuted && !isUIMuted else { return }
        uiPlayers[sound.rawValue]?.play()
    }
    
    func playSFX(_ sound: SFXSounds) {
        guard !isMasterMuted && !isSFXMuted else { return }
        sfxPlayers[sound.rawValue]?.play()
    }
    
    func playBGM(_ sound: BGMSounds, fadeIn: Bool = true, fadeDuration: TimeInterval = 1.0) {
        guard !isMasterMuted && !isBGMMuted else { return }
        
        guard !isRunningInPreview else {
                    print("🔇 Preview: Skipping BGM ")
                    return
                }
        
        // Stop current BGM if playing
        if let currentBGM = currentBGM {
            stopBGM(fadeOut: fadeIn, fadeDuration: fadeDuration)
        }
        
        // Load and play new BGM
        guard let path = Bundle.main.path(forResource: sound.rawValue, ofType: "wav") else {
            print("BGM file \(sound.rawValue).wav not found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.prepareToPlay()
            
            if fadeIn {
                bgmPlayer?.volume = 0.0
                bgmPlayer?.play()
                fadeInBGM(to: calculateVolume(base: bgmVolume, type: .bgm), duration: fadeDuration)
            } else {
                bgmPlayer?.volume = calculateVolume(base: bgmVolume, type: .bgm)
                bgmPlayer?.play()
            }
            
            currentBGM = sound
        } catch {
            print("Could not play BGM \(sound.rawValue): \(error.localizedDescription)")
        }
    }
    
    func stopBGM(fadeOut: Bool = true, fadeDuration: TimeInterval = 1.0) {
        guard let player = bgmPlayer else { return }
        
        if fadeOut {
            fadeOutBGM(duration: fadeDuration) { [weak self] in
                player.stop()
                self?.currentBGM = nil
            }
        } else {
            player.stop()
            currentBGM = nil
        }
    }
    
    func pauseBGM() {
        bgmPlayer?.pause()
    }
    
    func resumeBGM() {
        guard !isMasterMuted && !isBGMMuted else { return }
        bgmPlayer?.play()
    }
    
    // MARK: - BGM Fade Effects
    private func fadeInBGM(to targetVolume: Float, duration: TimeInterval) {
        guard let player = bgmPlayer else { return }
        
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeIncrement = targetVolume / Float(steps)
        
        var currentStep = 0
        
        bgmFadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            player.volume = volumeIncrement * Float(currentStep)
            
            if currentStep >= steps {
                player.volume = targetVolume
                timer.invalidate()
            }
        }
    }
    
    private func fadeOutBGM(duration: TimeInterval, completion: @escaping () -> Void) {
        guard let player = bgmPlayer else {
            completion()
            return
        }
        
        let initialVolume = player.volume
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeDecrement = initialVolume / Float(steps)
        
        var currentStep = 0
        
        bgmFadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            player.volume = initialVolume - (volumeDecrement * Float(currentStep))
            
            if currentStep >= steps {
                player.volume = 0.0
                timer.invalidate()
                completion()
            }
        }
    }
    
    // MARK: - Volume Calculations
    private func calculateVolume(base: Float, type: SoundType) -> Float {
        if isMasterMuted { return 0.0 }
        
        switch type {
        case .ui:
            return isUIMuted ? 0.0 : masterVolume * base
        case .sfx:
            return isSFXMuted ? 0.0 : masterVolume * base
        case .bgm:
            return isBGMMuted ? 0.0 : masterVolume * base
        }
    }
    
    // MARK: - Volume Updates
    private func updateAllVolumes() {
        updateUIVolumes()
        updateSFXVolumes()
        updateBGMVolume()
    }
    
    private func updateUIVolumes() {
        let volume = calculateVolume(base: uiVolume, type: .ui)
        for player in uiPlayers.values {
            player.volume = volume
        }
    }
    
    private func updateSFXVolumes() {
        let volume = calculateVolume(base: sfxVolume, type: .sfx)
        for player in sfxPlayers.values {
            player.volume = volume
        }
    }
    
    private func updateBGMVolume() {
        let volume = calculateVolume(base: bgmVolume, type: .bgm)
        bgmPlayer?.volume = volume
    }
    
    // MARK: - Utility Methods
    func stopAllSounds() {
        // Stop all UI sounds
        for player in uiPlayers.values {
            player.stop()
        }
        
        // Stop all SFX sounds
        for player in sfxPlayers.values {
            player.stop()
        }
        
        // Stop BGM
        stopBGM(fadeOut: false)
    }
    
    func preloadCustomSound(named soundName: String, type: SoundType, fileExtension: String = "wav") {
        preloadSound(named: soundName, type: type, fileExtension: fileExtension)
    }
    
    func playCustomSound(named soundName: String, type: SoundType) {
        switch type {
        case .ui:
            guard !isMasterMuted && !isUIMuted else { return }
            uiPlayers[soundName]?.play()
        case .sfx:
            guard !isMasterMuted && !isSFXMuted else { return }
            sfxPlayers[soundName]?.play()
        case .bgm:
            print("Use playBGM() method for background music")
        }
    }
    
    // MARK: - Settings Persistence
    func saveSettings() {
        UserDefaults.standard.set(masterVolume, forKey: "masterVolume")
        UserDefaults.standard.set(uiVolume, forKey: "uiVolume")
        UserDefaults.standard.set(sfxVolume, forKey: "sfxVolume")
        UserDefaults.standard.set(bgmVolume, forKey: "bgmVolume")
        UserDefaults.standard.set(isMasterMuted, forKey: "isMasterMuted")
        UserDefaults.standard.set(isUIMuted, forKey: "isUIMuted")
        UserDefaults.standard.set(isSFXMuted, forKey: "isSFXMuted")
        UserDefaults.standard.set(isBGMMuted, forKey: "isBGMMuted")
    }
    
    func loadSettings() {
        masterVolume = UserDefaults.standard.object(forKey: "masterVolume") as? Float ?? 1.0
        uiVolume = UserDefaults.standard.object(forKey: "uiVolume") as? Float ?? 0.8
        sfxVolume = UserDefaults.standard.object(forKey: "sfxVolume") as? Float ?? 0.9
        bgmVolume = UserDefaults.standard.object(forKey: "bgmVolume") as? Float ?? 0.6
        isMasterMuted = UserDefaults.standard.bool(forKey: "isMasterMuted")
        isUIMuted = UserDefaults.standard.bool(forKey: "isUIMuted")
        isSFXMuted = UserDefaults.standard.bool(forKey: "isSFXMuted")
        isBGMMuted = UserDefaults.standard.bool(forKey: "isBGMMuted")
    }
}

