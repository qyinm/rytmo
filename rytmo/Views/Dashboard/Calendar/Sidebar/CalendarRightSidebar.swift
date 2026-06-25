import SwiftUI
import MapKit
import SwiftData

private enum CalendarRightPanelMode: Equatable {
    case summary
    case create
    case edit
}

struct CalendarRightSidebar: View {
    let selectedDate: Date
    let dayEvents: [CalendarEventProtocol]
    let dayTodos: [TodoItem]
    @Binding var selectedEvent: CalendarEventProtocol?

    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var calendarManager = CalendarManager.shared
    @ObservedObject private var googleCalendarManager = GoogleCalendarManager.shared

    @State private var panelMode: CalendarRightPanelMode = .summary
    @State private var eventTitle: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var isAllDay: Bool = false
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
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

    private var isEditMode: Bool { panelMode == .edit }

    private var canEditSelectedEvent: Bool {
        guard isEditMode else { return false }
        return calendarManager.canWriteEvents(for: selectedCalendar)
    }

    private var selectedCalendarCanWrite: Bool {
        calendarManager.canWriteEvents(for: selectedCalendar)
    }

    private var writableCalendarGroups: [CalendarGroup] {
        calendarManager.calendarGroups.compactMap { group in
            let writableCalendars = group.calendars.filter { calendarManager.canWriteEvents(for: $0) }
            guard !writableCalendars.isEmpty else { return nil }
            return CalendarGroup(
                id: group.id,
                sourceTitle: group.sourceTitle,
                calendars: writableCalendars
            )
        }
    }

    private var firstWritableCalendar: CalendarInfo? {
        writableCalendarGroups.first?.calendars.first
    }

    private var shouldBlockFormForWriteAccess: Bool {
        if isEditMode {
            return !selectedCalendarCanWrite
        }

        return !calendarManager.canWriteAnyCalendar || firstWritableCalendar == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            switch panelMode {
            case .summary:
                summaryContent
            case .create, .edit:
                formContent
            }
        }
        .frame(width: 300)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white)
        .onAppear {
            syncPanelModeWithSelection()
        }
        .onChange(of: selectedDate) { _, _ in
            if panelMode == .create {
                startDate = selectedDate
                endDate = selectedDate.addingTimeInterval(3600)
            }
        }
        .onChange(of: selectedEvent?.eventIdentifier) { _, _ in
            syncPanelModeWithSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewEvent)) { _ in
            beginCreateEvent()
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

    // MARK: - Header

    private var header: some View {
        HStack {
            if panelMode != .summary {
                Button {
                    returnToSummary()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Back to day summary")
                .help("Back to day summary")
            }

            Text(headerTitle)
                .font(.system(size: 16, weight: .bold))

            Spacer()

            if panelMode == .summary {
                if calendarManager.canWriteAnyCalendar {
                    Button {
                        beginCreateEvent()
                    } label: {
                        Label("Add Event", systemImage: "plus")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityLabel("Add event")
                    .help("Create a new event on the selected day")
                }
            } else if isEditMode, canEditSelectedEvent {
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
                        .frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .accessibilityLabel("Event actions")
                .help("Event actions")
            }
        }
        .padding(16)
    }

    private var headerTitle: String {
        switch panelMode {
        case .summary:
            return "Day Overview"
        case .create:
            return "New Event"
        case .edit:
            return "Edit Event"
        }
    }

    // MARK: - Summary

    private var summaryContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                permissionBanner

                SelectedDayEventsView(
                    selectedDate: selectedDate,
                    events: dayEvents,
                    todos: dayTodos,
                    onEventSelected: { event in
                        selectedEvent = event
                        panelMode = .edit
                        setupForm()
                    }
                )
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var permissionBanner: some View {
        if calendarManager.googleNeedsScopeUpgrade {
            readOnlyBanner(
                title: "Read-only Google Calendar",
                message: "You can view events but need write permission to create or edit them.",
                actionTitle: "Enable Editing"
            ) {
                Task { await googleCalendarManager.requestScopeUpgrade() }
            }
        } else if !calendarManager.canWriteAnyCalendar && (!calendarManager.showGoogle && !calendarManager.showSystem) {
            readOnlyBanner(
                title: "No calendars connected",
                message: "Connect Apple or Google Calendar in Settings to see and manage events.",
                actionTitle: "Open Settings"
            ) {
                NotificationCenter.default.post(name: .openSettings, object: nil)
                UserDefaults.standard.set(2, forKey: "lastSettingsTab")
            }
        } else if calendarManager.showGoogle && !googleCalendarManager.isAuthorized && calendarManager.showSystem && !calendarManager.isAuthorized {
            readOnlyBanner(
                title: "Calendar access needed",
                message: "Grant calendar permissions in Settings to view and manage events.",
                actionTitle: "Open Settings"
            ) {
                NotificationCenter.default.post(name: .openSettings, object: nil)
                UserDefaults.standard.set(2, forKey: "lastSettingsTab")
            }
        }
    }

    private func readOnlyBanner(
        title: String,
        message: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: "lock.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.orange)

            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(actionTitle, action: action)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Form

    private var formContent: some View {
        Group {
            if shouldBlockFormForWriteAccess {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Write access required")
                        .font(.headline)
                    Text(writeBlockedMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if calendarManager.googleNeedsScopeUpgrade {
                        Button("Enable Google Calendar Editing") {
                            Task { await googleCalendarManager.requestScopeUpgrade() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Button("Back to Summary") {
                        returnToSummary()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(16)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        titleSection
                        dateAndTimeSection
                        calendarSection
                        locationSection
                        notesSection
                        actionButtons
                    }
                    .padding(16)
                }
            }
        }
    }

    private var writeBlockedMessage: String {
        if selectedCalendar.type == .google && calendarManager.googleNeedsScopeUpgrade {
            return "Google Calendar is connected in read-only mode. Upgrade permissions to create or edit events."
        }
        return "This calendar source does not have write permission. Connect or grant access in Settings."
    }

    private var titleSection: some View {
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
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar")
                .font(.caption)
                .foregroundColor(.secondary)

            CalendarSelectorView(
                selectedCalendar: $selectedCalendar,
                groups: writableCalendarGroups
            )

            if !selectedCalendar.id.isEmpty && !selectedCalendarCanWrite {
                Text("Select a writable calendar to save this event.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var notesSection: some View {
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
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                returnToSummary()
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
            .disabled(eventTitle.isEmpty || !selectedCalendarCanWrite || isSaving)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Mode Management

    private func syncPanelModeWithSelection() {
        if let event = selectedEvent {
            panelMode = .edit
            setupForm(for: event)
        } else if panelMode == .edit {
            panelMode = .summary
        }
    }

    private func beginCreateEvent() {
        guard calendarManager.canWriteAnyCalendar else {
            NotificationCenter.default.post(name: .openSettings, object: nil)
            UserDefaults.standard.set(2, forKey: "lastSettingsTab")
            return
        }
        selectedEvent = nil
        panelMode = .create
        setupForm()
    }

    private func returnToSummary() {
        selectedEvent = nil
        panelMode = .summary
        clearForm()
    }

    private func setupForm(for event: CalendarEventProtocol? = nil) {
        let editingEvent = event ?? selectedEvent

        if let editingEvent {
            eventTitle = editingEvent.eventTitle ?? ""
            startDate = editingEvent.eventStartDate ?? selectedDate
            endDate = editingEvent.eventEndDate ?? selectedDate.addingTimeInterval(3600)
            isAllDay = editingEvent.isAllDay
            location = editingEvent.eventLocation ?? ""
            notes = editingEvent.eventNotes ?? ""

            if let calendarId = editingEvent.calendarId {
                for group in calendarManager.calendarGroups {
                    if let matchingCal = group.calendars.first(where: { $0.id == calendarId }) {
                        selectedCalendar = matchingCal
                        break
                    }
                }
            }
        } else {
            clearForm()
            if !selectedCalendarCanWrite, let firstWritableCalendar {
                selectedCalendar = firstWritableCalendar
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
        guard calendarManager.canWriteEvents(for: selectedCalendar) else {
            errorMessage = writeBlockedMessage
            showError = true
            return
        }
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
                    returnToSummary()
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
        guard calendarManager.canWriteEvents(for: selectedCalendar) else {
            errorMessage = writeBlockedMessage
            showError = true
            return
        }

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
                    returnToSummary()
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

        Task {
            do {
                try await calendarManager.deleteEvent(event: event)

                await MainActor.run {
                    returnToSummary()
                }
            } catch {
                await MainActor.run {
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
                        .accessibilityHidden(true)

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
                        .accessibilityLabel("Start time, \(timeFormatter.string(from: startDate))")
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
                            .accessibilityHidden(true)

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
                        .accessibilityLabel("End time, \(timeFormatter.string(from: endDate))")
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
                .frame(minHeight: 30)
            }

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                if isAllDay {
                    allDayDatePickers
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
                    .accessibilityLabel("Event date, \(dateFormatter.string(from: startDate))")
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
            .frame(minHeight: 30)

            HStack(spacing: 8) {
                Image(systemName: "sun.max")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                Text("All Day")
                    .font(.system(size: 14))

                Spacer()

                Toggle("All day event", isOn: $isAllDay)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .frame(minHeight: 30)
        }
    }

    @ViewBuilder
    private var allDayDatePickers: some View {
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
