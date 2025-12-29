//
//  MenuBarTodoView.swift
//  rytmo
//
//  Created by gemini-code-assist on 12/24/25.
//

import SwiftUI
import SwiftData

struct MenuBarTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.orderIndex) private var todos: [TodoItem]
    @Environment(\.openWindow) var openWindow
    
    @State private var isExpanded: Bool = false
    @State private var newTaskContent: String = ""
    @FocusState private var isInputFocused: Bool
    
    private var incompleteTodosCount: Int {
        todos.filter { !$0.isCompleted }.count
    }
    
    private var completionRate: Double {
        guard !todos.isEmpty else { return 0 }
        let completed = todos.filter { $0.isCompleted }.count
        return Double(completed) / Double(todos.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapsible Header
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack(spacing: 10) {
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 12)
                    
                    // Progress Dots
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(index < Int(round(completionRate * 3)) ? Color.black : Color.black.opacity(0.15))
                                .frame(width: 5, height: 5)
                        }
                    }
                    
                    Text("Tasks")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Counter Badge
                    if incompleteTodosCount > 0 {
                        Text("\(incompleteTodosCount)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(
                                Circle()
                                    .fill(Color.black)
                            )
                    } else if !todos.isEmpty {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(Color.black)
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expandable Content
            if isExpanded {
                VStack(spacing: 0) {
                    // Divider
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 0.5)
                        .padding(.horizontal, 14)
                    
                    // Quick Input
                    HStack(spacing: 10) {
                        TextField("Add task...", text: $newTaskContent)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.primary)
                            .focused($isInputFocused)
                            .onSubmit {
                                addTodo()
                            }
                        
                        if !newTaskContent.isEmpty {
                            Button(action: addTodo) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                            )
                    )
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 0.5)
                        .padding(.horizontal, 14)
                    
                    // Task List - Fixed Height ScrollView
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            if todos.isEmpty {
                                // Minimal Empty State
                                VStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.04))
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.black.opacity(0.3))
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("No tasks yet")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text("Add your first task")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(Array(todos.prefix(12).enumerated()), id: \.element.id) { index, todo in
                                        MinimalTodoRow(
                                            todo: todo,
                                            onToggle: {
                                                todo.isCompleted.toggle()
                                                if todo.isCompleted {
                                                    todo.completedAt = Date()
                                                } else {
                                                    todo.completedAt = nil
                                                }
                                            },
                                            onDelete: {
                                                modelContext.delete(todo)
                                            }
                                        )
                                        
                                        if index < min(todos.count, 12) - 1 {
                                            Rectangle()
                                                .fill(Color.black.opacity(0.04))
                                                .frame(height: 0.5)
                                                .padding(.leading, 42)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 220)
                    
                    // Bottom Bar
                    if todos.count > 12 {
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.black.opacity(0.06))
                                .frame(height: 0.5)
                                .padding(.horizontal, 14)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    openWindow(id: "main")
                                }) {
                                    HStack(spacing: 6) {
                                        Text("View all")
                                            .font(.system(size: 11, weight: .medium))
                                        Text("\(todos.count)")
                                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color.black.opacity(0.06))
                                            )
                                        Image(systemName: "arrow.up.forward")
                                            .font(.system(size: 9, weight: .semibold))
                                    }
                                    .foregroundColor(.primary)
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
    }
    
    private func addTodo() {
        guard !newTaskContent.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let newTodo = TodoItem(content: newTaskContent, orderIndex: todos.count)
        modelContext.insert(newTodo)
        newTaskContent = ""
    }
}

// MARK: - Minimal Todo Row

private struct MinimalTodoRow: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Minimal Checkbox
            Button(action: onToggle) {
                ZStack {
                    // Outer circle
                    Circle()
                        .stroke(todo.isCompleted ? Color.black : Color.black.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    
                    if todo.isCompleted {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 18, height: 18)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    } else if isHovering {
                        Circle()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 18, height: 18)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Task Text
            Text(todo.content)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(todo.isCompleted ? .secondary : .primary)
                .strikethrough(todo.isCompleted)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Delete Button
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.04))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(isHovering ? Color.black.opacity(0.02) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    MenuBarTodoView()
        .frame(width: 420)
        .padding()
}
