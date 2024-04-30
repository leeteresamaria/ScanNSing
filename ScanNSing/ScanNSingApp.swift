//
//  ScanNSingApp.swift
//  ScanNSing
//
//  Created by Teresa Lee on 12/2/2024.
//

import SwiftUI
import SwiftData


@main
struct ScanNSingApp: App {
    var sharedModelContainer: ModelContainer = {
        
        let schema = Schema([
            Lyric.self,
            Song.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                MusicRecognitionView()
            }
            .environmentObject(AudioPlayer())
            .environmentObject(SongDetails())
        }
        .modelContainer(sharedModelContainer)
    }
}
