import SwiftUI
import EventKit

struct CalendarTabView: View {
    @StateObject private var calendarManager = CalendarManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                NotchCalendarListView()
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Today")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                NotchCalendarTimelineView()
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
        }
        .padding(.horizontal, 4)
        .onAppear {
            calendarManager.checkPermission()
        }
    }
}

struct NotchCalendarListView: View {
    @ObservedObject var calendarManager = CalendarManager.shared
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 2) {
                if !calendarManager.isAuthorized && calendarManager.showSystem {
                    Button("Grant Access") {
                        Task { await calendarManager.requestAccess() }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.accentColor)
                    .padding(.top, 10)
                } else if calendarManager.mergedEvents.isEmpty {
                    Text("No events today")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                } else {
                    ForEach(calendarManager.mergedEvents.prefix(4), id: \.eventIdentifier) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Capsule()
                                    .fill(event.eventColor)
                                    .frame(width: 3, height: 12)
                                
                                Text(event.eventTitle ?? "Untitled")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            
                            HStack {
                                if let startDate = event.eventStartDate {
                                    Text(startDate, style: .time)
                                }
                                Text("•")
                                Text(event.sourceName)
                            }
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .padding(.leading, 9)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

struct NotchCalendarTimelineView: View {
    @ObservedObject var calendarManager = CalendarManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            let now = Date()
            let hour = Calendar.current.component(.hour, from: now)
            
            VStack(spacing: 4) {
                Text("\(hour):\(String(format: "%02d", Calendar.current.component(.minute, from: now)))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(now, format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)
            
            Spacer()
            
            let startOfDay = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
            let endOfDay = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
            let totalSeconds = endOfDay.timeIntervalSince(startOfDay)
            let currentSeconds = now.timeIntervalSince(startOfDay)
            let progress = min(max(currentSeconds / totalSeconds, 0), 1)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Work Day")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.accentColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(.bottom, 10)
        }
    }
}
