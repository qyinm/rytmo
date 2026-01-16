import SwiftUI

struct CalendarLeftSidebar: View {
    @ObservedObject var calendarManager: CalendarManager
    @Binding var selectedDate: Date
    @Environment(\.colorScheme) var colorScheme
    
    // States for toggles
    @State private var showLocal: Bool = true
    @State private var showGoogle: Bool = true
    @State private var showSystem: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Mini Calendar
            CalendarGridView(
                calendarManager: calendarManager,
                selectedDate: $selectedDate
            )
            .padding(.horizontal, 8)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Schedule Booking Section (Placeholder)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.secondary)
                    Text("일정 잡기")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Image(systemName: "eye")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 16)
            }
            
            // Calendars List
            VStack(alignment: .leading, spacing: 16) {
                // Local Calendar (Rytmo)
                SourceToggleRow(
                    name: "Rytmo",
                    color: .blue,
                    isOn: $showLocal
                )
                
                // Google Calendar
                SourceToggleRow(
                    name: "qusseun@gmail.com", // Placeholder name based on image
                    color: .red,
                    isOn: $showGoogle
                )
                
                // System Calendar
                SourceToggleRow(
                    name: "System",
                    color: .purple,
                    isOn: $showSystem
                )
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Bottom Placeholders (Notion, etc.)
            VStack(alignment: .leading, spacing: 12) {
                Text("승우 Notion")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("Notion 데이터베이스 추가", systemImage: "plus")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            
            // Bottom Icons
            HStack(spacing: 16) {
                Image(systemName: "square.split.2x2")
                Image(systemName: "paperplane")
                Spacer()
                Image(systemName: "questionmark.circle")
            }
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .padding(16)
        }
        .frame(width: 260)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .onChange(of: showLocal) { _, newValue in calendarManager.toggleSource(local: newValue) }
        .onChange(of: showGoogle) { _, newValue in calendarManager.toggleSource(google: newValue) }
        .onChange(of: showSystem) { _, newValue in calendarManager.toggleSource(system: newValue) }
        .onAppear {
            // Sync initial states
            showLocal = calendarManager.showLocal
            showGoogle = calendarManager.showGoogle
            showSystem = calendarManager.showSystem
        }
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
                .toggleStyle(CheckboxToggleStyle()) // Or custom circle style
            
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}
