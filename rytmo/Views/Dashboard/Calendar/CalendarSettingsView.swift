import SwiftUI

struct CalendarSettingsView: View {
    @StateObject private var calendarManager = CalendarManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Connected Calendars")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                ToggleRow(
                    title: "Rytmo Calendar",
                    subtitle: "Internal app events",
                    icon: "calendar.badge.plus",
                    isOn: Binding(
                        get: { calendarManager.showLocal },
                        set: { calendarManager.toggleSource(local: $0) }
                    )
                )
                
                Divider()
                
                ToggleRow(
                    title: "System Calendar",
                    subtitle: "Apple Calendar events",
                    icon: "apple.logo",
                    isOn: Binding(
                        get: { calendarManager.showSystem },
                        set: { calendarManager.toggleSource(system: $0) }
                    )
                )
            }
            .background(Color.primary.opacity(0.03))
            .cornerRadius(12)
            
            if !calendarManager.isAuthorized && calendarManager.showSystem {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("System calendar access is not granted.")
                        .font(.subheadline)
                    Spacer()
                    Button("Grant Access") {
                        Task { await calendarManager.requestAccess() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(32)
    }
    
    struct ToggleRow: View {
        let title: String
        let subtitle: String
        let icon: String
        @Binding var isOn: Bool
        
        var body: some View {
            Toggle(isOn: $isOn) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .toggleStyle(.switch)
        }
    }
}
