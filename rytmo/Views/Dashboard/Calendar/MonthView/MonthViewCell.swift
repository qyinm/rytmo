import SwiftUI

struct MonthViewCell: View {
    let date: Date
    let isToday: Bool
    let isCurrentMonth: Bool
    let events: [CalendarEventProtocol?]
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
                // Show up to 4 items (slots), then + more
                ForEach(0..<min(events.count, 4), id: \.self) { index in
                    if let event = events[index] {
                        EventBarView(
                            title: event.eventTitle ?? "Untitled",
                            color: event.eventColor.opacity(0.8),
                            time: formatTime(for: event),
                            isStart: isEventStart(event),
                            isEnd: isEventEnd(event)
                        )
                    } else {
                        Color.clear.frame(height: 16)
                    }
                }
                
                if events.count < 4 {
                    ForEach(todos.prefix(4 - events.count), id: \.id) { todo in
                        EventBarView(
                            title: todo.title,
                            color: Color.gray.opacity(0.3),
                            time: nil,
                            isStart: true,
                            isEnd: true
                        )
                    }
                }
                
                if (events.count + todos.count) > 4 {
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
        .overlay(
            Rectangle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    private func isEventStart(_ event: CalendarEventProtocol) -> Bool {
        guard let start = event.eventStartDate else { return true }
        return CalendarUtils.calendar.isDate(start, inSameDayAs: date) || CalendarUtils.calendar.component(.weekday, from: date) == 1
    }
    
    private func isEventEnd(_ event: CalendarEventProtocol) -> Bool {
        guard let end = event.eventEndDate else { return true }
        let endOfDay = CalendarUtils.calendar.date(byAdding: .day, value: 1, to: CalendarUtils.calendar.startOfDay(for: date))!
        return end <= endOfDay || CalendarUtils.calendar.component(.weekday, from: date) == 7
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
    
    private func formatTime(for event: CalendarEventProtocol) -> String? {
        guard isEventStart(event), let date = event.eventStartDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct EventBarView: View {
    let title: String
    let color: Color
    let time: String?
    let isStart: Bool
    let isEnd: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .foregroundColor(.primary) // Better contrast on blocks
            
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
            Rectangle()
                .fill(color)
                .cornerRadius(isStart ? 4 : 0, corners: [.topLeft, .bottomLeft])
                .cornerRadius(isEnd ? 4 : 0, corners: [.topRight, .bottomRight])
        )
        .padding(.leading, isStart ? 2 : 0)
        .padding(.trailing, isEnd ? 2 : 0)
    }
}

// Helper for RoundedCorner in macOS/SwiftUI (AppKit)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let p1 = CGPoint(x: rect.minX, y: rect.minY)
        let p2 = CGPoint(x: rect.maxX, y: rect.minY)
        let p3 = CGPoint(x: rect.maxX, y: rect.maxY)
        let p4 = CGPoint(x: rect.minX, y: rect.maxY)
        
        // Top Left
        if corners.contains(.topLeft) {
            path.move(to: CGPoint(x: p1.x, y: p1.y + radius))
            path.addArc(center: CGPoint(x: p1.x + radius, y: p1.y + radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            path.move(to: p1)
        }
        
        // Top Right
        if corners.contains(.topRight) {
            path.addLine(to: CGPoint(x: p2.x - radius, y: p2.y))
            path.addArc(center: CGPoint(x: p2.x - radius, y: p2.y + radius), radius: radius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        } else {
            path.addLine(to: p2)
        }
        
        // Bottom Right
        if corners.contains(.bottomRight) {
            path.addLine(to: CGPoint(x: p3.x, y: p3.y - radius))
            path.addArc(center: CGPoint(x: p3.x - radius, y: p3.y - radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        } else {
            path.addLine(to: p3)
        }
        
        // Bottom Left
        if corners.contains(.bottomLeft) {
            path.addLine(to: CGPoint(x: p4.x + radius, y: p4.y))
            path.addArc(center: CGPoint(x: p4.x + radius, y: p4.y - radius), radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        } else {
            path.addLine(to: p4)
        }
        
        path.closeSubpath()
        return path
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
