import SwiftUI

struct CalendarSelectorView: View {
    @Binding var selectedCalendar: CalendarInfo
    let groups: [CalendarGroup]
    
    @State private var isPopoverPresented: Bool = false
    
    var body: some View {
        Button {
            isPopoverPresented.toggle()
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(selectedCalendar.color)
                    .frame(width: 12, height: 12)
                
                Text(selectedCalendar.title)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("캘린더 선택")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.03))
                
                Divider()
                
                // Calendar List grouped by account
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(groups) { group in
                            // Group Header
                            HStack {
                                Text(group.sourceTitle)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.primary.opacity(0.02))
                            
                            // Calendars in group
                            ForEach(group.calendars) { calendar in
                                CalendarRowView(
                                    calendar: calendar,
                                    isSelected: calendar.id == selectedCalendar.id,
                                    onSelect: {
                                        selectedCalendar = calendar
                                    }
                                )
                            }
                            
                            if group.id != groups.last?.id {
                                Divider()
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: 280)
                
            }
            .frame(width: 280)
        }
    }
}

// MARK: - Calendar Row View

private struct CalendarRowView: View {
    let calendar: CalendarInfo
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(calendar.color)
                    .frame(width: 12, height: 12)
                
                Text(calendar.title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}
