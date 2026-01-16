import SwiftUI
import SwiftData

struct FullMonthGridView: View {
    @ObservedObject var calendarManager: CalendarManager
    @Binding var displayedMonth: Date
    @Query private var allTodos: [TodoItem]
    
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    private let calendar = CalendarUtils.calendar
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday Header
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.02))
                        .overlay(
                            Rectangle()
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                }
            }
            
            // Calendar Grid
            let days = CalendarUtils.generateDaysInMonth(for: displayedMonth)
            let rows = days.count / 7
            
            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { column in
                            let date = days[row * 7 + column]
                            MonthViewCell(
                                date: date,
                                isToday: calendar.isDateInToday(date),
                                isCurrentMonth: CalendarUtils.isDate(date, inSameMonthAs: displayedMonth),
                                events: CalendarUtils.events(for: date, from: calendarManager.mergedEvents),
                                todos: todosForDate(date)
                            )
                        }
                    }
                }
            }
        }
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func todosForDate(_ date: Date) -> [TodoItem] {
        allTodos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
}
