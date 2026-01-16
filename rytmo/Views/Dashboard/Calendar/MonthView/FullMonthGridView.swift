import SwiftUI
import SwiftData

struct FullMonthGridView: View {
    let days: [Date]
    let eventSlots: [Date: [CalendarEventProtocol?]]
    let displayedMonth: Date
    let todosByDate: [Date: [TodoItem]]
    
    var onEventSelected: ((CalendarEventProtocol) -> Void)?
    var onDateSelected: ((Date) -> Void)?
    
    private static let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            WeekdayHeaderView()
            
            LazyVGrid(columns: Self.columns, spacing: 0) {
                ForEach(days, id: \.timeIntervalSince1970) { date in
                    OptimizedMonthCell(
                        date: date,
                        displayedMonth: displayedMonth,
                        events: eventSlots[date] ?? [],
                        todos: todosByDate[Calendar.current.startOfDay(for: date)] ?? [],
                        onEventSelected: onEventSelected,
                        onDateSelected: onDateSelected
                    )
                }
            }
        }
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .drawingGroup()
    }
}

struct WeekdayHeaderView: View {
    private static let symbols = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.02))
            }
        }
    }
}

struct OptimizedMonthCell: View {
    let date: Date
    let displayedMonth: Date
    let events: [CalendarEventProtocol?]
    let todos: [TodoItem]
    var onEventSelected: ((CalendarEventProtocol) -> Void)?
    var onDateSelected: ((Date) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var isCurrentMonth: Bool { Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month) }
    private var dayNumber: Int { Calendar.current.component(.day, from: date) }
    private var isFirstDay: Bool { dayNumber == 1 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(dayNumber)\(isFirstDay ? "일" : "")")
                    .font(.system(size: 12, weight: isToday ? .bold : .medium))
                    .foregroundColor(isCurrentMonth ? (isToday ? .white : .primary) : .secondary.opacity(0.3))
                    .padding(4)
                    .background(isToday ? Color.blue : Color.clear)
                    .clipShape(Circle())
                Spacer()
            }
            .padding(.top, 4)
            .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 2) {
                ForEach(0..<min(events.count, 4), id: \.self) { index in
                    if let event = events[index] {
                        SimpleEventBar(event: event, date: date, onTap: onEventSelected)
                    } else {
                        Color.clear.frame(height: 16)
                    }
                }
                
                let remainingSlots = max(0, 4 - events.count)
                ForEach(todos.prefix(remainingSlots), id: \.id) { todo in
                    SimpleTodoBar(title: todo.title)
                }
                
                let totalItems = events.count + todos.count
                if totalItems > 4 {
                    Text("+ more")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
        .border(Color.primary.opacity(0.1), width: 0.5)
        .contentShape(Rectangle())
        .onTapGesture { onDateSelected?(date) }
    }
}

struct SimpleEventBar: View {
    let event: CalendarEventProtocol
    let date: Date
    var onTap: ((CalendarEventProtocol) -> Void)?
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    
    private var isStart: Bool {
        guard let start = event.eventStartDate else { return true }
        return Calendar.current.isDate(start, inSameDayAs: date) || Calendar.current.component(.weekday, from: date) == 1
    }
    
    private var timeString: String? {
        guard isStart, let d = event.eventStartDate else { return nil }
        return Self.timeFormatter.string(from: d)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(event.eventTitle ?? "Untitled")
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
            Spacer(minLength: 0)
            if let time = timeString {
                Text(time)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(event.eventColor.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .padding(.horizontal, 2)
        .contentShape(Rectangle())
        .onTapGesture { onTap?(event) }
    }
}

struct SimpleTodoBar: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .lineLimit(1)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .padding(.horizontal, 2)
    }
}
