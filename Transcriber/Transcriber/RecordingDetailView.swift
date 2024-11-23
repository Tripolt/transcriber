//
//  RecordingDetailView.swift
//  Transcriber
//
//  Created by Matteo Tripolt on 23.11.24.
//
import SwiftUI
import AVFoundation

struct RecordingDetailView: View {
    @Bindable var recording: Recording
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0.0
    @State private var showingNameAlert = false
    @State private var newName = ""
    var audioPlayerDelegate = AudioPlayerDelegate()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                recordingInfoSection
                playerControlsSection
                summarySection
            }
            .padding()
        }
        .navigationBarTitle("Recording Details", displayMode: .inline)
        .background(Color(uiColor: .systemGroupedBackground))
        .alert("Rename Recording", isPresented: $showingNameAlert) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                recording.customName = newName
                do {
                    try recording.modelContext?.save()
                } catch {
                    print("Error saving new name: \(error)")
                }
            }
        } message: {
            Text("Enter a new name for this recording")
        }
    }
    
    private var recordingInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(recording.customName ?? recording.fileURL.lastPathComponent)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Button(action: {
                    newName = recording.customName ?? recording.fileURL.lastPathComponent
                    showingNameAlert = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
            
            Text("Recorded on \(formattedDate(recording.createdAt))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var playerControlsSection: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress)
                .accentColor(.blue)
            
            Button(action: playPause) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Summary")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let summary = recording.summaryText {
                    Button(action: {
                        UIPasteboard.general.string = summary
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if let summary = recording.summaryText {
                Text(summary)
                    .padding()
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
            } else {
                Text("No summary available.")
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    func playPause() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            if audioPlayer == nil {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
                    audioPlayerDelegate.didFinishPlaying = {
                        self.isPlaying = false
                        self.progress = 0.0
                    }
                    audioPlayer?.delegate = audioPlayerDelegate
                } catch {
                    print("Error initializing audio player: \(error.localizedDescription)")
                    return
                }
            }
            audioPlayer?.play()
            isPlaying = true
            updateProgress()
        }
    }
    
    func updateProgress() {
        guard let player = audioPlayer, player.duration > 0 else { return }
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.isPlaying {
                self.progress = player.currentTime / player.duration
            } else {
                timer.invalidate()
            }
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
