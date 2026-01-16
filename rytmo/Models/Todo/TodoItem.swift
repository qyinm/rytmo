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

    // Lightweight migration: content -> title
    // SwiftData will automatically migrate old "content" field to "title"
    @Attribute(originalName: "content") var title: String

    // Optional to allow automatic migration (existing items will have nil)
    var notes: String?
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var dueDate: Date?
    var orderIndex: Int

    init(title: String, notes: String? = nil, dueDate: Date? = nil, orderIndex: Int = 0) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.isCompleted = false
        self.createdAt = Date()
        self.dueDate = dueDate
        self.orderIndex = orderIndex
    }

    func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
        if isCompleted && dueDate == nil {
            dueDate = completedAt
        }
    }
}

