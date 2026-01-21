import SwiftUI
import EventKit
import SwiftData

struct DashboardCalendarView: View {
    @ObservedObject private var calendarManager = CalendarManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Query private var allTodos: [TodoItem]
    
    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    @State private var cachedTodosByDate: [Date: [TodoItem]] = [:]
    @State private var selectedEvent: CalendarEventProtocol? = nil
    @State private var updateTask: Task<Void, Never>?
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 0) {
            CalendarLeftSidebarOptimized(
                selectedDate: $selectedDate,
                showGoogle: calendarManager.showGoogle,
                showSystem: calendarManager.showSystem,
                onToggleGoogle: { calendarManager.toggleSource(google: $0) },
                onToggleSystem: { calendarManager.toggleSource(system: $0) }
            )
            
            Divider()
            
            VStack(alignment: .leading, spacing: 0) {
                CalendarHeaderView(
                    displayedMonth: displayedMonth,
                    onPrevMonth: { navigateMonth(-1) },
                    onNextMonth: { navigateMonth(1) },
                    onToday: { navigateToToday() }
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Divider()
                
                FullMonthGridView(
                    days: calendarManager.currentMonthDays,
                    eventSlots: calendarManager.eventSlots,
                    displayedMonth: displayedMonth,
                    todosByDate: cachedTodosByDate,
                    onEventSelected: { event in
                        selectedEvent = event
                        if let date = event.eventStartDate {
                            selectedDate = date
                        }
                    },
                    onDateSelected: { date in
                        selectedEvent = nil
                        selectedDate = date
                    }
                )
                .padding(16)
            }
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color.black : Color.white)
            
            Divider()
            
            CalendarRightSidebar(
                selectedDate: selectedDate,
                selectedEvent: $selectedEvent
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            calendarManager.checkPermission()
            updateTodosCache()
        }
        .onChange(of: allTodos) { _, _ in
            updateTodosCache()
        }
    }
    
    private func navigateMonth(_ delta: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
        calendarManager.currentReferenceDate = displayedMonth
        calendarManager.refresh(date: displayedMonth)
    }
    
    private func navigateToToday() {
        displayedMonth = Date()
        selectedDate = Date()
        calendarManager.currentReferenceDate = displayedMonth
        calendarManager.refresh(date: displayedMonth)
    }
    
    private func updateTodosCache() {
        updateTask?.cancel()
        
        // Capture state on Main Actor
        let todosSnapshot = allTodos
        // Use a local copy of the calendar to ensure consistency and thread safety
        let calendarSnapshot = calendar
        
        updateTask = Task {
            // 1. Prepare lightweight Sendable data on Main Actor (fast)
            // We map to indices so we can reconstruct the objects later without passing non-Sendable items
            let input = todosSnapshot.enumerated().compactMap { index, todo in
                todo.dueDate.map { TodoDateInfo(index: index, date: $0) }
            }
            
            if Task.isCancelled { return }
            
            // 2. Offload heavy grouping and date math to background thread
            let groupedIndices = await Task.detached(priority: .userInitiated) {
                var dict: [Date: [Int]] = [:]
                for item in input {
                    let startOfDay = calendarSnapshot.startOfDay(for: item.date)
                    dict[startOfDay, default: []].append(item.index)
                }
                return dict
            }.value
            
            if Task.isCancelled { return }
            
            // 3. Reconstruct the dictionary on Main Actor
            // This is O(N) but avoids the date math overhead
            var finalDict: [Date: [TodoItem]] = [:]
            for (date, indices) in groupedIndices {
                finalDict[date] = indices.map { todosSnapshot[$0] }
            }
            
            self.cachedTodosByDate = finalDict
        }
    }
}

private struct TodoDateInfo: Sendable {
    let index: Int
    let date: Date
}

struct CalendarHeaderView: View {
    let displayedMonth: Date
    let onPrevMonth: () -> Void
    let onNextMonth: () -> Void
    let onToday: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Text(displayedMonth, format: .dateTime.year().month(.wide))
                    .font(.system(size: 24, weight: .bold))
                
                Button {} label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                Button(action: onPrevMonth) {
                    Image(systemName: "chevron.left")
                }
                
                Button("Today", action: onToday)
                
                Button(action: onNextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

struct CalendarLeftSidebarOptimized: View {
    @Binding var selectedDate: Date
    let showGoogle: Bool
    let showSystem: Bool
    let onToggleGoogle: (Bool) -> Void
    let onToggleSystem: (Bool) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var calendarManager = CalendarManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            MiniCalendarView(selectedDate: $selectedDate)
                .padding(.horizontal, 8)
            
            Divider()
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.secondary)
                    Text("일정 잡기")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Image(systemName: "eye")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 16)
            }
            
            // Calendar list grouped by account
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(calendarManager.calendarGroups) { group in
                        // Group Header
                        Text(group.sourceTitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, group.id == calendarManager.calendarGroups.first?.id ? 0 : 12)
                            .padding(.bottom, 8)
                        
                        // Calendars in group
                        ForEach(group.calendars) { calendar in
                            CalendarVisibilityRow(
                                calendar: calendar,
                                isVisible: calendarManager.isCalendarVisible(calendar.id),
                                onToggle: {
                                    calendarManager.toggleCalendarVisibility(calendar.id)
                                }
                            )
                        }
                        
                        if group.id != calendarManager.calendarGroups.last?.id {
                            Divider()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .frame(width: 260)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
}

struct CalendarVisibilityRow: View {
    let calendar: CalendarInfo
    let isVisible: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isVisible ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14))
                    .foregroundColor(isVisible ? calendar.color : .secondary.opacity(0.5))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(calendar.color)
                    .frame(width: 12, height: 12)
                
                Text(calendar.title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct MiniCalendarView: View {
    @Binding var selectedDate: Date
    @State private var displayedMonth: Date = Date()
    
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    private let calendar = Calendar.current
    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(displayedMonth, format: .dateTime.month(.abbreviated).year())
                    .font(.system(size: 13, weight: .semibold))
                
                Spacer()
                
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(String(symbol.prefix(1)))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            let days = CalendarUtils.generateDaysInMonth(for: displayedMonth)
            LazyVGrid(columns: Self.columns, spacing: 4) {
                ForEach(days, id: \.timeIntervalSince1970) { date in
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let isToday = calendar.isDateInToday(date)
                    let isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
                    
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 11, weight: isToday ? .bold : .regular))
                        .foregroundColor(isCurrentMonth ? (isSelected ? .white : .primary) : .secondary.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .background(isSelected ? Color.blue : Color.clear)
                        .clipShape(Circle())
                        .onTapGesture { selectedDate = date }
                }
            }
        }
        .padding(12)
    }
}

struct SourceToggleRow: View {
    let name: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .controlSize(.mini)
                .toggleStyle(CheckboxToggleStyle())
            
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.system(size: 13))
            
            Spacer()
        }
    }
}
