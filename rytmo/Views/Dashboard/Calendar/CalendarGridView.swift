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
                        variant: .dashboard
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
