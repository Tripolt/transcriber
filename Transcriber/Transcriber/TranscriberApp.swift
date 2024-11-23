//
//  TranscriberApp.swift
//  Transcriber
//
//  Created by Matteo Tripolt on 23.11.24.
//

import SwiftUI
import SwiftData

@main
struct TranscriberApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recording.self,
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
            ContentView()
        }
        .modelContainer(for: Recording.self)
    }
}
