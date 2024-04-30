//
//  AudioPlayer.swift
//  swiftUIChatter
//
//  Created by Teresa Lee on 23/9/2023.
//

import AVFoundation

enum StartMode {
    case standby, record, play
}
enum PlayerState: Equatable {
    case start(StartMode)
    case recording
    case playing(StartMode)
    case paused(StartMode)
    
    mutating func transition(_ event: TransEvent) {
        if (event == .doneTapped) {
            self = .start(.standby)
            return
        }
        switch self {
        case .start(.record) where event == .recTapped:
            self = .recording
        case .start(.play) where event == .playTapped:
            self = .playing(.play)
        case .start(.standby):
            switch event {
            case .recTapped:
                self = .recording
            case .playTapped:
                self = .playing(.standby)
            default:
                break
            }
        case .recording:
            switch event {
            case .recTapped:
                fallthrough
            case .stopTapped:
                self = .start(.standby)
            case .failed:
                self = .start(.record)
            default:
                break
            }
        case .playing(let parent):
            switch event {
            case .playTapped:
                self = .paused(parent)
            case .stopTapped, .failed:
                self = .start(parent)
            default:
                break
            }
        case .paused(let grand):
            switch event {
            case .recTapped:
                self = .recording
            case .playTapped:
                self = .playing(grand)
            case .stopTapped:
                self = .start(.standby)
            default:
                break
            }
        default:
            break
        }
    }
}

enum TransEvent {
    case recTapped, playTapped, stopTapped, doneTapped, failed
}

final class AudioPlayer: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate, ObservableObject {
    @Published
    var audio: Data! = nil
    let audioFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sample.m4a")
    
    let playerUIState = PlayerUIState()
    var playerState = PlayerState.start(.standby) {
        didSet { playerUIState.propagate(playerState) }
    }
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder! = nil
    private var audioPlayer: AVAudioPlayer! = nil

    override init() {
        super.init()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("AudioPlayer: failed to setup AVAudioSession")
        }
    }
    
    func setupRecorder() {
        playerState = .start(.record)
        audio = nil
        
        guard let _ = audioRecorder else {
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try? AVAudioRecorder(url: audioFilePath, settings: settings)
            guard let _ = audioRecorder else {
                print("setupRecorder: failed")
                return
            }
            audioRecorder.delegate = self
            return
        }
    }
       
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Error encoding audio: \(error!.localizedDescription)")
        audioRecorder.stop()
        playerState.transition(.failed)
    }

    func setupPlayer(_ audioStr: String) {
        playerState = .start(.play)
        audio = Data(base64Encoded: audioStr, options: .ignoreUnknownCharacters)
        preparePlayer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error decoding audio \(error?.localizedDescription ?? "on playback")")
        // don't dismiss, in case user wants to record
        playerState.transition(.failed)
    }
   
    private func preparePlayer() {
        audioPlayer = try? AVAudioPlayer(data: audio)
        guard let audioPlayer else {
            print("preparePlayer: incompatible audio encoding, not m4a?")
            return
        }
        audioPlayer.volume = 30.0
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playerState.transition(.stopTapped)
    }

    func playTapped() {
        guard let audioPlayer else {
            print("playTapped: no audioPlayer!")
            return
        }
        playerState.transition(.playTapped)
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }
    
    func stopTapped() {
        audioPlayer.stop()
        audioPlayer.currentTime = 0;
        playerState.transition(.stopTapped)
    }
    
    func recTapped(duration: Int) async -> UInt64{
        await startRecording()
        do {
            try await Task.sleep(for: .seconds(duration))
        } catch {
            print("Error sleeping for \(duration) seconds")
        }
        let startTime = DispatchTime.now().uptimeNanoseconds
        print("StartTime = \(startTime)")

        await endRecording()
        
        return startTime
    }
    
    @MainActor
    func startRecording() {
        audioRecorder.deleteRecording()
        audioRecorder.record()
        playerState.transition(.recTapped)
        print("recTapped: recording audio")
    }
    
    @MainActor
    func endRecording() {
        print("recTapped: finished recording audio")
        audioRecorder.stop()
        audio = try? Data(contentsOf: audioFilePath)
        preparePlayer()
        playerState.transition(.recTapped)
    }
    
}
