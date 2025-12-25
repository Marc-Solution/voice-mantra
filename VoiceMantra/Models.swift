//
//  Models.swift
//  MantraFlow
//
//  SwiftData models for persistent storage
//

import Foundation
import SwiftData

@Model
final class AffirmationList {
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \Affirmation.list)
    var affirmations: [Affirmation] = []
    var createdAt: Date = Date()
    
    init(title: String, affirmations: [Affirmation] = []) {
        self.title = title
        self.affirmations = affirmations
    }
}

@Model
final class Affirmation {
    /// The text content the user writes for the affirmation
    var text: String
    /// Unique filename of the recorded audio file (e.g., "550e8400.m4a")
    var audioFileName: String?
    var createdAt: Date = Date()
    /// Sort order for manual reordering (lower = earlier)
    var sortOrder: Int = 0
    /// Whether this affirmation is muted (skipped during playback)
    var isMuted: Bool = false
    var list: AffirmationList?
    
    init(text: String, audioFileName: String? = nil, list: AffirmationList? = nil) {
        self.text = text
        self.audioFileName = audioFileName
        self.list = list
        // Initialize sortOrder based on createdAt timestamp (milliseconds since epoch)
        // This ensures existing affirmations maintain their creation order
        self.sortOrder = Int(Date().timeIntervalSince1970 * 1000)
    }
    
    /// Returns true if no audio has been recorded (text only)
    var isDraft: Bool {
        audioFileName == nil || audioFileName?.isEmpty == true
    }
    
    /// Returns the display name (first 20 characters of text)
    var displayName: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Untitled"
        }
        let prefix = String(trimmed.prefix(20))
        return trimmed.count > 20 ? prefix + "..." : prefix
    }
    
    /// Returns the full path to the audio file in Documents directory
    var audioFileURL: URL? {
        guard let fileName = audioFileName else { return nil }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }
}

