import Foundation
import SwiftUI

private enum GoogleCalendarDateParser {
    private static let lock = NSLock()
    private static let isoFormatter = ISO8601DateFormatter()
    private static let allDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func parse(dateTime: String?, date: String?) -> Date? {
        lock.lock()
        defer { lock.unlock() }
        if let dateTime {
            return isoFormatter.date(from: dateTime)
        }
        if let date {
            return allDayFormatter.date(from: date)
        }
        return nil
    }
}

struct GoogleCalendarListResource: Codable {
    let items: [GoogleCalendarListItem]?
}

struct GoogleCalendarListItem: Codable {
    let id: String
    let summary: String?
    let backgroundColor: String?
}

struct GoogleCalendarPaginatedResponse: Codable {
    let items: [GoogleCalendarEvent]?
    let nextPageToken: String?
}

struct GoogleCalendarEvent: Codable, CalendarEventProtocol {
    let id: String
    let summary: String?
    let start: GoogleCalendarTime?
    let end: GoogleCalendarTime?
    let htmlLink: String?
    let colorId: String?
    let location: String?
    let description: String?

    var storedCalendarId: String?
    var storedCalendarColorHex: String?

    var storedCalendarColor: Color? {
        if let hex = storedCalendarColorHex {
            return Color(hex: hex)
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case id, summary, start, end, htmlLink, colorId, location, description
        case storedCalendarId, storedCalendarColorHex
    }

    var eventIdentifier: String { id }
    var eventTitle: String? { summary }
    var eventStartDate: Date? { start?.dateValue }

    var eventEndDate: Date? {
        guard let date = end?.dateValue else { return nil }

        if isAllDay {
            return Calendar.current.date(byAdding: .day, value: -1, to: date)
        }

        return date
    }

    var eventColor: Color {
        if let colorId = colorId {
            switch colorId {
            case "1": return Color(hex: "#7986cb")
            case "2": return Color(hex: "#33b679")
            case "3": return Color(hex: "#8e24aa")
            case "4": return Color(hex: "#e67c73")
            case "5": return Color(hex: "#f6c026")
            case "6": return Color(hex: "#f5511d")
            case "7": return Color(hex: "#039be5")
            case "8": return Color(hex: "#616161")
            case "9": return Color(hex: "#3f51b5")
            case "10": return Color(hex: "#0b8043")
            case "11": return Color(hex: "#d60000")
            default: break
            }
        }

        return storedCalendarColor ?? .blue
    }

    var sourceName: String { "Google" }
    var isAllDay: Bool { start?.date != nil }
    var eventLocation: String? { location }
    var eventNotes: String? { description }
    var calendarId: String? { storedCalendarId }
}

struct GoogleCalendarTime: Codable {
    let dateTime: String?
    let date: String?
    private let parsedDateValue: Date?

    init(dateTime: String?, date: String?) {
        self.dateTime = dateTime
        self.date = date
        self.parsedDateValue = GoogleCalendarDateParser.parse(dateTime: dateTime, date: date)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateTime = try container.decodeIfPresent(String.self, forKey: .dateTime)
        let date = try container.decodeIfPresent(String.self, forKey: .date)
        self.init(dateTime: dateTime, date: date)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(dateTime, forKey: .dateTime)
        try container.encodeIfPresent(date, forKey: .date)
    }

    enum CodingKeys: String, CodingKey {
        case dateTime
        case date
    }

    var dateValue: Date? {
        parsedDateValue
    }
}

struct CacheableCalendarInfo: Codable, Sendable {
    let id: String
    let title: String
    let hexColorString: String?
    let sourceTitle: String

    init(from info: CalendarInfo) {
        self.id = info.id
        self.title = info.title
        self.hexColorString = info.hexColorString
        self.sourceTitle = info.sourceTitle
    }

    func toCalendarInfo() -> CalendarInfo {
        CalendarInfo(
            id: id,
            title: title,
            color: Color(hex: hexColorString ?? "#4285F4"),
            hexColorString: hexColorString,
            sourceTitle: sourceTitle,
            type: .google
        )
    }
}
