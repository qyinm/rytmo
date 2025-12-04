//
//  Playlist.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftData
import Foundation

@Model
class Playlist {
    @Attribute(.unique) var id: UUID
    var name: String
    var themeColorHex: String
    var createdAt: Date
    var orderIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \MusicTrack.playlist)
    var tracks: [MusicTrack] = []

    init(name: String, themeColorHex: String, orderIndex: Int) {
        self.id = UUID()
        self.name = name
        self.themeColorHex = themeColorHex
        self.createdAt = Date()
        self.orderIndex = orderIndex
    }
}
