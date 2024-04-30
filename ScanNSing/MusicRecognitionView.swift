//
//  PostView.swift
//  swiftUIChatter
//
//  Created by Teresa Lee on 5/9/2023.
//

import SwiftUI

struct MusicRecognitionView: View {
    @EnvironmentObject var songDetails: SongDetails
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    var body: some View {
        VStack {
            Text("Tap the button below to start identifying music!")
            Spacer()
            AudioView()
            Spacer()
            ResultsView()
            Spacer()
        }
        .navigationTitle("ScanNSing")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            audioPlayer.setupRecorder()
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                NavigationLink(destination: AddLyricsView()) {
                    Text("Manage stored lyrics")
                }
            }
        }
        .environmentObject(songDetails.initial)
    }
}

struct ResultsView: View {
    @EnvironmentObject var musicRecognitionDetails: MusicRecognitionDetails

    var body: some View {
        if !musicRecognitionDetails.startRecording {
            // if Button not laid out despite hidden, SwiftUI will not leave empty space
            Button {
            } label: {
                Text("Results")
            }
            .hidden()
        } else {
            if !musicRecognitionDetails.recorded {
                Text("Recording...")
            } else {
                if !musicRecognitionDetails.haveResults {
                    Text("Identifying music...")
                } else {
                    if musicRecognitionDetails.state == 0 {
                        // still identifying
                        Text("Identifying music...")
                    } else {
                        if !musicRecognitionDetails.successfulSearch {
                            Text("Music not found.")
                        } else {
                            NavigationLink(destination: SongView()) {
                                Text("See lyrics for: \(musicRecognitionDetails.title ?? "None")")
                            }
                        }
                    }
                }
            }
        }
    }
}

