//
//  TodoListView.swift
//  rytmo
//
//  Created by gemini-code-assist on 12/24/25.
//

import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.orderIndex) private var todos: [TodoItem]
    
    @State private var newTaskContent: String = ""
    @FocusState private var isInputFocused: Bool
    
    var showHeader: Bool = true
    var compact: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showHeader {
                HStack(spacing: 8) {
                    Text("Tasks")
                        .font(.system(size: compact ? 14 : 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(todos.filter { !$0.isCompleted }.count)")
                        .font(.system(size: compact ? 10 : 12, weight: .bold))
                        .padding(.horizontal, compact ? 6 : 8)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.1))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
            }
            
            // Todo List
            if todos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: compact ? 24 : 32))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("No tasks")
                        .font(.system(size: compact ? 12 : 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 20 : 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(todos) { todo in
                        TodoRowView(todo: todo, compact: compact)
                        
                        if todo.id != todos.last?.id {
                            Divider()
                                .opacity(0.5)
                        }
                    }
                }
                .background(Color.primary.opacity(0.02))
                .cornerRadius(10)
            }
        }
    }
    
    private func addTodo() {
        guard !newTaskContent.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newTodo = TodoItem(title: newTaskContent, orderIndex: todos.count)
        modelContext.insert(newTodo)
        newTaskContent = ""
        isInputFocused = false
    }
}

struct TodoRowView: View {
    @Environment(\.modelContext) private var modelContext
    let todo: TodoItem
    var compact: Bool = false
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                todo.isCompleted.toggle()
                todo.completedAt = todo.isCompleted ? Date() : nil
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: compact ? 16 : 18))
                    .foregroundColor(todo.isCompleted ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.system(size: compact ? 13 : 15))
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .lineLimit(3)

                if !todo.notes.isEmpty {
                    Text(todo.notes)
                        .font(.system(size: compact ? 11 : 13))
                        .foregroundColor(todo.isCompleted ? .secondary.opacity(0.6) : .secondary.opacity(0.8))
                        .lineLimit(2)
                }

                if let dueDate = todo.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: isOverdue(dueDate) ? "calendar.badge.exclamationmark" : "calendar")
                            .font(.system(size: compact ? 10 : 12))
                        Text(formatDate(dueDate))
                            .font(.system(size: compact ? 10 : 12))
                    }
                    .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
                }
            }
            
            Spacer()
            
            if isHovering {
                Button(action: {
                    modelContext.delete(todo)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: compact ? 12 : 14))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, compact ? 8 : 12)
        .padding(.horizontal, compact ? 8 : 12)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }

    // MARK: - Helper Methods

    private func isOverdue(_ date: Date) -> Bool {
        date < Date() && !todo.isCompleted
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

