import SwiftUI
import EventKit
import SwiftData

struct DashboardCalendarView: View {
    @ObservedObject private var calendarManager = CalendarManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.orderIndex) private var allTodos: [TodoItem]
    
    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    @State private var selectedEvent: CalendarEventProtocol? // New selection state
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. Left Sidebar (Navigation & Filters)
            CalendarLeftSidebar(
                calendarManager: calendarManager,
                selectedDate: $selectedDate
            )
            
            Divider()
            
            // 2. Main Calendar Area
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Text(displayedMonth, format: .dateTime.year().month(.wide))
                            .font(.system(size: 24, weight: .bold))
                        
                        Button {
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 0) {
                            Button {
                                withAnimation {
                                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                                    calendarManager.currentReferenceDate = displayedMonth
                                    calendarManager.refresh(date: displayedMonth)
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            
                            Button("Today") {
                                withAnimation {
                                    displayedMonth = Date()
                                    selectedDate = Date()
                                    calendarManager.currentReferenceDate = displayedMonth
                                    calendarManager.refresh(date: displayedMonth)
                                }
                            }
                            
                            Button {
                                withAnimation {
                                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                                    calendarManager.currentReferenceDate = displayedMonth
                                    calendarManager.refresh(date: displayedMonth)
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button {
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Divider()
                
                // Full Month Grid
                FullMonthGridView(
                    calendarManager: calendarManager,
                    displayedMonth: $displayedMonth,
                    onEventSelected: { event in
                        selectedEvent = event
                        if let date = event.eventStartDate {
                            selectedDate = date
                        }
                    },
                    onDateSelected: { date in
                        selectedDate = date
                        selectedEvent = nil
                    }
                )
            }
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color.black : Color.white)
            
            Divider()
            
            // 3. Right Sidebar (Inspector)
            CalendarRightSidebar(
                selectedDate: selectedDate,
                selectedEvent: selectedEvent
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            calendarManager.checkPermission()
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

