//
//  RecordingRow.swift
//  Transcriber
//
//  Created by Matteo Tripolt on 23.11.24.
//

import SwiftUI
import AVFoundation

struct RecordingRow: View {
    var audioURL: URL
    @State private var audioPlayer: AVAudioPlayer?
    @ObservedObject private var playerDelegate = AudioPlayerDelegate()

    var body: some View {
        HStack {
            Text(audioURL.lastPathComponent)
            Spacer()
            Button(action: {
                self.playPause()
            }) {
                Image(systemName: playerDelegate.isPlaying ? "stop.fill" : "play.fill")
                    .foregroundColor(playerDelegate.isPlaying ? .red : .blue)
            }
        }
    }

    func playPause() {
        if playerDelegate.isPlaying {
            audioPlayer?.stop()
            playerDelegate.isPlaying = false
        } else {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.delegate = playerDelegate
                // Optional: Aktionen hinzufügen, die ausgeführt werden sollen, wenn die Wiedergabe beendet ist
                playerDelegate.didFinishPlaying = {
                    // Beispiel: Weitere Aktionen bei Beendigung
                }
                audioPlayer?.play()
                playerDelegate.isPlaying = true
            } catch {
                print("Fehler beim Abspielen der Aufnahme: \(error.localizedDescription)")
            }
        }
    }
}
