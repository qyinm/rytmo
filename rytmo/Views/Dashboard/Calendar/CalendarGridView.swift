import SwiftUI

// MARK: - Calendar Grid View

struct CalendarGridView: View {
    @ObservedObject var calendarManager: CalendarManager
    @Binding var selectedDate: Date
    @Environment(\.colorScheme) var colorScheme
    
    @State private var displayedMonth: Date = Date()
    
    private let calendar = Calendar.current
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
            let days = generateDaysInMonth(for: displayedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    DayCellView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
                        events: eventsForDate(date),
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
    
    private func generateDaysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        let startDate = monthFirstWeek.start
        let endDate = monthLastWeek.end
        
        var dates: [Date] = []
        var current = startDate
        
        while current < endDate {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        
        return dates
    }
    
    private func eventsForDate(_ date: Date) -> [CalendarEventProtocol] {
        calendarManager.mergedEvents.filter { event in
            guard let eventDate = event.eventStartDate else { return false }
            return calendar.isDate(eventDate, inSameDayAs: date)
        }
    }
}

// MARK: - Calendar Header View

struct CalendarHeaderView: View {
    @Binding var displayedMonth: Date
    let onTodayTapped: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack {
            // Month/Year Display with Navigation
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
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
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
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
    
    private let calendar = Calendar.current
    
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
                
                Text("\(calendar.component(.day, from: date))")
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
    @Environment(\.colorScheme) var colorScheme
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(selectedDate, format: .dateTime.weekday(.wide).month().day())
                    .font(.headline)
                
                Spacer()
                
                Text("\(events.count) events")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if events.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No events")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(events, id: \.eventIdentifier) { event in
                        HStack(spacing: 12) {
                            // Time
                            VStack(alignment: .trailing, spacing: 2) {
                                if let startDate = event.eventStartDate {
                                    Text(startDate, style: .time)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                if let endDate = event.eventEndDate {
                                    Text(endDate, style: .time)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 60)
                            
                            // Color Indicator
                            Capsule()
                                .fill(event.eventColor)
                                .frame(width: 3)
                            
                            // Event Info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.eventTitle ?? "Untitled")
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                                
                                Text(event.sourceName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.03))
                        )
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
