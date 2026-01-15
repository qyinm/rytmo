import SwiftUI
import EventKit
import SwiftData

struct CalendarTabView: View {
    @StateObject private var calendarManager = CalendarManager.shared
    @Query(sort: \TodoItem.orderIndex) private var allTodos: [TodoItem]
    @State private var selectedDate: Date = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Compact Calendar Grid
            NotchCalendarGridView(
                calendarManager: calendarManager,
                selectedDate: $selectedDate
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            
            // Right: Events + Todos for Selected Date
            NotchEventsAndTodosView(
                selectedDate: selectedDate,
                events: eventsForSelectedDate,
                todos: todosForSelectedDate
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
        }
        .padding(.horizontal, 4)
        .onAppear {
            calendarManager.checkPermission()
        }
    }
    
    private var eventsForSelectedDate: [CalendarEventProtocol] {
        calendarManager.mergedEvents.filter { event in
            guard let eventDate = event.eventStartDate else { return false }
            return calendar.isDate(eventDate, inSameDayAs: selectedDate)
        }
    }
    
    private var todosForSelectedDate: [TodoItem] {
        allTodos.filter { todo in
            // 완료된 항목은 해당 날짜에서만 표시
            if todo.isCompleted {
                guard let dueDate = todo.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: selectedDate)
            }
            
            // 미완료 + 날짜 미설정: 오늘만 표시
            guard let dueDate = todo.dueDate else {
                return calendar.isDateInToday(selectedDate)
            }
            
            return calendar.isDate(dueDate, inSameDayAs: selectedDate)
        }
    }
}

// MARK: - Notch Compact Calendar Grid

struct NotchCalendarGridView: View {
    @ObservedObject var calendarManager: CalendarManager
    @Binding var selectedDate: Date
    
    @State private var displayedMonth: Date = Date()
    
    /// Use single-letter weekday symbols from locale
    private var weekdaySymbols: [String] {
        CalendarUtils.calendar.veryShortWeekdaySymbols
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Button {
                    displayedMonth = CalendarUtils.calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(displayedMonth, format: .dateTime.month(.abbreviated).year())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    displayedMonth = CalendarUtils.calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            
            // Weekday Labels
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            
            // Days Grid
            let days = CalendarUtils.generateDaysInMonth(for: displayedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(days, id: \.self) { date in
                    DayCellView(
                        date: date,
                        isSelected: CalendarUtils.calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: CalendarUtils.calendar.isDateInToday(date),
                        isCurrentMonth: CalendarUtils.isDate(date, inSameMonthAs: displayedMonth),
                        hasEvents: CalendarUtils.hasEvents(for: date, in: calendarManager.mergedEvents)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal, 4)
            
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Notch Events and Todos View


struct NotchEventsAndTodosView: View {
    let selectedDate: Date
    let events: [CalendarEventProtocol]
    let todos: [TodoItem]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date Header
            Text(selectedDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    // Events
                    ForEach(events.prefix(3), id: \.eventIdentifier) { event in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(event.eventColor)
                                .frame(width: 3, height: 24)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.eventTitle ?? "Untitled")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                if let startDate = event.eventStartDate {
                                    Text(startDate, style: .time)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    // Todos
                    ForEach(todos.prefix(3)) { todo in
                        HStack(spacing: 8) {
                            Button {
                                todo.toggleCompletion()
                            } label: {
                                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(todo.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                            
                            Text(todo.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(todo.isCompleted ? .secondary : .white)
                                .strikethrough(todo.isCompleted)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    // Empty State
                    if events.isEmpty && todos.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("No events")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }
}

