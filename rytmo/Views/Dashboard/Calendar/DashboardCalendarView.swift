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
                .padding(8)
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
        HStack(spacing: 12) {
            Text(displayedMonth, format: .dateTime.year().month(.wide))
                .font(.system(size: 18, weight: .semibold))
            
            Spacer()
            
            HStack(spacing: 4) {
                Button(action: onPrevMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderless)
                
                Button("Today", action: onToday)
                    .font(.system(size: 11, weight: .medium))
                
                Button(action: onNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderless)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(calendarManager.calendarGroups) { group in
                    Text(group.sourceTitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, group.id == calendarManager.calendarGroups.first?.id ? 4 : 8)
                        .padding(.bottom, 4)
                    
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 200)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color(nsColor: .controlBackgroundColor).opacity(0.3))
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
            HStack(spacing: 6) {
                Image(systemName: isVisible ? "checkmark.square.fill" : "square")
                    .font(.system(size: 12))
                    .foregroundColor(isVisible ? calendar.color : .secondary.opacity(0.4))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(calendar.color)
                    .frame(width: 10, height: 10)
                
                Text(calendar.title)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
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
