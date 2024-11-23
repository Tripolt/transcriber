//
//  ContentView.swift
//  Transcriber
//
//  Created by Matteo Tripolt on 23.11.24.
//
import SwiftUI
import AVFoundation
import SwiftData

struct ContentView: View {
    @StateObject var audioRecorder = AudioRecorder()
    @State var isUploading = false
    @Environment(\.modelContext) var modelContext

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    List {
                        ForEach(audioRecorder.recordings) { recording in
                            // In ContentView.swift, update the NavigationLink content
                            NavigationLink(destination: RecordingDetailView(recording: recording)) {
                                HStack {
                                    Text(recording.customName ?? recording.fileURL.lastPathComponent)
                                    Spacer()
                                    if recording.summaryText != nil {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                    
                    Spacer()
                    if isUploading {
                        ProgressView("Verarbeite...")
                            .padding()
                    }
                    HStack {
                        Spacer()
                        recordButton
                        Spacer()
                    }
                }
            }
            .navigationTitle("Aufnahmen")
            .onAppear {
                if audioRecorder.modelContext == nil {
                    audioRecorder.modelContext = modelContext
                    audioRecorder.fetchRecordings()
                }

                audioRecorder.onRecordingSaved = { recording in
                    DispatchQueue.main.async {
                        self.uploadAudioFile(recording: recording)
                    }
                }
            }
        }
    }

    private var recordButton: some View {
           Button(action: {
               withAnimation {
                   audioRecorder.recording ? audioRecorder.stopRecording() : audioRecorder.startRecording()
               }
           }) {
               RoundedRectangle(cornerSize: CGSize(width: 22, height: 22))                  .fill(audioRecorder.recording ? Color.red : Color.blue)
                   .frame(width: 130, height: 50)
                   .overlay(
                    HStack{
                        Text(audioRecorder.recording ? "Stop" : "Record")
                            .font(.title2)
                            .foregroundStyle(Color.white)
                        Image(systemName: audioRecorder.recording ? "stop.fill" : "mic.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                   )
                   .shadow(radius: 3)
           }
           .scaleEffect(audioRecorder.recording ? 1.1 : 1.0)
           .animation(.spring(response: 0.3), value: audioRecorder.recording)
       }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            let recording = self.audioRecorder.recordings[index]
            self.audioRecorder.deleteRecording(recording)
        }
    }

    func uploadAudioFile(recording: Recording) {
        self.isUploading = true

        let fileURL = recording.fileURL
        let url = URL(string: "http://localhost:8200/upload")! // Passen Sie die URL an
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()
        let filename = fileURL.lastPathComponent
        let mimeType = "audio/m4a"

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        do {
            let fileData = try Data(contentsOf: fileURL)
            data.append(fileData)
        } catch {
            print("Fehler beim Lesen der Audiodatei: \(error.localizedDescription)")
            self.isUploading = false
            return
        }
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let session = URLSession(configuration: .default)
        session.uploadTask(with: request, from: data) { data, response, error in
            DispatchQueue.main.async {
                self.isUploading = false
            }
            if let error = error {
                print("Fehler beim Hochladen: \(error.localizedDescription)")
                return
            }
            if let data = data, let summary = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    // Speichern der Zusammenfassung im Recording-Objekt
                    recording.summaryText = summary
                    do {
                        try self.modelContext.save()
                    } catch {
                        print("Fehler beim Speichern der Zusammenfassung: \(error.localizedDescription)")
                    }
                }
            }
        }.resume()
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Recording.self, inMemory: true)
}
