import Foundation

/// Định dạng ngày giờ kiểu Việt Nam, không phụ thuộc ngôn ngữ cài đặt của máy.
enum VNDate {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "vi_VN")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    private static let weekdayNames = ["Chủ nhật", "Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7"]

    /// "Thứ 2", "Chủ nhật"...
    static func weekday(_ date: Date, calendar: Calendar = VNDate.calendar) -> String {
        let index = calendar.component(.weekday, from: date) - 1
        return weekdayNames[max(0, min(6, index))]
    }

    /// "07:30"
    static func time(_ date: Date, calendar: Calendar = VNDate.calendar) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    /// "30/09"
    static func dayMonth(_ date: Date, calendar: Calendar = VNDate.calendar) -> String {
        let c = calendar.dateComponents([.day, .month], from: date)
        return String(format: "%02d/%02d", c.day ?? 0, c.month ?? 0)
    }

    /// "30/09/2026"
    static func shortDate(_ date: Date, calendar: Calendar = VNDate.calendar) -> String {
        let c = calendar.dateComponents([.day, .month, .year], from: date)
        return String(format: "%02d/%02d/%04d", c.day ?? 0, c.month ?? 0, c.year ?? 0)
    }

    /// "Thứ 2, 30/09/2026"
    static func longDate(_ date: Date, calendar: Calendar = VNDate.calendar) -> String {
        "\(weekday(date, calendar: calendar)), \(shortDate(date, calendar: calendar))"
    }

    /// "07:30 Thứ 2, 30/09"
    static func timeAndDay(_ date: Date, calendar: Calendar = VNDate.calendar) -> String {
        "\(time(date, calendar: calendar)) \(weekday(date, calendar: calendar)), \(dayMonth(date, calendar: calendar))"
    }

    /// "Hôm nay", "Ngày mai", "Hôm qua" hoặc nil.
    static func relativeDayName(_ date: Date, now: Date = Date(), calendar: Calendar = VNDate.calendar) -> String? {
        let days = dayDifference(from: now, to: date, calendar: calendar)
        switch days {
        case 0: return "Hôm nay"
        case 1: return "Ngày mai"
        case 2: return "Ngày kia"
        case -1: return "Hôm qua"
        default: return nil
        }
    }

    /// "Hôm nay · Thứ 2, 30/09/2026"
    static func sectionTitle(_ date: Date, now: Date = Date(), calendar: Calendar = VNDate.calendar) -> String {
        if let relative = relativeDayName(date, now: now, calendar: calendar) {
            return "\(relative) · \(longDate(date, calendar: calendar))"
        }
        return longDate(date, calendar: calendar)
    }

    /// Số ngày lịch giữa hai thời điểm (không tính giờ).
    static func dayDifference(from start: Date, to end: Date, calendar: Calendar = VNDate.calendar) -> Int {
        let a = calendar.startOfDay(for: start)
        let b = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// "còn 2 giờ 15 phút", "còn 3 ngày", "đã qua 20 phút", "ngay bây giờ".
    static func countdown(to date: Date, now: Date = Date()) -> String {
        let seconds = date.timeIntervalSince(now)
        let minutes = Int((abs(seconds) / 60).rounded())
        if minutes < 1 { return "ngay bây giờ" }
        let text = durationText(minutes: minutes)
        return seconds > 0 ? "còn \(text)" : "đã qua \(text)"
    }

    /// "45 phút", "2 giờ 15 phút", "3 ngày", "1 ngày 4 giờ".
    static func durationText(minutes: Int) -> String {
        let days = minutes / 1440
        let hours = (minutes % 1440) / 60
        let mins = minutes % 60
        if days > 0 {
            return hours > 0 && days < 3 ? "\(days) ngày \(hours) giờ" : "\(days) ngày"
        }
        if hours > 0 {
            return mins > 0 ? "\(hours) giờ \(mins) phút" : "\(hours) giờ"
        }
        return "\(mins) phút"
    }

    /// Tuổi tính theo năm sinh.
    static func age(birthYear: Int?, now: Date = Date(), calendar: Calendar = VNDate.calendar) -> Int? {
        guard let birthYear, birthYear > 1900 else { return nil }
        let year = calendar.component(.year, from: now)
        let age = year - birthYear
        return (0...120).contains(age) ? age : nil
    }
}
