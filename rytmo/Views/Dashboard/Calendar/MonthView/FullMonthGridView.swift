import SwiftUI
import SwiftData

// MARK: - Optimization Structures

struct MonthDayInfo: Identifiable, Sendable {
    let id: TimeInterval
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let isCurrentMonth: Bool
    let isFirstDay: Bool
    
    init(date: Date, displayedMonth: Date, calendar: Calendar) {
        self.date = date
        self.id = date.timeIntervalSince1970
        self.dayNumber = calendar.component(.day, from: date)
        self.isToday = calendar.isDateInToday(date)
        self.isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        self.isFirstDay = self.dayNumber == 1
    }
}

struct EventDisplayInfo: Identifiable {
    let id: String
    let title: String
    let color: Color
    let isStart: Bool
    let timeString: String?
    let originalEvent: CalendarEventProtocol
    
    init(event: CalendarEventProtocol, date: Date, calendar: Calendar) {
        self.id = event.eventIdentifier
        self.title = event.eventTitle ?? "Untitled"
        self.color = event.eventColor
        self.originalEvent = event
        
        let start = event.eventStartDate
        // Logic from original SimpleEventBar
        if let start = start {
            self.isStart = calendar.isDate(start, inSameDayAs: date) || calendar.component(.weekday, from: date) == 1
            if self.isStart {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                self.timeString = formatter.string(from: start)
            } else {
                self.timeString = nil
            }
        } else {
            self.isStart = true
            self.timeString = nil
        }
    }
}

struct FullMonthGridView: View {
    let days: [Date]
    let eventSlots: [Date: [CalendarEventProtocol?]]
    let displayedMonth: Date
    let todosByDate: [Date: [TodoItem]]
    
    var onEventSelected: ((CalendarEventProtocol) -> Void)?
    var onDateSelected: ((Date) -> Void)?
    
    // Optimized pre-calculated data
    private let dayInfos: [MonthDayInfo]
    private let precomputedEvents: [TimeInterval: [EventDisplayInfo?]]
    
    private static let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    init(days: [Date], 
         eventSlots: [Date: [CalendarEventProtocol?]], 
         displayedMonth: Date, 
         todosByDate: [Date: [TodoItem]], 
         onEventSelected: ((CalendarEventProtocol) -> Void)? = nil, 
         onDateSelected: ((Date) -> Void)? = nil) {
        
        self.days = days
        self.eventSlots = eventSlots
        self.displayedMonth = displayedMonth
        self.todosByDate = todosByDate
        self.onEventSelected = onEventSelected
        self.onDateSelected = onDateSelected
        
        let calendar = Calendar.current
        
        self.dayInfos = days.map { 
            MonthDayInfo(date: $0, displayedMonth: displayedMonth, calendar: calendar) 
        }
        
        var eventsDict: [TimeInterval: [EventDisplayInfo?]] = [:]
        for day in days {
            if let events = eventSlots[day] {
                eventsDict[day.timeIntervalSince1970] = events.map { event in
                    guard let event = event else { return nil }
                    return EventDisplayInfo(event: event, date: day, calendar: calendar)
                }
            }
        }
        self.precomputedEvents = eventsDict
    }
    
    var body: some View {
        GeometryReader { geometry in
            let headerHeight: CGFloat = 32
            let availableHeight = geometry.size.height - headerHeight
            let cellHeight = max(60, availableHeight / 6)
            
            VStack(spacing: 0) {
                WeekdayHeaderView()
                    .frame(height: headerHeight)
                
                LazyVGrid(columns: Self.columns, spacing: 0) {
                    ForEach(dayInfos) { info in
                        OptimizedMonthCell(
                            info: info,
                            events: precomputedEvents[info.id] ?? [],
                            todos: todosByDate[Calendar.current.startOfDay(for: info.date)] ?? [],
                            cellHeight: cellHeight,
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
        }
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
    let info: MonthDayInfo
    let events: [EventDisplayInfo?]
    let todos: [TodoItem]
    let cellHeight: CGFloat
    var onEventSelected: ((CalendarEventProtocol) -> Void)?
    var onDateSelected: ((Date) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var maxVisibleItems: Int {
        let headerSpace: CGFloat = 28
        let itemHeight: CGFloat = 18
        let availableForItems = cellHeight - headerSpace
        return max(1, Int(availableForItems / itemHeight))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("\(info.dayNumber)\(info.isFirstDay ? "일" : "")")
                    .font(.system(size: 12, weight: info.isToday ? .bold : .medium))
                    .foregroundColor(info.isCurrentMonth ? (info.isToday ? .white : .primary) : .secondary.opacity(0.3))
                    .padding(4)
                    .background(info.isToday ? Color.blue : Color.clear)
                    .clipShape(Circle())
                Spacer()
            }
            .padding(.top, 4)
            .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 2) {
                ForEach(0..<min(events.count, maxVisibleItems), id: \.self) { index in
                    if let event = events[index] {
                        SimpleEventBar(info: event, onTap: onEventSelected)
                    } else {
                        Color.clear.frame(height: 16)
                    }
                }
                
                let remainingSlots = max(0, maxVisibleItems - events.count)
                ForEach(todos.prefix(remainingSlots), id: \.id) { todo in
                    SimpleTodoBar(title: todo.title)
                }
                
                let totalItems = events.count + todos.count
                if totalItems > maxVisibleItems {
                    Text("+\(totalItems - maxVisibleItems)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(height: cellHeight)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
        .border(Color.primary.opacity(0.1), width: 0.5)
        .contentShape(Rectangle())
        .onTapGesture { onDateSelected?(info.date) }
    }
}

struct SimpleEventBar: View {
    let info: EventDisplayInfo
    var onTap: ((CalendarEventProtocol) -> Void)?
    
    var body: some View {
        HStack(spacing: 4) {
            Text(info.title)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
            Spacer(minLength: 0)
            if let time = info.timeString {
                Text(time)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(info.color.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .padding(.horizontal, 2)
        .contentShape(Rectangle())
        .onTapGesture { onTap?(info.originalEvent) }
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

