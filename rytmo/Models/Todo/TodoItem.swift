//
//  TodoItem.swift
//  rytmo
//
//  Created by gemini-code-assist on 12/24/25.
//

import Foundation
import SwiftData

@Model
class TodoItem {
    @Attribute(.unique) var id: UUID
    var content: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var orderIndex: Int
    
    init(content: String, orderIndex: Int = 0) {
        self.id = UUID()
        self.content = content
        self.isCompleted = false
        self.createdAt = Date()
        self.orderIndex = orderIndex
    }
}

