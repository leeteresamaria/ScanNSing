//
//  LyricsView.swift
//  ScanNSing
//
//  Created by Teresa on 3/18/24.
//

import Foundation
import SwiftUI
import SwiftData
import Combine


struct LyricsRow: View {
    let lyric: Lyric
    let isCurrentLyric: Bool
    let editMode: EditMode
    var onLyricTapped: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Text(lyric.lyricString)
                .font(isCurrentLyric ? .title3.weight(.bold) : .none)
                .foregroundStyle(isCurrentLyric ? .primary : Color.secondary)
                .padding(.vertical, 8)
                .multilineTextAlignment(.center)
            Spacer()
            if editMode == .active {
                Button(action: onLyricTapped) {
                    Image(systemName: "circle")
                }
            } else {
                Image(systemName: "circle")
                .hidden()
            }
        }
        .id(lyric.id)
    }
}

struct LyricsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var songDetails: SongDetails
    
    @Query(sort: \Song.songName) var songs: [Song]
    
    let startingPlaybackTime: TimeInterval
    let inputName: String
    @Binding var autosync: Bool   // boolean that changes with button
    
    @State private var currentPlaybackTime: TimeInterval = 0.0
    @State private var currentLyricId: UUID? = nil
    @State private var editMode = EditMode.inactive
    @State private var timer: Timer?
    
    init(startingPlaybackTime: TimeInterval, inputName: String, autosync: Binding<Bool>) {
        self.startingPlaybackTime = startingPlaybackTime
        _currentPlaybackTime = State(initialValue: startingPlaybackTime) // Initialize the State variable

        self.inputName = inputName
        _songs = Query(filter: #Predicate {
            $0.songName.localizedStandardContains(inputName)
        })
        
        self._autosync = autosync
    }
    
    var sortedLyrics: [Lyric] {
        // Make sure `songs.first` exists and has lyrics.
        // If not, return an empty array.
        guard let songLyrics = songs.first?.lyrics else {
            return []
        }
        // Return the sorted lyrics array.
        return songLyrics.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    private func scheduleTimerForNextLyric() {
        // Invalidate the previous timer
        self.timer?.invalidate()
        
        // Stop if we're at the end of the lyrics list
        guard let currentLyricIndex = sortedLyrics.firstIndex(where: { $0.id == self.currentLyricId }),
              currentLyricIndex + 1 < sortedLyrics.count else { return }
        
        let nextLyric = sortedLyrics[currentLyricIndex + 1]
        let interval = nextLyric.timestamp - self.currentPlaybackTime - 0.1
        
        // Schedule a new timer
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            guard let nextLyricIndex = self.sortedLyrics.firstIndex(where: { $0.id == self.currentLyricId })?.advanced(by: 1) else { return }
            
            if nextLyricIndex < self.sortedLyrics.count {
                let nextLyric = self.sortedLyrics[nextLyricIndex]
                self.currentLyricId = nextLyric.id
                self.currentPlaybackTime = nextLyric.timestamp
                // Call the function to schedule a new timer for the next lyric
                self.scheduleTimerForNextLyric()
            }
        }
    }
    
    // This function will be called when the user changes the playback time manually
    private func updateForManualTimeChange(newTime: TimeInterval) {
        // Cancel any existing timer
        timer?.invalidate()
        
        // Find the current lyric based on newTime and set currentLyricId
        currentLyricId = currentlyPlayingLyricId(for: newTime)
        
        // Start the timer for the next lyric
        scheduleTimerForNextLyric()
    }
    
    func currentlyPlayingLyricId(for timing: TimeInterval) -> UUID? {
        var currentlyPlayingLyricId: UUID?
        
        for i in 0 ..< sortedLyrics.count {
            let currentLyric = sortedLyrics[i]
            let nextLyricTimestamp = i + 1 < sortedLyrics.count ? sortedLyrics[i + 1].timestamp : nil
            
            if timing >= currentLyric.timestamp &&
                (nextLyricTimestamp == nil || timing < nextLyricTimestamp!) {
                currentlyPlayingLyricId = currentLyric.id
                break // Once we find the currently playing lyric, we stop searching
            }
        }
        
        print("currentlyPlayingLyricId: \(String(describing: currentlyPlayingLyricId))")
        return currentlyPlayingLyricId
    }
    
    
    var body: some View {
        if let _ = songs.first {
            NavigationView {
                ScrollViewReader { proxy in
                    VStack {
                        // Text(song.songName).font(.title)
//                        Text("timestamp: \(currentPlaybackTime)")
//                        Button(autosync ? "On" : "Off") {
//                            autosync.toggle()
//                        }
                        ScrollView {
                            VStack {
                                ForEach(sortedLyrics) { lyric in
                                    LyricsRow(
                                        lyric: lyric,
                                        isCurrentLyric: lyric.id == currentLyricId,
                                        editMode: editMode
                                    ) {
                                        print("Tapped: \(lyric.id), \(lyric.timestamp), \(lyric.lyricString)")
                                        currentPlaybackTime = lyric.timestamp
                                        updateForManualTimeChange(newTime: lyric.timestamp)
                                        autosync = false    // disable autosync when lyrics are manually readjusted
                                    }
                                }
                            }
                        }
                        .onChange(of: currentLyricId) {
                            if (editMode == EditMode.inactive) {
                                withAnimation {
                                    proxy.scrollTo(currentLyricId, anchor: .center) // Use the proxy to scroll to the Text view with the currentLyricId
                                }
                            }
                        }
                        .onChange(of: startingPlaybackTime) {
                            currentPlaybackTime = startingPlaybackTime
                            updateForManualTimeChange(newTime: startingPlaybackTime)
                            print("startingPlaybacktime changed: \(startingPlaybackTime)")
                        }
                    }
                    .onAppear {
                        print("startingPlaybackTime = \(startingPlaybackTime)")
                        currentPlaybackTime = startingPlaybackTime
                        updateForManualTimeChange(newTime: startingPlaybackTime)
                    }
                    .onDisappear {
                        // Cancel the timer when the view disappears
                        // timerSubscription?.cancel()
                        self.timer?.invalidate()
                    }
                }
                // .navigationBarHidden(true)
                // .navigationBarTitleDisplayMode(.inline)
                // .navigationTitle(song.songName)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Toggle(isOn: $autosync) {
                            Text("Autosync \(autosync ? "On" : "Off")")
                        }
                        Spacer()
                        if songDetails.resync.startRecording && !songDetails.resync.recorded {
                            Image(systemName: "mic.fill").foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "mic").foregroundStyle(.secondary)
                        }
                        Spacer()
                        EditButton()
                    }
                }
                .environment(\.editMode, $editMode)
            }
        } else {
            Text("Lyrics unavailable")
        }
    }
}


