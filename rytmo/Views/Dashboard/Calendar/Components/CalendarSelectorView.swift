import SwiftUI

struct CalendarSelectorView: View {
    @Binding var selectedCalendar: CalendarInfo
    let groups: [CalendarGroup]
    @Binding var selectedColor: Color
    
    @State private var isPopoverPresented: Bool = false
    
    // Predefined colors for event color picker
    private let eventColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .gray, .pink
    ]
    
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
                // Header (Current Selection)
                HStack {
                    Text(selectedCalendar.sourceTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.03))
                
                Divider()
                
                // Calendar List
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.sourceTitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                
                                ForEach(group.calendars) { calendar in
                                    Button {
                                        selectedCalendar = calendar
                                        selectedColor = calendar.color // Default to calendar color
                                        // isPopoverPresented = false // Keep open to select color? Or close.
                                    } label: {
                                        HStack(spacing: 8) {
                                            if calendar.id == selectedCalendar.id {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white)
                                                    .frame(width: 16)
                                            } else {
                                                Spacer().frame(width: 16)
                                            }
                                            
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(calendar.color)
                                                .frame(width: 12, height: 12)
                                            
                                            Text(calendar.title)
                                                .font(.system(size: 13))
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(
                                            calendar.id == selectedCalendar.id ? Color.primary.opacity(0.1) : Color.clear
                                        )
                                        .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
                .frame(height: 250)
                
                Divider()
                
                // Color Picker Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("이벤트 색")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        ForEach(eventColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 16, height: 16)
                                    
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.03))
            }
            .frame(width: 260)
        }
    }
}
