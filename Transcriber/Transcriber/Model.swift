//
//  Item.swift
//  Transcriber
//
//  Created by Matteo Tripolt on 23.11.24.
//

import Foundation
import SwiftData

@Model
class Recording: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var fileURL: URL
    var createdAt: Date
    var summaryText: String?
    var customName: String? // New property for custom name
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        self.createdAt = Date()
    }
}

