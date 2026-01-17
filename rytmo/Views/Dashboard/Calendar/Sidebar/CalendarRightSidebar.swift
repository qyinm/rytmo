import SwiftUI

struct CalendarRightSidebar: View {
    let selectedDate: Date
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var calendarManager = CalendarManager.shared
    
    @State private var eventTitle: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var isAllDay: Bool = false
    @State private var location: String = ""
    @State private var notes: String = ""
    
    // Updated Selection State
    @State private var selectedCalendar: CalendarInfo = CalendarInfo(
        id: "",
        title: "Select Calendar",
        color: .gray,
        sourceTitle: "",
        type: .system
    )
    @State private var selectedEventColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("일정 만들기")
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                Button {
                    // Close sidebar action (optional)
                } label: {
                    Image(systemName: "sidebar.right")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            Divider()
            
            // Event Creation Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("제목")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("일정 제목", text: $eventTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primary.opacity(0.05))
                            )
                    }
                    
                    // Date & Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("날짜 및 시간")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("종일", isOn: $isAllDay)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        
                        DatePicker("시작", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                        
                        DatePicker("종료", selection: $endDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                    
                    // Calendar Selection (New Custom Dropdown)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("캘린더")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        CalendarSelectorView(
                            selectedCalendar: $selectedCalendar,
                            groups: calendarManager.calendarGroups,
                            selectedColor: $selectedEventColor
                        )
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("위치")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("위치 추가", text: $location)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primary.opacity(0.05))
                            )
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("메모")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $notes)
                            .font(.system(size: 14))
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primary.opacity(0.05))
                            )
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button("취소") {
                            clearForm()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        Button("저장") {
                            createEvent()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(eventTitle.isEmpty)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
            }
        }
        .frame(width: 280)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white)
        .onAppear {
            startDate = selectedDate
            endDate = selectedDate.addingTimeInterval(3600)
            
            // Set initial calendar from available groups
            if selectedCalendar.id.isEmpty {
                if let firstGroup = calendarManager.calendarGroups.first, let firstCal = firstGroup.calendars.first {
                    selectedCalendar = firstCal
                    selectedEventColor = firstCal.color
                }
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            startDate = newDate
            endDate = newDate.addingTimeInterval(3600)
        }
    }
    
    private func clearForm() {
        eventTitle = ""
        location = ""
        notes = ""
        startDate = selectedDate
        endDate = selectedDate.addingTimeInterval(3600)
        isAllDay = false
        // Reset color to calendar default
        selectedEventColor = selectedCalendar.color
    }
    
    private func createEvent() {
        // TODO: Implement event creation logic using selectedCalendar and selectedEventColor
        print("Creating event: \(eventTitle) in \(selectedCalendar.title) with color \(selectedEventColor)")
        clearForm()
    }
}
