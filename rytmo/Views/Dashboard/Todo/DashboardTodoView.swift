//
//  DashboardTodoView.swift
//  rytmo
//
//  Created by Sisyphus on 1/12/26.
//

import SwiftUI
import SwiftData

struct DashboardTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.orderIndex) private var todos: [TodoItem]

    @State private var newTaskTitle: String = ""
    @State private var newTaskNotes: String = ""
    @State private var dueDate: Date? = nil
    @State private var showDatePicker: Bool = false
    @State private var showNoteInput: Bool = false
    
    @FocusState private var focusedField: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("My Tasks")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Simplify your day, one task at a time.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.top, 48)
            .padding(.bottom, 32)

            ScrollView {
                VStack(spacing: 32) {
                    // Inline Quick Add Bar (Image 1 inspired)
                    quickAddBar
                    
                    // Task List
                    TodoListView(showHeader: true, compact: false)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .frame(maxWidth: 800)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Quick Add Bar
    
    private var quickAddBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Left Checkbox Placeholder
                Image(systemName: "circle")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary.opacity(0.4))
                
                // Title Input
                TextField("Write a new task...", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .focused($focusedField)
                    .onChange(of: newTaskTitle) { newValue in
                        parseDateFromText(newValue)
                    }
                
                Spacer()
                
                // Note Toggle Button
                Button(action: {
                    withAnimation(.snappy) { showNoteInput.toggle() }
                }) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 14))
                        .foregroundColor(showNoteInput || !newTaskNotes.isEmpty ? .primary : .secondary)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(showNoteInput ? Color.primary.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                
                // Date Picker Button
                Button(action: { showDatePicker = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: dueDate == nil ? "calendar" : "calendar.badge.clock")
                            .font(.system(size: 14))
                        
                        if let date = dueDate {
                            Text(formatDate(date))
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(dueDate == nil ? Color.clear : Color.primary.opacity(0.05))
                    )
                    .foregroundColor(dueDate == nil ? .secondary : .primary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                    datePickerPopover
                }
                
                // Add Button (Only visible when title is not empty)
                if !newTaskTitle.isEmpty {
                    Button(action: createTodo) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            // Expandable Note Input (WYSIWYG Style)
            if showNoteInput {
                Divider()
                    .padding(.horizontal, 16)
                
                ZStack(alignment: .topLeading) {
                    if newTaskNotes.isEmpty {
                        Text("Add notes... (supports rich text)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.top, 0)
                            .padding(.leading, 0)
                            .allowsHitTesting(false)
                    }
                    
                    WYSIWYGNoteEditor(text: $newTaskNotes, placeholder: "")
                        .frame(minHeight: 60)
                }
                .padding(.horizontal, 16)
                .padding(.leading, 30)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(focusedField ? Color.primary.opacity(0.1) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - WYSIWYG Editor (NSTextView Wrapper)
    
    private struct WYSIWYGNoteEditor: NSViewRepresentable {
        @Binding var text: String
        var placeholder: String
        
        func makeNSView(context: Context) -> NSScrollView {
            let scrollView = NSScrollView()
            scrollView.drawsBackground = false
            scrollView.borderType = .noBorder
            scrollView.hasVerticalScroller = false
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            
            let textView = CustomTextView()
            textView.isRichText = true
            textView.isEditable = true
            textView.isSelectable = true
            textView.allowsUndo = true
            textView.font = .systemFont(ofSize: 14)
            textView.textColor = .labelColor
            textView.backgroundColor = .clear
            textView.drawsBackground = false
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textView.textContainerInset = NSSize(width: 0, height: 0)
            textView.textContainer?.lineFragmentPadding = 0
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: 200, height: CGFloat.greatestFiniteMagnitude)
            textView.delegate = context.coordinator
            
            // Fix text visibility and color consistency
            textView.typingAttributes = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
            
            scrollView.documentView = textView
            return scrollView
        }
        
        func updateNSView(_ nsView: NSScrollView, context: Context) {
            guard let textView = nsView.documentView as? CustomTextView else { return }
            
            if textView.string != text {
                textView.string = text
            }
            
            // Sync current theme color
            textView.textColor = .labelColor
            textView.insertionPointColor = .labelColor
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, NSTextViewDelegate {
            var parent: WYSIWYGNoteEditor
            
            init(_ parent: WYSIWYGNoteEditor) {
                self.parent = parent
            }
            
            func textDidChange(_ notification: Notification) {
                guard let textView = notification.object as? NSTextView else { return }
                parent.text = textView.string
            }
        }
    }
    
    // Custom NSTextView to handle intrinsic content size and better behavior
    private class CustomTextView: NSTextView {
        override var intrinsicContentSize: NSSize {
            guard let container = textContainer, let manager = layoutManager else {
                return .zero
            }
            manager.ensureLayout(for: container)
            let usedRect = manager.usedRect(for: container)
            return NSSize(width: NSView.noIntrinsicMetric, height: max(60, usedRect.height))
        }
        
        override func didChangeText() {
            super.didChangeText()
            self.invalidateIntrinsicContentSize()
        }
    }
    
    // MARK: - Date Picker Popover (Full Custom Calendar)
    
    private var datePickerPopover: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule Task")
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 4)
            
            // Quick Options
            VStack(spacing: 4) {
                quickDateOption(title: "Today", systemImage: "sun.max", date: Date())
                quickDateOption(title: "Tomorrow", systemImage: "sunrise", date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                quickDateOption(title: "Next Week", systemImage: "calendar.badge.plus", date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date())
            }
            
            Divider()
            
            // Full Custom Calendar
            CustomCalendarView(selectedDate: Binding(
                get: { dueDate ?? Date() },
                set: { date in
                    dueDate = Calendar.current.startOfDay(for: date)
                    showDatePicker = false
                }
            ))
            .frame(width: 280)
            
            if dueDate != nil {
                Button(action: { dueDate = nil; showDatePicker = false }) {
                    Text("Clear Date")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 312)
    }
    
    private func quickDateOption(title: String, systemImage: String, date: Date) -> some View {
        Button(action: {
            dueDate = Calendar.current.startOfDay(for: date)
            showDatePicker = false
        }) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 12))
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
                Text(formatDate(date))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func parseDateFromText(_ text: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Reset dueDate if text is empty or very short to avoid stale states
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            dueDate = nil
            return
        }
        
        // 1. Explicit short weekday check (Mon, Tue, Wed...)
        let weekDays = [
            ("sun", 1), ("mon", 2), ("tue", 3), ("wed", 4), ("thu", 5), ("fri", 6), ("sat", 7)
        ]
        
        for (dayStr, weekdayIdx) in weekDays {
            // Check for standalone word match
            let pattern = "\\b\(dayStr)\\b"
            if text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                // Find next occurrence of this weekday
                let currentWeekday = calendar.component(.weekday, from: today)
                var daysToAdd = weekdayIdx - currentWeekday
                
                // If it's today (daysToAdd == 0), schedule for today.
                // If it's past (daysToAdd < 0), schedule for next week.
                if daysToAdd < 0 {
                    daysToAdd += 7
                }
                
                if let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) {
                    dueDate = nextDate
                    return // Found a match, stop parsing
                }
            }
        }

        // 2. Use NSDataDetector for natural language parsing
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return }
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        
        if let match = matches.first, let date = match.date {
            let targetDate = calendar.startOfDay(for: date)
            
            // Smart correction for past dates
            if targetDate < today {
                // If it's likely a weekday reference (within last 7 days), move to next week
                if let daysDiff = calendar.dateComponents([.day], from: targetDate, to: today).day, daysDiff < 7 {
                     if let nextOccurrence = calendar.date(byAdding: .day, value: 7, to: targetDate) {
                        dueDate = nextOccurrence
                    }
                } else {
                    // For specific past dates (e.g. "Jan 1" when it's June), user might mean next year
                    // But simpler to just keep as-is or let user correct manually.
                    // For now, we trust explicit dates unless they look like "last Friday"
                    dueDate = targetDate
                }
            } else {
                dueDate = targetDate
            }
        } else {
            // No match found -> clear previously set date if it came from parsing?
            // UX decision: For now, if user deletes the keyword, we clear the date.
            // But checking "no match" is tricky because "Meeting" has no match but we want to keep "Fri" result?
            // Actually, parseDateFromText is called on EVERY change.
            // If we didn't find a match in THIS text, we should probably clear it IF the previous date came from text.
            // But we don't know source. 
            // Simple approach: If no match found in current text, clear dueDate.
            // This allows removing date by deleting text.
            dueDate = nil
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    private func createTodo() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newTodo = TodoItem(
            title: newTaskTitle,
            notes: newTaskNotes,
            dueDate: dueDate
        )
        modelContext.insert(newTodo)
        
        // Reset fields
        newTaskTitle = ""
        newTaskNotes = ""
        dueDate = nil
        showNoteInput = false
        focusedField = false
    }
}

// MARK: - Full Custom Calendar View (Image 2 style)

private struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth: Date = Date()
    @State private var daysInMonth: [Date?] = []
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
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
            
            // Days
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            action: { selectedDate = date }
                        )
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
            .frame(minHeight: 216) // Fix height to prevent laggy jumps (6 rows * 36px)
        }
        .onAppear {
            updateDays()
        }
        .onChange(of: currentMonth) { _ in
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

private struct CalendarDayView: View {
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

#Preview {
    DashboardTodoView()
        .modelContainer(for: TodoItem.self, inMemory: true)
        .frame(width: 800, height: 600)
}
