import SwiftUI
import EventKit

struct DashboardCalendarView: View {
    @StateObject private var calendarManager = CalendarManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                Text("Calendar")
                    .font(.system(size: 28, weight: .bold))
                
                Spacer()
                
                Button {
                    calendarManager.refresh()
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
                VStack(spacing: 32) {
                    if !calendarManager.isAuthorized || calendarManager.mergedEvents.isEmpty || !calendarManager.googleManager.isAuthorized {
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
                            
                            Text("Rytmo supports Apple Calendar (System) and direct Google Calendar integration. Connect your accounts to see your full schedule.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Button {
                                    Task { await calendarManager.requestAccess() }
                                } label: {
                                    Label(calendarManager.isAuthorized ? "Apple Authorized" : "Connect Apple", 
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
                                } else {
                                    Button {
                                        Task { await calendarManager.googleManager.requestAccess() }
                                    } label: {
                                        Label("Connect Google", systemImage: "g.circle.fill")
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                
                                Spacer()
                                
                                Button {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension") {
                                        NSWorkspace.shared.open(url)
                                    }
                                } label: {
                                    Label("System Settings", systemImage: "gear")
                                }
                                .buttonStyle(.plain)
                                .font(.caption)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(boxBackgroundColor)
                        )
                        .padding(.horizontal, 32)
                    }

                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            let now = Date()
                            VStack(alignment: .leading, spacing: 4) {
                                Text(now, format: .dateTime.day().month().year())
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text(now, format: .dateTime.weekday(.wide))
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("\(calendarManager.mergedEvents.count) Events Today", systemImage: "calendar")
                                    .font(.subheadline)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(boxBackgroundColor)
                        )
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Day Progress")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            let now = Date()
                            let startOfDay = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
                            let endOfDay = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
                            let totalSeconds = endOfDay.timeIntervalSince(startOfDay)
                            let currentSeconds = now.timeIntervalSince(startOfDay)
                            let progress = min(max(currentSeconds / totalSeconds, 0), 1)
                            
                            VStack(alignment: .center, spacing: 8) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 8)
                                    Circle()
                                        .trim(from: 0, to: progress)
                                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                    
                                    Text("\(Int(progress * 100))%")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                }
                                .frame(width: 100, height: 100)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Spacer()
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(boxBackgroundColor)
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Schedule")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if calendarManager.mergedEvents.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("No events scheduled for the next 24 hours.")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(boxBackgroundColor)
                            )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(calendarManager.mergedEvents, id: \.eventIdentifier) { event in
                                    HStack(spacing: 16) {
                                        VStack(alignment: .trailing, spacing: 4) {
                                            if let startDate = event.eventStartDate {
                                                Text(startDate, style: .time)
                                                    .font(.system(size: 14, weight: .bold))
                                            }
                                            if let endDate = event.eventEndDate {
                                                Text(endDate, style: .time)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .frame(width: 80)
                                        
                                        Capsule()
                                            .fill(event.eventColor)
                                            .frame(width: 4)
                                            .padding(.vertical, 4)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(event.eventTitle ?? "Untitled")
                                                    .font(.system(size: 16, weight: .semibold))
                                                Text("(\(event.sourceName))")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.03))
                                    )
                                }
                            }
                        }
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
    
    private var boxBackgroundColor: Color {
        colorScheme == .dark ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.black.opacity(0.03)
    }
}
