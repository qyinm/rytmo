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
    var onEventSelected: ((CalendarEventProtocol) -> Void)? = nil

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(selectedDate, format: .dateTime.weekday(.wide).month().day())
                    .font(.headline)

                Spacer()

                HStack(spacing: 12) {
                    if !events.isEmpty {
                        Label("\(events.count)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("\(events.count) events")
                    }
                    if !todos.isEmpty {
                        Label("\(todos.count)", systemImage: "checklist")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("\(todos.count) tasks")
                    }
                }
            }

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

            if events.isEmpty && todos.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                            .accessibilityHidden(true)
                        Text("No events or tasks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(boxBackgroundColor)
        )
    }

    private func eventRow(_ event: CalendarEventProtocol) -> some View {
        Button {
            onEventSelected?(event)
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(event.eventColor)
                    .frame(width: 4, height: 36)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    if let startDate = event.eventStartDate {
                        Text(startDate, style: .time)
                            .font(.system(size: 12, weight: .medium))
                    }
                    if let endDate = event.eventEndDate, !event.isAllDay {
                        Text(endDate, style: .time)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 50, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.eventTitle ?? "Untitled")
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    Text(event.sourceName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if onEventSelected != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.03))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(CalendarAccessibility.eventLabel(for: event))
        .help(onEventSelected != nil ? "Edit event" : "")
        .disabled(onEventSelected == nil)
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
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.isCompleted ? "Mark incomplete" : "Mark complete")
            .help(todo.isCompleted ? "Mark incomplete" : "Mark complete")

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .font(.system(size: 14, weight: .medium))
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                if let notes = todo.notes, !notes.isEmpty {
                    Text(notes)
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