import SwiftUI

struct CalendarRightSidebar: View {
    let selectedDate: Date
    let selectedEvent: CalendarEventProtocol?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (Date)
            HStack {
                Text(selectedDate, format: .dateTime.month(.wide).day())
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                Button {
                    // Close inspector action (optional)
                } label: {
                    Image(systemName: "sidebar.right")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            Divider()
            
            if let event = selectedEvent {
                // Event Details Mode
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title & Calendar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(event.eventColor)
                                    .frame(width: 12, height: 12)
                                
                                Text(event.sourceName) // e.g. qusseun@gmail.com
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(event.eventTitle ?? "No Title")
                                .font(.system(size: 20, weight: .bold))
                        }
                        
                        // Time Info
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if let start = event.eventStartDate {
                                    Text(start, format: .dateTime.month().day().weekday().hour().minute())
                                }
                                if let end = event.eventEndDate {
                                    Text(end, format: .dateTime.month().day().weekday().hour().minute())
                                        .foregroundColor(.secondary)
                                }
                            }
                            .font(.system(size: 14))
                        }
                        
                        // Participants (Placeholder)
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "person.2")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("참가자")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Me")
                                    .font(.system(size: 14))
                            }
                        }
                        
                        // Location (Placeholder)
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("위치")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Add location")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Description (Placeholder)
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("설명")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Add description")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                }
            } else {
                // Empty / Day Summary Mode
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    Text("Select an event to see details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 280)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white)
    }
}
