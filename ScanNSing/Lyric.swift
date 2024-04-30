//
//  Lyric.swift
//  ScanNSing
//
//  Created by Teresa Lee on 3/5/24.
//

import Foundation
import SwiftData

@Model
final class Lyric{
    var id = UUID()
    var timestamp: Double  // timestamp in seconds
    var lyricString: String
    
    init(timestamp: Double, lyrics: String) {
        self.timestamp = timestamp
        self.lyricString = lyrics
    }
}

@Model
final class Song {
    var songName: String
    var lyrics: Array<Lyric>

    init(songName: String = "", lyrics: Array<Lyric> = Array()) {
        self.songName = songName
        self.lyrics = lyrics
    }
}
