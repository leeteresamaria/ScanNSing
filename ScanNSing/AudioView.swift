//
//  AudioView.swift
//  swiftUIChatter
//
//  Created by Teresa Lee on 23/9/2023.
//

import SwiftUI

final class PlayerUIState: ObservableObject {
    
    var recHidden = false
    @Published var recDisabled = false
    @Published var recColor = Color(.systemBlue)
    @Published var recIcon =  Image(systemName: "waveform.badge.magnifyingglass")
    
    @Published var playCtlDisabled = true
    
    @Published var playDisabled = true
    @Published var playIcon = Image(systemName: "play")
    
    @Published var doneDisabled = false
    @Published var doneIcon = Image(systemName: "checkmark")
    
    private func reset() {
        recHidden = false
        recDisabled = false
        recColor = Color(.systemBlue)
        recIcon = Image(systemName: "waveform.badge.magnifyingglass")
        
        playCtlDisabled = true
        
        playDisabled = true
        playIcon = Image(systemName: "play")
        
        doneDisabled = false
        doneIcon = Image(systemName: "checkmark")
    }
    
    private func playCtlEnabled(_ enabled: Bool) {
        playCtlDisabled = !enabled
    }
    
    private func playEnabled(_ enabled: Bool) {
        playIcon = Image(systemName: "play")
        playDisabled = !enabled
    }
    
    private func pauseEnabled(_ enabled: Bool) {
        playIcon = Image(systemName: "pause")
        playDisabled = !enabled
    }
    
    private func recEnabled() {
        recIcon = Image(systemName: "waveform.badge.magnifyingglass")
        recDisabled = false
        recColor = Color(.systemBlue)
    }
    
    func propagate(_ playerState: PlayerState) {
        switch (playerState) {
        case .start(.play):
            recHidden = true
            playEnabled(true)
            playCtlEnabled(false)
            doneIcon = Image(systemName: "xmark.square")
        case .start(.standby):
            if !recHidden { recEnabled() }
            playEnabled(true)
            playCtlEnabled(false)
            doneDisabled = false
        case .start(.record):
            // initial values already set up for record start mode.
            reset()
        case .recording:
            recDisabled = true
            recColor = Color(.systemRed)
            playEnabled(false)
            playCtlEnabled(false)
            doneDisabled = true
        case .paused:
            if !recHidden { recEnabled() }
            playIcon = Image(systemName: "play")
        case .playing:
            if !recHidden {
                recDisabled = true
                recColor = Color(.systemGray6)
            }
            pauseEnabled(true)
            playCtlEnabled(true)
        }
    }
}

struct AudioView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer

    var body: some View {
        VStack {
            RecButton()
//            PlayButton()
        }
        .environmentObject(audioPlayer.playerUIState)
    }
}

struct RecButton: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var playerUIState: PlayerUIState
    @EnvironmentObject var songDetails: SongDetails

    var body: some View {
        if playerUIState.recHidden {
            // if Button not laid out despite hidden, SwiftUI will not leave empty space
            Button(action: { }) {
                playerUIState.recIcon
                    .resizable()
                    .frame(width: 200, height: 200)
            }
            .hidden()
        } else {
            Button {
                Task {
                    do {
                        songDetails.initial.reset()
                        songDetails.initial.startRecording = true
                        songDetails.initial.startTime = await audioPlayer.recTapped(duration: 13)
                        songDetails.initial.recorded = true

                        try await Task.sleep(for: .seconds(1))
                        try await songDetails.initial.saveAudio(audioPlayer.audioFilePath)
                        print("Submitted audio to API, navigate to lyrics screen")
                        
                        // try to get results back
                        var timeWaited = 0.0
                        while timeWaited < 5 {
                            try await songDetails.initial.getSong()
                            
                            if songDetails.initial.state == 1 {
                                // found results
                                break
                            } else if songDetails.initial.state == 0 {
                                // processing
                                try await Task.sleep(for: .seconds(1.0))
                                timeWaited += 1.0
                            } else {
                                // state == -1 (not found) or state == -2 (error)
                                print("Song not found")
                                break
                            }
                        }
                        
                        if timeWaited == 4 {
                            print("Waited too long, song not found")
                        }
                        
                        print("Completed getSong()")
                    } catch {
                        print("An error occured: \(error.localizedDescription)")
                    }
                }
            } label: {
                playerUIState.recIcon
                    .resizable()
                    .frame(width: 200, height: 200)
                    .foregroundColor(playerUIState.recColor)
            }
            .disabled(playerUIState.recDisabled)
        }
    }
}

//struct PlayButton: View {
//    @EnvironmentObject var audioPlayer: AudioPlayer
//    @EnvironmentObject var playerUIState: PlayerUIState
//    
//    var body: some View {
//        Button {
//            audioPlayer.playTapped()
//        } label: {
//            playerUIState.playIcon.scaleEffect(2.0)/*.padding(.trailing, 40)*/
//        }
//        .disabled(playerUIState.playDisabled)
//    }
//}
