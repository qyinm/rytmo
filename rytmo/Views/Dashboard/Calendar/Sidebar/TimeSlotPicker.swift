import SwiftUI

struct TimeSlotPicker: View {
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
