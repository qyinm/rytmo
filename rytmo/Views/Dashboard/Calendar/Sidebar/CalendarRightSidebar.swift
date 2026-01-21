import SwiftUI

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
                Text(isEditMode ? "일정 수정" : "일정 만들기")
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                // More menu (delete option) - only shown in edit mode
                if isEditMode {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("삭제", systemImage: "trash")
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
                
                Button {
                    if isEditMode {
                        selectedEvent = nil
                    }
                } label: {
                    Image(systemName: isEditMode ? "xmark" : "sidebar.right")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            Divider()
            
            // Event Form
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
                    dateAndTimeSection
                    
                    // Calendar Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("캘린더")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        CalendarSelectorView(
                            selectedCalendar: $selectedCalendar,
                            groups: calendarManager.calendarGroups
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
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primary.opacity(0.05))
                            )
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button("취소") {
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
                                Text("저장")
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
        .alert(isEditMode ? "이벤트 수정 실패" : "이벤트 생성 실패", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .alert("이벤트 삭제", isPresented: $showDeleteConfirm) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("이 이벤트를 삭제하시겠습니까?")
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
            errorMessage = "캘린더를 선택해주세요."
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
    private var dateAndTimeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("날짜 및 시간")
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
                
                Text("종일")
                    .font(.system(size: 14))
                
                Spacer()
                
                Toggle("", isOn: $isAllDay)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .frame(height: 30)
            
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text("GMT+9 Seoul")
                    .font(.system(size: 14))
                
                Spacer()
            }
            .foregroundColor(.primary)
            .frame(height: 30)
            
            HStack(spacing: 8) {
                Image(systemName: "repeat")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text("반복 안 함")
                    .font(.system(size: 14))
                
                Spacer()
            }
            .foregroundColor(.primary)
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
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }

    private func formatDaysDuration(start: Date, end: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end))
        if let days = components.day {
            return "(\(days + 1)일)"
        }
        return ""
    }
}

private struct TimeSlotPicker: View {
    @Binding var date: Date
    let onSelect: () -> Void
    
    private let timeSlots: [Date] = {
        var slots: [Date] = []
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        for i in 0..<(24 * 4) {
            if let date = calendar.date(byAdding: .minute, value: i * 15, to: startOfDay) {
                slots.append(date)
            }
        }
        return slots
    }()
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(timeSlots, id: \.self) { slot in
                        Button {
                            updateTime(with: slot)
                            onSelect()
                        } label: {
                            HStack {
                                Text(formatTime(slot))
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                Spacer()
                                if isSelected(slot) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(isSelected(slot) ? Color.primary.opacity(0.1) : Color.clear)
                        .id(slot)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(width: 150, height: 250)
            .onAppear {
                if let nearest = findNearestSlot() {
                    proxy.scrollTo(nearest, anchor: .center)
                }
            }
        }
    }
    
    private func updateTime(with slot: Date) {
        let calendar = Calendar.current
        let slotComps = calendar.dateComponents([.hour, .minute], from: slot)
        
        var targetComps = calendar.dateComponents([.year, .month, .day], from: date)
        targetComps.hour = slotComps.hour
        targetComps.minute = slotComps.minute
        
        if let newDate = calendar.date(from: targetComps) {
            date = newDate
        }
    }
    
    private func isSelected(_ slot: Date) -> Bool {
        let calendar = Calendar.current
        let slotComps = calendar.dateComponents([.hour, .minute], from: slot)
        let dateComps = calendar.dateComponents([.hour, .minute], from: date)
        return slotComps.hour == dateComps.hour && slotComps.minute == dateComps.minute
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func findNearestSlot() -> Date? {
        let calendar = Calendar.current
        let currentComps = calendar.dateComponents([.hour, .minute], from: date)
        let currentMinutes = (currentComps.hour ?? 0) * 60 + (currentComps.minute ?? 0)
        
        return timeSlots.min(by: { a, b in
            let aComps = calendar.dateComponents([.hour, .minute], from: a)
            let bComps = calendar.dateComponents([.hour, .minute], from: b)
            let aMin = (aComps.hour ?? 0) * 60 + (aComps.minute ?? 0)
            let bMin = (bComps.hour ?? 0) * 60 + (bComps.minute ?? 0)
            return abs(aMin - currentMinutes) < abs(bMin - currentMinutes)
        })
    }
}

private struct SidebarCalendarView: View {
    @Binding var selectedDate: Date
    var onDateSelected: ((Date) -> Void)? = nil
    
    @State private var currentMonth: Date = Date()
    @State private var daysInMonth: [Date?] = []
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        SidebarCalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            action: {
                                selectedDate = date
                                onDateSelected?(date)
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
            .frame(minHeight: 216)
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            currentMonth = selectedDate
            updateDays()
        }
        .onChange(of: currentMonth) { _, _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                updateDays()
            }
        }
    }
    
    private func updateDays() {
        daysInMonth = generateDaysInMonth(for: currentMonth)
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start)),
              let monthRange = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return []
        }
        
        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDaysInMonth = monthRange.count
        
        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirstDay - 1)
        
        for day in 0..<numberOfDaysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

private struct SidebarCalendarDayView: View {
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
