//
//  SelectedDayEventsView.swift
//  rytmo
//
//  View displaying events and todos for a selected day
//

import SwiftUI
import SwiftData

struct SelectedDayEventsView: View {
    let selectedDate: Date
    let events: [CalendarEventProtocol]
    var todos: [TodoItem] = []
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text(selectedDate, format: .dateTime.weekday(.wide).month().day())
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if !events.isEmpty {
                        Label("\(events.count)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !todos.isEmpty {
                        Label("\(todos.count)", systemImage: "checklist")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Events Section
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Events")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    ForEach(events, id: \.eventIdentifier) { event in
                        eventRow(event)
                    }
                }
            }
            
            // Todos Section
            if !todos.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tasks")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    ForEach(todos) { todo in
                        todoRow(todo)
                    }
                }
            }
            
            // Empty State
            if events.isEmpty && todos.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No events or tasks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(boxBackgroundColor)
        )
    }
    
    private func eventRow(_ event: CalendarEventProtocol) -> some View {
        HStack(spacing: 12) {
            // Color Indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(event.eventColor)
                .frame(width: 4, height: 36)
            
            // Time
            VStack(alignment: .leading, spacing: 2) {
                if let startDate = event.eventStartDate {
                    Text(startDate, style: .time)
                        .font(.system(size: 12, weight: .medium))
                }
                if let endDate = event.eventEndDate {
                    Text(endDate, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 50, alignment: .leading)
            
            // Event Info
            VStack(alignment: .leading, spacing: 2) {
                Text(event.eventTitle ?? "Untitled")
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Text(event.sourceName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.03))
        )
    }
    
    private func todoRow(_ todo: TodoItem) -> some View {
        HStack(spacing: 12) {
            Button {
                todo.isCompleted.toggle()
                todo.completedAt = todo.isCompleted ? Date() : nil
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .font(.system(size: 14, weight: .medium))
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                
                if !todo.notes.isEmpty {
                    Text(todo.notes)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.03))
        )
    }
    
    private var boxBackgroundColor: Color {
        colorScheme == .dark ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.black.opacity(0.03)
    }
}
