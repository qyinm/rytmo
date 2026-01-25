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
    let showTitle: Bool
    let timeString: String?
    let originalEvent: CalendarEventProtocol
    let continuesFromPrevious: Bool
    let continuesToNext: Bool
    
    init(event: CalendarEventProtocol, date: Date, calendar: Calendar) {
        self.id = event.eventIdentifier
        self.title = event.eventTitle ?? "Untitled"
        self.color = event.eventColor
        self.originalEvent = event
        
        let start = event.eventStartDate
        let end = event.eventEndDate
        let weekday = calendar.component(.weekday, from: date)
        let isFirstDayOfWeek = weekday == 1
        
        let isActualStart = start.map { calendar.isDate($0, inSameDayAs: date) } ?? true
        self.showTitle = isActualStart || isFirstDayOfWeek
        
        if self.showTitle, let start = start, !event.isAllDay {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            self.timeString = formatter.string(from: start)
        } else {
            self.timeString = nil
        }
        
        self.continuesFromPrevious = !isActualStart && !isFirstDayOfWeek
        
        if let end = end {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
            let isLastDayOfWeek = weekday == 7
            
            // For all-day events, end date is inclusive - convert to exclusive for comparison
            let effectiveEnd = event.isAllDay ? calendar.date(byAdding: .day, value: 1, to: end)! : end
            let endsOnThisDay = effectiveEnd <= dayEnd
            self.continuesToNext = !endsOnThisDay && !isLastDayOfWeek
        } else {
            self.continuesToNext = false
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
                    Text("\(info.dayNumber)")
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
    
    private var cornerRadii: RectangleCornerRadii {
        let radius: CGFloat = 3
        return RectangleCornerRadii(
            topLeading: info.continuesFromPrevious ? 0 : radius,
            bottomLeading: info.continuesFromPrevious ? 0 : radius,
            bottomTrailing: info.continuesToNext ? 0 : radius,
            topTrailing: info.continuesToNext ? 0 : radius
        )
    }
    
    var body: some View {
        info.color.opacity(0.85)
            .frame(height: 16)
            .frame(maxWidth: .infinity)
            .clipShape(UnevenRoundedRectangle(cornerRadii: cornerRadii))
            .overlay(alignment: .leading) {
                HStack(spacing: 4) {
                    if info.showTitle {
                        Text(info.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if let time = info.timeString {
                        Text(time)
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.leading, info.continuesFromPrevious ? 2 : 4)
                .padding(.trailing, info.continuesToNext ? 2 : 4)
            }
            .padding(.leading, info.continuesFromPrevious ? 0 : 2)
            .padding(.trailing, info.continuesToNext ? 0 : 2)
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

