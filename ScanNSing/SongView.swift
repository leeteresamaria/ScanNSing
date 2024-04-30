//
//  SongView.swift
//  ScanNSing
//
//  Created by Teresa on 3/18/24.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

struct SongView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var songDetails: SongDetails
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    @State private var autosync: Bool = false    // boolean that changes with button
    @State private var elapsedTime: Double = 0.0
    
    @State var timerAutosync: Cancellable? = nil    // for recording sample audio and autosyncing
    
    enum musicRecognitionType {
        case initial, resync
    }
    @State private var recognitionType = musicRecognitionType.initial
    
    var body: some View{
        VStack {
            let title = songDetails.initial.title ?? "None"
            let album = songDetails.initial.album ?? "None"
            let artist = songDetails.initial.artist ?? "None"
            
            Text("Title: \(title)").multilineTextAlignment(.center)
            Text("Album: \(album)").multilineTextAlignment(.center)
            Text("Artist: \(artist)").multilineTextAlignment(.center)
//            Text("Autosync: \(autosync ? "On" : "Off")")
            LyricsView(startingPlaybackTime: elapsedTime, inputName: songDetails.initial.title ?? "", autosync: $autosync)
        }
        .onAppear() {
            elapsedTime = getElapsedTime()
            print("elapsedTime = \(elapsedTime)")
            autosync = songDetails.initial.songType == .music
            self.autoResync()
            timerAutosync = Timer.publish(every: 20.0, on: .main, in: .common).autoconnect()
                .sink { _ in
                    print("Start auto resync process")
                    self.autoResync()
                }
        }
        .onChange(of: autosync) {
            if autosync == true {
                print("turned on autosync")
                // start timer
                self.autoResync()
                timerAutosync = Timer.publish(every: 20.0, on: .main, in: .common).autoconnect()
                    .sink { _ in
                        print("Start auto resync process")
                        self.autoResync()
                    }
            } else {
                print("Turned off autosync")
                timerAutosync?.cancel()
            }
                    
        }
    }
    
    func getElapsedTime() -> Double{
        print("RecognitionType: \(recognitionType)")
        
        var play_offset_ms: Double
        var startTime: UInt64
        var offset = 0.0
        
        if recognitionType == musicRecognitionType.initial {
            guard let play_offset_ms_check = songDetails.initial.play_offset_ms else {
                print("play_offset_ms not found")
                return 0.0
            }
            play_offset_ms = play_offset_ms_check
            
            guard let startTime_check = songDetails.initial.startTime else {
                print("startTime not found")
                return 0.0
            }
            startTime = startTime_check
            
            offset = 2.0
            
        } else {
            // resync
            
            guard let play_offset_ms_check = songDetails.resync.play_offset_ms else {
                print("play_offset_ms not found")
                return 0.0
            }
            play_offset_ms = play_offset_ms_check
            
            guard let startTime_check = songDetails.resync.startTime else {
                print("startTime not found")
                return 0.0
            }
            startTime = startTime_check
            
            offset = 1.5
        }
        
        
        let endTime = DispatchTime.now()
        let elapsedTime = Double(endTime.uptimeNanoseconds - startTime)/1_000_000_000
        print("Elapsed time = \(elapsedTime), timestamp = \(elapsedTime + play_offset_ms)")
        return elapsedTime + play_offset_ms + offset
        /* ACRCloud tends to only use the first 11 seconds of the 13-second recording for original music */
    }
    
    func autoResync() {
        if songDetails.initial.songType != .music || self.autosync != true {
            return
        }
        
        Task {
            do {
                songDetails.resync.reset()
                songDetails.resync.startRecording = true
                songDetails.resync.startTime = await audioPlayer.recTapped(duration: 11)
                songDetails.resync.recorded = true

                try await Task.sleep(for: .seconds(1))
                try await songDetails.resync.saveAudio(audioPlayer.audioFilePath)
                print("Submitted audio to API, navigate to lyrics screen")
                
                // try to get results back
                var timeWaited = 0.0
                while timeWaited < 5 {
                    try await songDetails.resync.getSong()
                    
                    if songDetails.resync.state == 1 {
                        // found results
                        break
                    } else if songDetails.resync.state == 0 {
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
        
        // make sure API response results are valid before changing timestamp
        if !songDetails.resync.successfulSearch || (songDetails.initial.title != songDetails.resync.title) {
            return
        }
        
        self.recognitionType = musicRecognitionType.resync
        elapsedTime = getElapsedTime()
        print("new timestamp = \(elapsedTime)")
    }

}


