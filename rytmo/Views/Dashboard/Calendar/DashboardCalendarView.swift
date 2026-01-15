import SwiftUI
import EventKit
import SwiftData

struct DashboardCalendarView: View {
    @ObservedObject private var calendarManager = CalendarManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.orderIndex) private var allTodos: [TodoItem]
    @State private var selectedDate: Date = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Text("Calendar")
                    .font(.system(size: 28, weight: .bold))
                
                Spacer()
                
                Button {
                    calendarManager.refresh()
                    calendarManager.googleManager.fetchEvents()
                } label: {
                    Label("Sync", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    NotificationCenter.default.post(name: NSNotification.Name("switchToCalendarSettings"), object: nil)
                } label: {
                    Label("Connect Accounts", systemImage: "plus.circle")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Error/Loading States
                    if let googleError = calendarManager.googleManager.error {
                        ErrorBannerView(message: googleError) {
                            calendarManager.googleManager.fetchEvents()
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    if calendarManager.googleManager.isLoading {
                        LoadingBannerView(message: "Syncing Google Calendar...")
                            .padding(.horizontal, 32)
                    }
                    
                    // Connect Calendars Prompt (only when no calendars connected)
                    if !calendarManager.isAuthorized && !calendarManager.googleManager.isAuthorized {
                        ConnectCalendarsView(calendarManager: calendarManager)
                            .padding(.horizontal, 32)
                    }
                    
                    // Main Content: Calendar (Left) + Events/Todos (Right)
                    HStack(alignment: .top, spacing: 24) {
                        // Calendar Grid (Left)
                        CalendarGridView(
                            calendarManager: calendarManager,
                            selectedDate: $selectedDate
                        )
                        .frame(maxWidth: 500)
                        
                        // Events + Todos (Right)
                        SelectedDayEventsView(
                            selectedDate: selectedDate,
                            events: eventsForSelectedDate,
                            todos: todosForSelectedDate
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            calendarManager.checkPermission()
        }
    }
    
    private var eventsForSelectedDate: [CalendarEventProtocol] {
        calendarManager.mergedEvents.filter { event in
            guard let eventDate = event.eventStartDate else { return false }
            return calendar.isDate(eventDate, inSameDayAs: selectedDate)
        }
    }
    
    private var todosForSelectedDate: [TodoItem] {
        allTodos.filter { todo in
            // 완료된 항목은 해당 날짜에서만 표시
            if todo.isCompleted {
                guard let dueDate = todo.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: selectedDate)
            }
            
            // 미완료 + 날짜 미설정: 오늘만 표시
            guard let dueDate = todo.dueDate else {
                return calendar.isDateInToday(selectedDate)
            }
            
            return calendar.isDate(dueDate, inSameDayAs: selectedDate)
        }
    }
}

// MARK: - Supporting Views

struct ErrorBannerView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.1))
        )
    }
}

struct LoadingBannerView: View {
    let message: String
    
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.blue.opacity(0.05))
        )
    }
}

struct ConnectCalendarsView: View {
    @ObservedObject var calendarManager: CalendarManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Connect your Calendars")
                    .font(.headline)
                Spacer()
                if calendarManager.googleManager.isAuthorized {
                    Label("Google Connected", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Text("Connect Apple Calendar or Google Calendar to see your schedule.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button {
                    Task { await calendarManager.requestAccess() }
                } label: {
                    Label(calendarManager.isAuthorized ? "Apple Connected" : "Connect Apple",
                          systemImage: "apple.logo")
                }
                .buttonStyle(.bordered)
                .disabled(calendarManager.isAuthorized)
                
                if calendarManager.googleManager.isAuthorized {
                    Button {
                        Task { await calendarManager.googleManager.requestAccess() }
                    } label: {
                        Label("Google Connected", systemImage: "g.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                } else {
                    Button {
                        Task { await calendarManager.googleManager.requestAccess() }
                    } label: {
                        Label("Connect Google", systemImage: "g.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(calendarManager.googleManager.isLoading)
                }
                
                Spacer()
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

struct DayProgressCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        let endOfDay = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(9 * 3600)
        let totalSeconds = endOfDay.timeIntervalSince(startOfDay)
        let currentSeconds = now.timeIntervalSince(startOfDay)
        let progress = min(max(currentSeconds / totalSeconds, 0), 1)
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Day Progress")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .frame(width: 80, height: 80)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(boxBackgroundColor)
        )
    }
    
    private var boxBackgroundColor: Color {
        colorScheme == .dark ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.black.opacity(0.03)
    }
}

struct QuickStatsCard: View {
    let totalEvents: Int
    let googleConnected: Bool
    let systemConnected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                    Text("\(totalEvents) events")
                        .font(.system(size: 13))
                }
                
                HStack(spacing: 8) {
                    Image(systemName: googleConnected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(googleConnected ? .green : .secondary)
                    Text("Google")
                        .font(.system(size: 13))
                        .foregroundColor(googleConnected ? .primary : .secondary)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: systemConnected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(systemConnected ? .green : .secondary)
                    Text("System")
                        .font(.system(size: 13))
                        .foregroundColor(systemConnected ? .primary : .secondary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(boxBackgroundColor)
        )
    }
    
    private var boxBackgroundColor: Color {
        colorScheme == .dark ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.black.opacity(0.03)
    }
}

