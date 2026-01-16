import SwiftUI

struct MonthViewCell: View {
    let date: Date
    let isToday: Bool
    let isCurrentMonth: Bool
    let events: [CalendarEventProtocol]
    let todos: [TodoItem]
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Day Number
            HStack {
                Text("\(CalendarUtils.calendar.component(.day, from: date))\(isFirstDayOfMonth ? "일" : "")")
                    .font(.system(size: 12, weight: isToday ? .bold : .medium))
                    .foregroundColor(dayTextColor)
                    .padding(4)
                    .background(
                        Group {
                            if isToday {
                                Circle()
                                    .fill(Color.blue)
                            }
                        }
                    )
                    .foregroundColor(isToday ? .white : dayTextColor)
                
                Spacer()
            }
            .padding(.top, 4)
            .padding(.horizontal, 4)
            
            // Events / Todos List
            VStack(alignment: .leading, spacing: 2) {
                // Show up to 3-4 items, then "+ more" if needed
                let combinedItems = combinedDisplayItems
                ForEach(combinedItems.prefix(4), id: \.id) { item in
                    EventBarView(title: item.title, color: item.color, time: item.time)
                }
                
                if combinedItems.count > 4 {
                    Text("+ \(combinedItems.count - 4) more")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    private var isFirstDayOfMonth: Bool {
        CalendarUtils.calendar.component(.day, from: date) == 1
    }
    
    private var dayTextColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.3)
        }
        return .primary
    }
    
    private struct DisplayItem: Identifiable {
        let id: String
        let title: String
        let color: Color
        let time: String?
    }
    
    private var combinedDisplayItems: [DisplayItem] {
        var items: [DisplayItem] = []
        
        // Add Events
        for event in events {
            let timeStr = event.eventStartDate.map { date in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter.string(from: date)
            }
            items.append(DisplayItem(
                id: event.eventIdentifier,
                title: event.eventTitle ?? "Untitled Event",
                color: event.eventColor.opacity(0.2),
                time: timeStr
            ))
        }
        
        // Add Todos
        for todo in todos {
            items.append(DisplayItem(
                id: todo.id.uuidString,
                title: todo.title,
                color: Color.gray.opacity(0.1),
                time: nil
            ))
        }
        
        return items
    }
}

struct EventBarView: View {
    let title: String
    let color: Color
    let time: String?
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            if let time = time {
                Text(time)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
        )
        .padding(.horizontal, 2)
    }
}
