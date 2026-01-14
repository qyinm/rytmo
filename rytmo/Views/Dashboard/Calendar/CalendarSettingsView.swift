import SwiftUI

struct CalendarSettingsView: View {
    @StateObject private var calendarManager = CalendarManager.shared
    @StateObject private var googleCalendarManager = GoogleCalendarManager.shared
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Connected Calendars")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                // 1. Rytmo Local Calendar
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
                
                // 2. Apple / System Calendar
                ToggleRow(
                    title: "System Calendar",
                    subtitle: "Apple Calendar / Native account events",
                    icon: "apple.logo",
                    isOn: Binding(
                        get: { calendarManager.showSystem },
                        set: { calendarManager.toggleSource(system: $0) }
                    )
                )
                
                if !calendarManager.isAuthorized && calendarManager.showSystem {
                    permissionActionRow(
                        message: "System calendar access not granted.",
                        buttonTitle: "Grant Access"
                    ) {
                        Task { await calendarManager.requestAccess() }
                    }
                }
                
                Divider()
                
                // 3. Direct Google Calendar Integration
                ToggleRow(
                    title: "Google Calendar",
                    subtitle: "Direct integration with Google API",
                    icon: "g.circle.fill",
                    isOn: Binding(
                        get: { calendarManager.showGoogle },
                        set: { calendarManager.toggleSource(google: $0) }
                    )
                )
                
                if !googleCalendarManager.isAuthorized && calendarManager.showGoogle {
                    permissionActionRow(
                        message: "Google Calendar API access required.",
                        buttonTitle: "Connect Google"
                    ) {
                        Task { await googleCalendarManager.requestAccess() }
                    }
                }
            }
            .background(Color.primary.opacity(0.03))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding(32)
    }
    
    @ViewBuilder
    private func permissionActionRow(message: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button(buttonTitle) {
                action()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
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
