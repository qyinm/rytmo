//
//  DayCellView.swift
//  rytmo
//
//  Shared day cell component for calendar views
//

import SwiftUI

/// Visual style variant for DayCellView
enum DayCellVariant {
    case dashboard  // Light background, accent colors
    case notch      // Dark background, white text
}

/// Unified day cell view for both Dashboard and Notch calendar views
struct DayCellView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let events: [CalendarEventProtocol]
    let variant: DayCellVariant
    
    init(
        date: Date,
        isSelected: Bool,
        isToday: Bool,
        isCurrentMonth: Bool,
        events: [CalendarEventProtocol] = [],
        variant: DayCellVariant = .dashboard
    ) {
        self.date = date
        self.isSelected = isSelected
        self.isToday = isToday
        self.isCurrentMonth = isCurrentMonth
        self.events = events
        self.variant = variant
    }
    
    /// Convenience initializer for notch variant with hasEvents
    init(
        date: Date,
        isSelected: Bool,
        isToday: Bool,
        isCurrentMonth: Bool,
        hasEvents: Bool
    ) {
        self.date = date
        self.isSelected = isSelected
        self.isToday = isToday
        self.isCurrentMonth = isCurrentMonth
        self.events = hasEvents ? [PlaceholderEvent()] : []
        self.variant = .notch
    }
    
    var body: some View {
        switch variant {
        case .dashboard:
            dashboardVariant
        case .notch:
            notchVariant
        }
    }
    
    // MARK: - Dashboard Variant
    
    private var dashboardVariant: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 32, height: 32)
                } else if isToday {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }
                
                Text("\(CalendarUtils.calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday || isSelected ? .semibold : .regular))
                    .foregroundColor(dashboardDayTextColor)
            }
            .frame(width: 36, height: 36)
            
            if !events.isEmpty {
                HStack(spacing: 3) {
                    ForEach(events.prefix(3), id: \.eventIdentifier) { event in
                        Circle()
                            .fill(event.eventColor)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            } else {
                Spacer()
                    .frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var dashboardDayTextColor: Color {
        if isSelected {
            return .white
        } else if !isCurrentMonth {
            return .secondary.opacity(0.4)
        } else if isToday {
            return .accentColor
        } else {
            return .primary
        }
    }
    
    // MARK: - Notch Variant
    
    private var notchVariant: some View {
        VStack(spacing: 1) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                } else if isToday {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                        .frame(width: 18, height: 18)
                }
                
                Text("\(CalendarUtils.calendar.component(.day, from: date))")
                    .font(.system(size: 9, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundColor(notchDayTextColor)
            }
            
            if !events.isEmpty && !isSelected {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 3, height: 3)
            } else {
                Spacer().frame(height: 3)
            }
        }
        .frame(height: 24)
        .contentShape(Rectangle())
    }
    
    private var notchDayTextColor: Color {
        if isSelected {
            return .black
        } else if !isCurrentMonth {
            return .secondary.opacity(0.3)
        } else {
            return .white
        }
    }
}

// MARK: - Placeholder Event for hasEvents compatibility

private struct PlaceholderEvent: CalendarEventProtocol {
    var eventIdentifier: String { UUID().uuidString }
    var eventTitle: String? { nil }
    var eventStartDate: Date? { nil }
    var eventEndDate: Date? { nil }
    var eventColor: Color { .accentColor }
    var sourceName: String { "" }
    
    // Additional properties
    var isAllDay: Bool { false }
    var eventLocation: String? { nil }
    var eventNotes: String? { nil }
    var calendarId: String? { nil }
}
