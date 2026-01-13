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
    var title: String
    var notes: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var dueDate: Date?
    var orderIndex: Int

    init(title: String, notes: String = "", dueDate: Date? = nil, orderIndex: Int = 0) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.isCompleted = false
        self.createdAt = Date()
        self.dueDate = dueDate
        self.orderIndex = orderIndex
    }
}

