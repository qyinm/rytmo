import SwiftUI
import SwiftData

// MARK: - Calendar Grid View

struct CalendarGridView: View {
    @ObservedObject var calendarManager: CalendarManager
    @Binding var selectedDate: Date
    @Environment(\.colorScheme) var colorScheme
    
    @State private var displayedMonth: Date = Date()
    
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        VStack(spacing: 20) {
            // Month Navigation Header
            CalendarHeaderView(
                displayedMonth: $displayedMonth,
                onTodayTapped: { selectedDate = Date() }
            )
            
            // Weekday Labels
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            let days = CalendarUtils.generateDaysInMonth(for: displayedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    DayCellView(
                        date: date,
                        isSelected: CalendarUtils.calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: CalendarUtils.calendar.isDateInToday(date),
                        isCurrentMonth: CalendarUtils.isDate(date, inSameMonthAs: displayedMonth),
                        events: CalendarUtils.events(for: date, from: calendarManager.mergedEvents),
                        colorScheme: colorScheme
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedDate = date
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(boxBackgroundColor)
        )
    }
    
    private var boxBackgroundColor: Color {
        colorScheme == .dark ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.black.opacity(0.03)
    }
}

// MARK: - Calendar Header View

struct CalendarHeaderView: View {
    @Binding var displayedMonth: Date
    let onTodayTapped: () -> Void
    
    var body: some View {
        HStack {
            // Month/Year Display with Navigation
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = CalendarUtils.calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.system(size: 16, weight: .semibold))
                    .frame(minWidth: 140)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = CalendarUtils.calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Today Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = Date()
                    onTodayTapped()
                }
            } label: {
                Text("Today")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

// MARK: - Day Cell View

struct DayCellView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let events: [CalendarEventProtocol]
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            // Day Number
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 32, height: 32)
                } else if isToday {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }
                
                Text("\(CalendarUtils.calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday || isSelected ? .semibold : .regular))
                    .foregroundColor(dayTextColor)
            }
            .frame(width: 36, height: 36)
            
            // Event Dots
            if !events.isEmpty {
                HStack(spacing: 3) {
                    ForEach(events.prefix(3), id: \.eventIdentifier) { event in
                        Circle()
                            .fill(event.eventColor)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            } else {
                Spacer()
                    .frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var dayTextColor: Color {
        if isSelected {
            return .white
        } else if !isCurrentMonth {
            return .secondary.opacity(0.4)
        } else if isToday {
            return .accentColor
        } else {
            return .primary
        }
    }
}

// MARK: - Selected Day Events View

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
