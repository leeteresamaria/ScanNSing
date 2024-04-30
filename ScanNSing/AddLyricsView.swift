//
//  AddLyricsView.swift
//  ScanNSing
//
//  Created by Teresa on 4/11/24.
//

import Foundation
import SwiftUI
import SwiftData

struct LyricsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let song: Song
    @Binding var isPresenting: Bool
    @Binding var isShowingSheet: Bool
    
    var body: some View {
        Text(song.songName)
        Text("Format: [timestamp] lyrics")
        List {
            ForEach(song.lyrics.sorted(by: { $0.timestamp < $1.timestamp })) { lyric in
                Text("[\(lyric.timestamp, specifier: "%.2f")] \(lyric.lyricString)")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isShowingSheet.toggle()
                }) {
                    Text("Edit")
                }
                .sheet(isPresented: $isShowingSheet) {
                    LyricsEditor(song: song)
                }
            }
        }
    }
}

struct AddLyricsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var songs: [Song]
    @State private var isPresenting = false
    @State private var isShowingSheet = false

    var body: some View {
        VStack {
            Text("All stored lyrics")
            List {
                ForEach(songs) { song in
                    NavigationLink {
                        LyricsDetailView(song: song, isPresenting: $isPresenting, isShowingSheet: $isShowingSheet)
                    } label: {
                        Text(song.songName)
                    }
                }
                .onDelete(perform: deleteSong)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingSheet.toggle()
                    }) {
                        Label("Add Song", systemImage: "plus")
                    }
                    .sheet(isPresented: $isShowingSheet) {
                        LyricsEditor(song: nil)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        AddSampleSongs()
                    }) {
                        Text("Add Sample Songs")
                    }
                }
            }
        }
    }
    

    private func AddSampleSongs() {
        addSong1()  // Varsity and the Victors
        addSong2()  // The Yellow and Blue
        addSong3()  // The Star Spangled Banner
    }

    private func deleteSong(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(songs[index])
            }
        }
    }
    
    private func addSong1() {
        // Varsity and the Victors
        var newLyrics : [Lyric] = []
        newLyrics.append(Lyric(timestamp: 0.0, lyrics: "[Instrumental]"))
        newLyrics.append(Lyric(timestamp: 3.0, lyrics: "Men of Michigan onto victory,"))
        newLyrics.append(Lyric(timestamp: 6.25, lyrics: "Ev'ry man in ev'ry play."))
        newLyrics.append(Lyric(timestamp: 9.5, lyrics: "Michigan expects her Varsity to win today!"))
        newLyrics.append(Lyric(timestamp: 15.5, lyrics: "Rah! Rah! Win for Michigan!"))
        
        newLyrics.append(Lyric(timestamp: 21.5, lyrics: "Varsity, Down the field."))
        newLyrics.append(Lyric(timestamp: 24.5, lyrics: "Never yield, Raise high our shield."))
        newLyrics.append(Lyric(timestamp: 27.5, lyrics: "March on to victory for Michigan,"))
        newLyrics.append(Lyric(timestamp: 32.5, lyrics: "And the Maize and Blue"))
        newLyrics.append(Lyric(timestamp: 33.5, lyrics: "Oh Varsity, We're for you,"))
        newLyrics.append(Lyric(timestamp: 36.5, lyrics: "Here for you to cheer for you."))
        newLyrics.append(Lyric(timestamp: 39.75, lyrics: "We have no fear for you. Oh Varsity!"))
        newLyrics.append(Lyric(timestamp: 45.0, lyrics: "[Instrumental]"))
        
        newLyrics.append(Lyric(timestamp: 54.5, lyrics: "Varsity, Down the field."))
        newLyrics.append(Lyric(timestamp: 57.75, lyrics: "Never yield, Raise high our shield."))
        newLyrics.append(Lyric(timestamp: 61.0, lyrics: "March on to victory for Michigan,"))
        newLyrics.append(Lyric(timestamp: 65.75, lyrics: "And the Maize and Blue"))
        newLyrics.append(Lyric(timestamp: 67.0, lyrics: "Oh Varsity, We're for you,"))
        newLyrics.append(Lyric(timestamp: 70.0, lyrics: "Here for you to cheer for you."))
        newLyrics.append(Lyric(timestamp: 73.0, lyrics: "We have no fear for you. Oh Varsity!"))
        newLyrics.append(Lyric(timestamp: 81.0, lyrics: "[Instrumental]"))
        
        newLyrics.append(Lyric(timestamp: 84.0, lyrics: "Now for a cheer they are here, triumphant!"))
        newLyrics.append(Lyric(timestamp: 87.0, lyrics: "Here they come with banners flying,"))
        newLyrics.append(Lyric(timestamp: 90.5, lyrics: "In stalwart step they're nighing,"))
        newLyrics.append(Lyric(timestamp: 93.0, lyrics: "With shouts of vict'ry crying,"))
        newLyrics.append(Lyric(timestamp: 96.0, lyrics: "We hurrah, hurrah, we greet you now, Hail!"))
        
        newLyrics.append(Lyric(timestamp: 99.0, lyrics: "Here they come with banners flying,"))
        newLyrics.append(Lyric(timestamp: 101.75, lyrics: "In stalwart step they're nighing,"))
        newLyrics.append(Lyric(timestamp: 104.75, lyrics: "With shouts of vict'ry crying,"))
        newLyrics.append(Lyric(timestamp: 107.5, lyrics: "We hurrah, hurrah, we greet you now, Hail!"))
        
        newLyrics.append(Lyric(timestamp: 110.5, lyrics: "Far we their praises sing"))
        newLyrics.append(Lyric(timestamp: 113.0, lyrics: "For the glory and fame they've bro't us"))
        newLyrics.append(Lyric(timestamp: 116.5, lyrics: "Loud let the bells them ring"))
        newLyrics.append(Lyric(timestamp: 119.0, lyrics: "For here they come with banners flying"))

        newLyrics.append(Lyric(timestamp: 122.0, lyrics: "Far we their praises tell"))
        newLyrics.append(Lyric(timestamp: 124.5, lyrics: "For the glory and fame they've bro't us"))
        newLyrics.append(Lyric(timestamp: 128.0, lyrics: "Loud let the bells them ring"))
        newLyrics.append(Lyric(timestamp: 130.5, lyrics: "For here they come with banners flying"))

        newLyrics.append(Lyric(timestamp: 132.75, lyrics: "Here they come, Hurrah!"))
        
        newLyrics.append(Lyric(timestamp: 136.25, lyrics: "Hail! to the victors valiant"))
        newLyrics.append(Lyric(timestamp: 140.5, lyrics: "Hail! to the conqu'ring heroes"))
        newLyrics.append(Lyric(timestamp: 144.5, lyrics: "Hail! Hail! to Michigan"))
        newLyrics.append(Lyric(timestamp: 147.75, lyrics: "the leaders and best"))
        
        newLyrics.append(Lyric(timestamp: 152.0, lyrics: "Hail! to the victors valiant"))
        newLyrics.append(Lyric(timestamp: 155.75, lyrics: "Hail! to the conqu'ring heroes"))
        newLyrics.append(Lyric(timestamp: 159.25, lyrics: "Hail! Hail! to Michigan"))
        newLyrics.append(Lyric(timestamp: 162.5, lyrics: "the champions of the West!"))
            
        newLyrics.append(Lyric(timestamp: 166.0, lyrics: "We cheer them again"))
        newLyrics.append(Lyric(timestamp: 167.0, lyrics: "We cheer and cheer again"))
        newLyrics.append(Lyric(timestamp: 169.0, lyrics: "For Michigan, we cheer for Michigan"))
        newLyrics.append(Lyric(timestamp: 172.75, lyrics: "We cheer with might and main"))
        newLyrics.append(Lyric(timestamp: 177.0, lyrics: "We cheer, cheer, cheer"))
        newLyrics.append(Lyric(timestamp: 179.25, lyrics: "With might and main we cheer!"))
        
        newLyrics.append(Lyric(timestamp: 181.0, lyrics: "Hail! to the victors valiant"))
        newLyrics.append(Lyric(timestamp: 184.0, lyrics: "Hail! to the conqu'ring heroes"))
        newLyrics.append(Lyric(timestamp: 187.5, lyrics: "Hail! Hail! to Michigan"))
        newLyrics.append(Lyric(timestamp: 190.5, lyrics: "the leaders and best"))
        newLyrics.append(Lyric(timestamp: 193.5, lyrics: "with pride we"))
        
        newLyrics.append(Lyric(timestamp: 196.0, lyrics: "Hail! to the victors valiant"))
        newLyrics.append(Lyric(timestamp: 199.5, lyrics: "Hail! to the conqu'ring heroes"))
        newLyrics.append(Lyric(timestamp: 202.75, lyrics: "Hail! Hail! to Michigan"))
        newLyrics.append(Lyric(timestamp: 205.5, lyrics: "the champions of the West!"))
        newLyrics.append(Lyric(timestamp: 209.5, lyrics: "Go Blue!"))
        
        modelContext.insert(Song(songName: "Varsity and the Victors", lyrics: newLyrics))
    }
    
    func addSong2() {
        // Yellow and Blue
        var newLyrics : [Lyric] = []
        newLyrics.append(Lyric(timestamp: 0.0, lyrics: "[Instrumental]"))
        
        newLyrics.append(Lyric(timestamp: 12.5, lyrics: "Sing to the colors that float in the light;"))
        newLyrics.append(Lyric(timestamp: 20.0, lyrics: "Hurrah for the Yellow and Blue!"))
        newLyrics.append(Lyric(timestamp: 27.0, lyrics: "Yellow the stars as they ride through the night"))
        newLyrics.append(Lyric(timestamp: 34.0, lyrics: "And reel in a rollicking crew;"))
        
        newLyrics.append(Lyric(timestamp: 41.5, lyrics: "Yellow the field where ripens the grain"))
        newLyrics.append(Lyric(timestamp: 47.5, lyrics: "And yellow the moon on the harvest wain;"))
        newLyrics.append(Lyric(timestamp: 55.5, lyrics: "Hail!"))
        
        newLyrics.append(Lyric(timestamp: 60.5, lyrics: "Hail to the colors that float in the light"))
        newLyrics.append(Lyric(timestamp: 67.0, lyrics: "Hurrah for the Yellow and Blue!"))
        
        modelContext.insert(Song(songName: "The Yellow and Blue", lyrics: newLyrics))
    }
    
    func addSong3() {
        // The Star Spangled Banner
        var newLyrics : [Lyric] = []
        newLyrics.append(Lyric(timestamp: 0.0, lyrics: "[Instrumental]"))
        
        newLyrics.append(Lyric(timestamp: 8.30, lyrics: "Oh say can you see"))
        newLyrics.append(Lyric(timestamp: 12.55, lyrics: "By the dawns early light"))
        newLyrics.append(Lyric(timestamp: 17.35, lyrics: "What so proudly we hailed"))
        newLyrics.append(Lyric(timestamp: 21.94, lyrics: "At the twilights last gleaming"))
        
        newLyrics.append(Lyric(timestamp: 26.74, lyrics: "Who's broad striped and bright stars"))
        newLyrics.append(Lyric(timestamp: 31.17, lyrics: "Through the perilous fight"))
        newLyrics.append(Lyric(timestamp: 35.98, lyrics: "O'er the ramparts we watched"))
        newLyrics.append(Lyric(timestamp: 40.52, lyrics: "Were so gallantly streaming"))
        
        newLyrics.append(Lyric(timestamp: 44.99, lyrics: "And the rocket's red glare"))
        newLyrics.append(Lyric(timestamp: 49.46, lyrics: "The bombs bursting in air"))
        newLyrics.append(Lyric(timestamp: 53.84, lyrics: "Gave proof through the night"))
        newLyrics.append(Lyric(timestamp: 58.49, lyrics: "That our flag was still there"))
        
        newLyrics.append(Lyric(timestamp: 63.47, lyrics: "Oh say does that star spangled banner yet wave"))
        newLyrics.append(Lyric(timestamp: 73.81, lyrics: "O'er the land of the free"))
        newLyrics.append(Lyric(timestamp: 79.53, lyrics: "And the home of the brave"))
        
        modelContext.insert(Song(songName: "The Star Spangled Banner", lyrics: newLyrics))
    }
}

struct LyricsEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var songs: [Song]
    
    let song: Song?
    
    private var editorTitle: String {
        song == nil ? "Add Song" : "Edit Song"
    }
    
    @State private var name = ""
    @State private var timestamps: [Double] = []
    @State private var lyrics: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Song Name", text: $name)
                }
                
                ForEach(0..<lyrics.count, id: \.self) { index in
                    Section {
                        TextField("Timestamp", value: $timestamps[index], format: .number)
                        TextField("Lyrics Line", text: $lyrics[index])
                    }
                }
                
                Button(action: {
                    self.timestamps.append(0.0)
                    self.lyrics.append("")
                }) {
                    Text("Add line")
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(editorTitle)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        withAnimation{
                            save()
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let song {
                name = song.songName
                for lyric in song.lyrics {
                    lyrics.append(lyric.lyricString)
                    timestamps.append(lyric.timestamp)
                }
            }
        }
    }
    
    private func save() {
        if let song {
            song.songName = name
            var newLyricArray: [Lyric] = []
            for (i, lyric) in lyrics.enumerated() {
                let newLyric = Lyric(timestamp: timestamps[i], lyrics: lyric)
                newLyricArray.append(newLyric)
            }
            song.lyrics = newLyricArray
        } else {
            var newLyricArray: [Lyric] = []
            for (i, lyric) in lyrics.enumerated() {
                let newLyric = Lyric(timestamp: timestamps[i], lyrics: lyric)
                newLyricArray.append(newLyric)
            }
            
            let newSong = Song(songName: name, lyrics: newLyricArray)
            modelContext.insert(newSong)
        }
    }
    
}
