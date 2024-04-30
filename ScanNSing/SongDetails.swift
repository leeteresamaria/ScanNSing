//
//  SongDetails.swift
//  ScanNSing
//
//  Created by Teresa Lee on 3/8/24.
//

import Foundation
import SwiftUI

final class SongDetails: ObservableObject {
    @Published var initial = MusicRecognitionDetails()    // initial music recognition
    @Published var resync = MusicRecognitionDetails()     // for resynchronization if needed
}

class MusicRecognitionDetails: ObservableObject {
    @Published var startRecording = false
    @Published var recorded = false
    @Published var haveResults = false
    @Published var successfulSearch = false
    
    @Published var fsID: String? = nil
    @Published var title: String? = nil
    @Published var album: String? = nil
    @Published var artist: String? = nil
    @Published var play_offset_ms: Double? = nil
    
    enum SongType {
        case music, cover
    }
    @Published var songType: SongType? = nil
    
    @Published var state: Int = 0
    @Published var startTime: UInt64? = nil // for elapsed time when processing response
    
    
    func saveAudio(_ audioUrl: URL) async throws{
        print("Started saveAudio")
        print(audioUrl)
        print(type(of: audioUrl))
        
        let url = "https://api-v2.acrcloud.com/api/fs-containers/YOUR_CONTAINER_ID_HERE/files"
        
        let token = "YOUR_TOKEN_HERE"
        
        if let fileSize = getFileSize(atPath: audioUrl.path) {
            print("File size: \(fileSize) bytes")
        } else {
            print("Unable to determine file size.")
        }
        
        // Prepare the URL and request
        guard let serverUrl = URL(string: url) else {
            print("saveAudio: Bad server URL")
            return
        }
        var request = URLRequest(url: serverUrl)
        request.httpMethod = "POST"

        // Set the headers
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")

        // Prepare the request body
        var requestBody = Data()
        requestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        requestBody.append("Content-Disposition: form-data; name=\"data_type\"\r\n\r\naudio\r\n".data(using: .utf8)!)
        
        var fileData: Data?
        do {
            fileData = try Data(contentsOf: audioUrl)
        } catch {
            print("SaveAudio: Failed to convert audio content to data")
            return
        }
        guard let fileDataContent = fileData else {
            print("SaveAudio: Failed to unwrap optional audio content")
            return
        }
        let fileName = audioUrl.lastPathComponent

        requestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        requestBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        requestBody.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        requestBody.append(fileDataContent)
        requestBody.append("\r\n".data(using: .utf8)!)

        requestBody.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // Set the request body
        request.httpBody = requestBody
        
        do {
            let data = try await sendAudio(request: request)

            if let responseString = String(data: data, encoding: .utf8) {
                // Update the UI on the main thread inside the MainActor context
                await MainActor.run {
                    self.fsID = getId(responseString)
                    print("Completed saveAudio")
                }
            }
        } catch {
            // Handle the error
            print("saveAudio: NETWORKING ERROR or BAD RESPONSE, error: \(error)")
        }
    }
    
    // send audio to ACRCloud API
    func sendAudio(request: URLRequest) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                // Check for and handle an error from the URLSession
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Attempt to cast the URL response to an HTTP response to check status codes
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: URLError(.cannotParseResponse))
                    return
                }
                
                // Log status code:
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                // Regardless of the status code, we should log the response body if any exists,
                // You might only want to print this in debug mode or have additional checks
                // to avoid logging sensitive information in production.
                if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                    print("Response Body: \(responseString)")
                }
                
                // If the status is not in the 2xx range, throw an error with the bad server response
                guard (200...299).contains(httpResponse.statusCode) else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                // If we have reached this point, the response is valid. Continue with the data
                continuation.resume(returning: data!)
            }.resume()
        }
    }
    
    func getSong() async throws{
        print("Started getSong")
        
        guard let fsID = self.fsID else {
            print("Invalid fileID")
            return
        }
        
        // Define the URL
        let urlString = "https://api-v2.acrcloud.com/api/fs-containers/YOUR_CONTAINER_ID_HERE/files/" + fsID
        print("getSong: fsID = ", fsID)
        
        let token = "YOUR_TOKEN_HERE"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        
        // Create URLSession
        let session = URLSession.shared
        
        // Create data task
        let task = session.dataTask(with: request) { data, response, error in
            // Handle response
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                print("HTTP Error: \(httpResponse.statusCode)")
                return
            }
            
            // Parse and handle data
            if let data = data {
                do {
                   guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                       print("Error: Could not cast JSON to [String: Any]")
                       return
                   }
                    print(json)
                } catch {
                    print("Error parsing JSON: \(error)")
                }
                
                Task {
                    // Directly pass the raw data to the getSongDetails function
                    let musicDetails = await self.getApiState(data)
                    if musicDetails == nil {
                        await MainActor.run {
                            self.haveResults = true
                            print("haveResults = true")
                        }
                        print("Error occured, unable to find song information")
                        return
                    }
                    await MainActor.run {
                        self.haveResults = true
                        print("haveResults = true")
                        self.successfulSearch = true
                        print("successfulSearch = true")
                    }
                    print("Completed getSong")
                }
            }
        }
        
        // Start the task
        task.resume()
    }
    
    struct MusicDataResponse: Codable {
        let data: [MusicData]
    }

    struct MusicData: Codable {
        let results: MusicResults
        let state: Int
    }

    struct MusicResults: Codable {
        let music: [Music]?
        let cover_songs: [Cover]?
    }
    
    struct Music: Codable {
        let result: MusicItem
    }
    
    struct Cover: Codable {
        let result: CoverItem
    }

    struct MusicItem: Codable {
        let album: Album
        let artists: [Artist]
        let title: String
        let play_offset_ms: Int
        // Any other fields you might have
    }
    
    struct CoverItem: Codable {
        let album: Album
        let artists: [Artist]
        let title: String
        // Any other fields you might have
    }

    struct Album: Codable {
        let name: String?
    }

    struct Artist: Codable {
        let name: String?
    }
    
    struct MusicDetails: Codable {
        var album: String?
        var artist: String?
        var title: String
        var play_offset_ms: Double?
    }
    
    func getApiState(_ json: Data) async -> MusicDetails?{
        do {
            // Decode the JSON into our Codable model
            let musicDataResponse = try JSONDecoder().decode(MusicDataResponse.self, from: json)
            
            // Assuming the first item in the data array contains what we're looking for
            guard let firstResult = musicDataResponse.data.first else {
                print("Error: No results found")
                return nil
            }
            
            // get state here
            let state = firstResult.state
            print("State = \(state)")
            await MainActor.run {
                self.state = state
            }
            
            if state == 1 {
                return await getSongDetails(json)
            }
            
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
        return nil
    }

    func getSongDetails(_ json: Data) async -> MusicDetails? {
        do {
            // Decode the JSON into our Codable model
            let musicDataResponse = try JSONDecoder().decode(MusicDataResponse.self, from: json)
            
            // Assuming the first item in the data array contains what we're looking for
            guard let firstResult = musicDataResponse.data.first else {
                print("Error: No results found")
                return nil
            }
            
            let musicResults = firstResult.results
            
            if let musicResult = musicResults.music {
                print("JSON contains music data")
                // Process music data
                // Assuming we only care about the first music item
                guard let firstMusicResult = musicResult.first else {
                    print("Error: No music items found")
                    return nil
                }
                
                let firstMusicItem = firstMusicResult.result
                
                // Assuming you want to take the first artist (if there are multiple)
                let firstArtistName = firstMusicItem.artists.first?.name ?? ""
                
                let musicDetails = MusicDetails(album: firstMusicItem.album.name ?? "",
                                                artist: firstArtistName,
                                                title: firstMusicItem.title,
                                                play_offset_ms: Double(firstMusicItem.play_offset_ms))
                
                // If you need to update UI on the main thread, queue the changes with MainActor as before
                await MainActor.run {
                    self.album = musicDetails.album
                    self.artist = musicDetails.artist
                    self.title = musicDetails.title
                    if let offset = musicDetails.play_offset_ms {
                        self.play_offset_ms = offset/1000.0
                    }
                    self.songType = SongType.music
                }
                print("Album: \(musicDetails.album ?? "")")
                print("Artist: \(musicDetails.artist ?? "")")
                print("Title: \(musicDetails.title)")
                print("play_offset_ms: \(musicDetails.play_offset_ms ?? 0)")
                print("songType: music")
                
                return musicDetails
            } else if let coverResult = musicResults.cover_songs {
                print("JSON contains cover songs data")
                // Process cover songs data
                // Assuming we only care about the first music item
                guard let firstCoverResult = coverResult.first else {
                    print("Error: No music items found")
                    return nil
                }
                
                let firstCoverItem = firstCoverResult.result
                
                // Assuming you want to take the first artist (if there are multiple)
                let firstArtistName = firstCoverItem.artists.first?.name ?? ""
                
                let coverDetails = MusicDetails(album: firstCoverItem.album.name,
                                                artist: firstArtistName,
                                                title: firstCoverItem.title)
                
                // If you need to update UI on the main thread, queue the changes with MainActor as before
                await MainActor.run {
                    self.album = coverDetails.album
                    self.artist = coverDetails.artist
                    self.title = coverDetails.title
                    self.songType = SongType.cover
                }
                print("Album: \(coverDetails.album ?? "")")
                print("Artist: \(coverDetails.artist ?? "")")
                print("Title: \(coverDetails.title)")
                print("SongType: cover")
                
                return coverDetails
            } else {
                print("JSON does not contain music or cover songs data")
                return nil
            }

        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
    
    func reset() {
        startRecording = false
        recorded = false
        haveResults = false
        successfulSearch = false
        
        fsID = nil
        title = nil
        album = nil
        artist = nil
        play_offset_ms = nil
        
        songType = nil
        
        state = 0
        startTime = nil
    }
    
}

func getId(_ jsonString: String) -> String? {
    // Define a Codable struct to represent the JSON structure
    struct DataResponse: Codable {
        let data: DataItem
    }

    struct DataItem: Codable {
        let id: String
        // Add other properties if needed
    }

    // Convert the JSON string to data
    if let jsonData = jsonString.data(using: .utf8) {
        // Decode JSON data into DataResponse
        do {
            let dataResponse = try JSONDecoder().decode(DataResponse.self, from: jsonData)
            // Access the id value
            let id = dataResponse.data.id
            print("ID:", id)
            return id
        } catch {
            print("Error decoding JSON:", error)
        }
    }
    return nil
}

func getFileSize(atPath filePath: String) -> UInt64? {
    do {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
        if let fileSize = fileAttributes[.size] as? UInt64 {
            // Size of the file in bytes
            return fileSize
        }
    } catch {
        print("Error: \(error.localizedDescription)")
    }
    return nil
}

