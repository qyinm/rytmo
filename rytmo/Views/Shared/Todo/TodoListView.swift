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
            
            // 입력 필드
            HStack(spacing: 8) {
                TextField("새로운 할 일 추가...", text: $newTaskContent)
                    .textFieldStyle(.plain)
                    .font(.system(size: compact ? 13 : 15))
                    .padding(.horizontal, 10)
                    .padding(.vertical, compact ? 6 : 10)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                    .focused($isInputFocused)
                    .onSubmit {
                        addTodo()
                    }
                
                Button(action: addTodo) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: compact ? 18 : 22))
                        .foregroundColor(newTaskContent.isEmpty ? .secondary.opacity(0.5) : .primary)
                }
                .buttonStyle(.plain)
                .disabled(newTaskContent.isEmpty)
            }
            
            // 투두 리스트
            if todos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: compact ? 24 : 32))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("할 일이 없습니다")
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
        
        let newTodo = TodoItem(content: newTaskContent, orderIndex: todos.count)
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
            
            Text(todo.content)
                .font(.system(size: compact ? 13 : 15))
                .strikethrough(todo.isCompleted)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)
                .lineLimit(3)
            
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
}

