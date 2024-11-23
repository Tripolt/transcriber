//
//  AudioPlayerDelegate.swift
//  Transcriber
//
//  Created by Matteo Tripolt on 23.11.24.
//
import Foundation
import AVFoundation
import Combine

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate, ObservableObject {
    @Published var isPlaying = false
    var didFinishPlaying: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.didFinishPlaying?()
        }
    }
}
