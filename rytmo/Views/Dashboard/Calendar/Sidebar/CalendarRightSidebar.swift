import SwiftUI
import MapKit

struct CalendarRightSidebar: View {
    let selectedDate: Date
    @Binding var selectedEvent: CalendarEventProtocol?
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var calendarManager = CalendarManager.shared
    
    @State private var eventTitle: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var isAllDay: Bool = false
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var isDeleting: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    @State private var showStartTimePicker: Bool = false
    @State private var showEndTimePicker: Bool = false
    @State private var showStartDatePicker: Bool = false
    @State private var showEndDatePicker: Bool = false
    
    @StateObject private var locationSearchManager = LocationSearchManager()
    @FocusState private var isLocationFocused: Bool
    @State private var showLocationResults: Bool = false
    
    @State private var selectedCalendar: CalendarInfo = CalendarInfo(
        id: "",
        title: "Select Calendar",
        color: .gray,
        sourceTitle: "",
        type: .system
    )
    
    private var isEditMode: Bool { selectedEvent != nil }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(isEditMode ? "Edit Event" : "New Event")
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                // More menu (delete option) - only shown in edit mode
                if isEditMode {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                }
            }
            .padding(16)
            
            Divider()
            
            // Event Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Event Title", text: $eventTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primary.opacity(0.05))
                            )
                    }
                    
                    // Date & Time
                    dateAndTimeSection
                    
                    // Calendar Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        CalendarSelectorView(
                            selectedCalendar: $selectedCalendar,
                            groups: calendarManager.calendarGroups
                        )
                    }
                    
                    // Location
                    locationSection
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $notes)
                            .font(.system(size: 14))
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primary.opacity(0.05))
                            )
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            if isEditMode {
                                selectedEvent = nil
                            } else {
                                clearForm()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        Button {
                            if isEditMode {
                                updateEvent()
                            } else {
                                createEvent()
                            }
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Save")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(eventTitle.isEmpty || (!isEditMode && selectedCalendar.id.isEmpty) || isSaving)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
            }
        }
        .frame(width: 280)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white)
        .onAppear {
            setupForm()
        }
        .onChange(of: selectedDate) { _, newDate in
            if !isEditMode {
                startDate = newDate
                endDate = newDate.addingTimeInterval(3600)
            }
        }
        .onChange(of: selectedEvent?.eventIdentifier) { _, _ in
            setupForm()
        }
        .alert(isEditMode ? "Failed to Update Event" : "Failed to Create Event", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .alert("Delete Event", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete this event?")
        }
    }
    
    private func setupForm() {
        if let event = selectedEvent {
            // Edit mode: populate with event data
            eventTitle = event.eventTitle ?? ""
            startDate = event.eventStartDate ?? Date()
            endDate = event.eventEndDate ?? Date().addingTimeInterval(3600)
            isAllDay = event.isAllDay
            location = event.eventLocation ?? ""
            notes = event.eventNotes ?? ""
            
            // Find and select the calendar for this event
            if let calendarId = event.calendarId {
                for group in calendarManager.calendarGroups {
                    if let matchingCal = group.calendars.first(where: { $0.id == calendarId }) {
                        selectedCalendar = matchingCal
                        break
                    }
                }
            }
        } else {
            // Create mode: reset form
            clearForm()
            
            // Set initial calendar
            if selectedCalendar.id.isEmpty {
                if let firstGroup = calendarManager.calendarGroups.first, let firstCal = firstGroup.calendars.first {
                    selectedCalendar = firstCal
                }
            }
        }
    }
    
    private func clearForm() {
        eventTitle = ""
        location = ""
        notes = ""
        startDate = selectedDate
        endDate = selectedDate.addingTimeInterval(3600)
        isAllDay = false
    }
    
    private func createEvent() {
        guard !selectedCalendar.id.isEmpty else {
            errorMessage = "Please select a calendar."
            showError = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                try await calendarManager.createEvent(
                    title: eventTitle,
                    startDate: startDate,
                    endDate: endDate,
                    isAllDay: isAllDay,
                    calendarInfo: selectedCalendar,
                    location: location.isEmpty ? nil : location,
                    notes: notes.isEmpty ? nil : notes
                )
                
                await MainActor.run {
                    isSaving = false
                    clearForm()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func updateEvent() {
        guard let event = selectedEvent else { return }
        
        isSaving = true
        
        Task {
            do {
                try await calendarManager.updateEvent(
                    event: event,
                    title: eventTitle,
                    startDate: startDate,
                    endDate: endDate,
                    isAllDay: isAllDay,
                    calendarInfo: selectedCalendar,
                    location: location.isEmpty ? nil : location,
                    notes: notes.isEmpty ? nil : notes
                )
                
                await MainActor.run {
                    isSaving = false
                    selectedEvent = nil
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func deleteEvent() {
        guard let event = selectedEvent else { return }
        
        isDeleting = true
        
        Task {
            do {
                try await calendarManager.deleteEvent(event: event)
                
                await MainActor.run {
                    isDeleting = false
                    selectedEvent = nil
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .topLeading) {
                TextField("Add Location", text: $location)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.05))
                    )
                    .focused($isLocationFocused)
                    .onChange(of: location) { _, newValue in
                        locationSearchManager.queryFragment = newValue
                        showLocationResults = !newValue.isEmpty
                    }
                
                if isLocationFocused && showLocationResults && !locationSearchManager.results.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(locationSearchManager.results, id: \.self) { result in
                                Button {
                                    location = result.title
                                    showLocationResults = false
                                    isLocationFocused = false
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white)
                    .cornerRadius(6)
                    .shadow(radius: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .offset(y: 35)
                    .zIndex(10)
                }
            }
            .zIndex(10)
        }
        .zIndex(10)
    }
    
    @ViewBuilder
    private var dateAndTimeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Date & Time")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            if !isAllDay {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    HStack(spacing: 0) {
                        Button {
                            showStartTimePicker.toggle()
                        } label: {
                            Text(timeFormatter.string(from: startDate))
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showStartTimePicker, arrowEdge: .bottom) {
                            TimeSlotPicker(date: Binding(
                                get: { startDate },
                                set: { newDate in
                                    let duration = endDate.timeIntervalSince(startDate)
                                    startDate = newDate
                                    endDate = newDate.addingTimeInterval(duration)
                                }
                            )) {
                                showStartTimePicker = false
                            }
                        }
                        
                        Text("→")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        Button {
                            showEndTimePicker.toggle()
                        } label: {
                            Text(timeFormatter.string(from: endDate))
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showEndTimePicker, arrowEdge: .bottom) {
                            TimeSlotPicker(date: Binding(
                                get: { endDate },
                                set: { newDate in
                                    endDate = newDate
                                    if endDate < startDate {
                                        startDate = endDate
                                    }
                                }
                            )) {
                                showEndTimePicker = false
                            }
                        }
                    }
                    
                    Spacer()
                    
                    let duration = endDate.timeIntervalSince(startDate)
                    if duration > 0 {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 30)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                if isAllDay {
                    Button {
                        showStartDatePicker.toggle()
                    } label: {
                        Text(dateFormatter.string(from: startDate))
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showStartDatePicker, arrowEdge: .bottom) {
                        SidebarCalendarView(selectedDate: Binding(
                            get: { startDate },
                            set: { newDate in
                                startDate = newDate
                                if endDate < startDate {
                                    endDate = startDate
                                }
                            }
                        )) { _ in
                            showStartDatePicker = false
                        }
                    }
                    
                    Text("→")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    Button {
                        showEndDatePicker.toggle()
                    } label: {
                        Text(dateFormatter.string(from: endDate))
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showEndDatePicker, arrowEdge: .bottom) {
                        SidebarCalendarView(selectedDate: Binding(
                            get: { endDate },
                            set: { newDate in
                                endDate = newDate
                                if startDate > endDate {
                                    startDate = endDate
                                }
                            }
                        )) { _ in
                            showEndDatePicker = false
                        }
                    }
                    
                    Text(formatDaysDuration(start: startDate, end: endDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                } else {
                    Button {
                        showStartDatePicker.toggle()
                    } label: {
                        Text(dateFormatter.string(from: startDate))
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showStartDatePicker, arrowEdge: .bottom) {
                        SidebarCalendarView(selectedDate: Binding(
                            get: { startDate },
                            set: { newDate in
                                let duration = endDate.timeIntervalSince(startDate)
                                let calendar = Calendar.current
                                let newYMD = calendar.dateComponents([.year, .month, .day], from: newDate)
                                var startComps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startDate)
                                startComps.year = newYMD.year
                                startComps.month = newYMD.month
                                startComps.day = newYMD.day
                                
                                if let updatedStart = calendar.date(from: startComps) {
                                    startDate = updatedStart
                                    endDate = updatedStart.addingTimeInterval(duration)
                                }
                            }
                        )) { _ in
                            showStartDatePicker = false
                        }
                    }
                    
                    Spacer()
                }
            }
            .frame(height: 30)
            
            HStack(spacing: 8) {
                Image(systemName: "sun.max")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text("All Day")
                    .font(.system(size: 14))
                
                Spacer()
                
                Toggle("", isOn: $isAllDay)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .frame(height: 30)
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d (E)"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }

    private func formatDaysDuration(start: Date, end: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end))
        if let days = components.day {
            return "(\(days + 1) days)"
        }
        return ""
    }
}
