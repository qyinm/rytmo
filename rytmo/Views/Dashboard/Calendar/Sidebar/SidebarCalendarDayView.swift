import SwiftUI

struct SidebarCalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary)
                        .frame(width: 32, height: 32)
                } else if isHovering {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 32, height: 32)
                }
                
                VStack(spacing: 2) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : (isCurrentMonth ? .primary : .secondary.opacity(0.3)))
                    
                    if isToday && !isSelected {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 3, height: 3)
                    }
                }
            }
            .frame(height: 36)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
