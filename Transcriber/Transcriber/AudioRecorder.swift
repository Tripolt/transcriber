//
//  AudioRecorder.swift
//  Transcriber
//
//  Created by Matteo Tripolt on 23.11.24.
//
import Foundation
import AVFoundation
import SwiftUI
import SwiftData

class AudioRecorder: NSObject, ObservableObject {
    @Published var recordings: [Recording] = []
    @Published var recording = false

    var audioRecorder: AVAudioRecorder?
    var recordingSession: AVAudioSession?
    var modelContext: ModelContext?
    var onRecordingSaved: ((Recording) -> Void)?

    override init() {
        super.init()
    }

    func startRecording() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try recordingSession?.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let tempDirectory = FileManager.default.temporaryDirectory
            let audioFilename = tempDirectory.appendingPathComponent("\(Date().toString()).m4a")

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            recording = true
        } catch {
            print("Fehler beim Starten der Aufnahme: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        recording = false

        if let tempURL = audioRecorder?.url, let modelContext = modelContext {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsDirectory.appendingPathComponent(tempURL.lastPathComponent)
            do {
                try FileManager.default.moveItem(at: tempURL, to: audioFilename)

                let newRecording = Recording(fileURL: audioFilename)
                modelContext.insert(newRecording)
                try modelContext.save()
                fetchRecordings()
                onRecordingSaved?(newRecording)
            } catch {
                print("Fehler beim Speichern der Aufnahme: \(error.localizedDescription)")
            }
        }
    }

    func fetchRecordings() {
        guard let modelContext = modelContext else { return }
        let request = FetchDescriptor<Recording>()
        do {
            let fetchedRecordings = try modelContext.fetch(request)
            DispatchQueue.main.async {
                self.recordings = fetchedRecordings.sorted(by: { $0.createdAt > $1.createdAt })
            }
        } catch {
            print("Fehler beim Abrufen der Aufnahmen: \(error.localizedDescription)")
        }
    }

    func deleteRecording(_ recording: Recording) {
        guard let modelContext = modelContext else { return }
        do {
            try FileManager.default.removeItem(at: recording.fileURL)
            modelContext.delete(recording)
            try modelContext.save()
            fetchRecordings()
        } catch {
            print("Error deleting recording: \(error.localizedDescription)")
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // Nichts tun oder sicherstellen, dass kein Recording-Objekt erstellt wird
    }
}

extension Date {
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter.string(from: self)
    }
}
