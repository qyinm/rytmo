//
//  MusicTrack.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftData
import Foundation

@Model
class MusicTrack {
    @Attribute(.unique) var id: UUID
    var videoId: String
    var title: String
    var thumbnailUrl: URL?
    var sortIndex: Int

    var playlist: Playlist?

    init(title: String, videoId: String, thumbnailUrl: URL?, sortIndex: Int) {
        self.id = UUID()
        self.title = title
        self.videoId = videoId
        self.thumbnailUrl = thumbnailUrl
        self.sortIndex = sortIndex
    }
}
