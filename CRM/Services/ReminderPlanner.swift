import Foundation

/// Một mốc nhắc hẹn.
///
/// `code >= 0`: nhắc trước giờ hẹn `code` phút (0 = đúng giờ hẹn).
/// `code < 0`: nhắc vào NGÀY HÔM TRƯỚC lúc `-code` phút tính từ 0 giờ
/// (vd `-1200` = 20:00 tối hôm trước — lúc thích hợp để gọi công nhân xác nhận).
struct ReminderOption: Identifiable, Hashable {
    let code: Int
    var id: Int { code }

    static let eveningBefore = ReminderOption(code: -20 * 60)

    /// Các lựa chọn hiển thị trong app, theo thứ tự từ sớm đến muộn.
    static let all: [ReminderOption] = [-20 * 60, 1440, 180, 120, 60, 30, 15, 0].map(ReminderOption.init(code:))

    /// Mặc định: tối hôm trước 20:00 và trước 1 tiếng.
    static let defaultCodes: [Int] = [-20 * 60, 60]

    var title: String {
        if code == 0 { return "Đúng giờ hẹn" }
        if code > 0 { return "Trước \(VNDate.durationText(minutes: code))" }
        let minuteOfDay = -code
        let clock = String(format: "%02d:%02d", minuteOfDay / 60, minuteOfDay % 60)
        let part = minuteOfDay >= 18 * 60 ? "Tối hôm trước" : (minuteOfDay >= 12 * 60 ? "Chiều hôm trước" : "Sáng hôm trước")
        return "\(part) (\(clock))"
    }

    /// Thời điểm bắn thông báo cho một lịch hẹn.
    static func fireDate(for appointmentDate: Date, code: Int, calendar: Calendar = VNDate.calendar) -> Date? {
        if code >= 0 {
            return appointmentDate.addingTimeInterval(TimeInterval(-code * 60))
        }
        let dayStart = calendar.startOfDay(for: appointmentDate)
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dayStart) else { return nil }
        return calendar.date(byAdding: .minute, value: -code, to: previousDay)
    }

    /// "-1200,60" -> [-1200, 60]
    static func parse(_ raw: String) -> [Int] {
        var seen = Set<Int>()
        return raw.split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .filter { seen.insert($0).inserted }
    }

    /// [60, -1200] -> "-1200,60" (sắp xếp theo thứ tự hiển thị)
    static func serialize(_ codes: [Int]) -> String {
        sorted(codes).map(String.init).joined(separator: ",")
    }

    /// Sắp xếp theo thứ tự trong `all`, các mã lạ xếp cuối.
    static func sorted(_ codes: [Int]) -> [Int] {
        let order = Dictionary(uniqueKeysWithValues: all.enumerated().map { ($1.code, $0) })
        return Array(Set(codes)).sorted { (order[$0] ?? Int.max, -$0) < (order[$1] ?? Int.max, -$1) }
    }
}

/// Bản chụp dữ liệu một lịch hẹn, tách khỏi SwiftData để lập lịch thông báo.
struct AppointmentSnapshot: Equatable {
    var id: UUID
    var date: Date
    var kindTitle: String
    var workerName: String
    var phone: String
    var company: String
    var location: String
    var reminderCodes: [Int]
    var isActive: Bool
}

/// Một thông báo cần đặt lịch.
struct PlannedReminder: Equatable {
    var identifier: String
    var appointmentID: UUID
    var fireDate: Date
    var title: String
    var subtitle: String
    var body: String
}

enum ReminderPlanner {
    static let identifierPrefix = "appt-"

    /// iOS chỉ giữ tối đa 64 thông báo chờ cho mỗi app; chừa lại chỗ cho "nhắc lại sau".
    static let maxPending = 58

    /// Lập danh sách thông báo sắp tới, ưu tiên những cái gần nhất.
    static func plan(
        _ snapshots: [AppointmentSnapshot],
        now: Date = Date(),
        limit: Int = maxPending,
        calendar: Calendar = VNDate.calendar
    ) -> [PlannedReminder] {
        var reminders: [PlannedReminder] = []
        for snapshot in snapshots where snapshot.isActive {
            for code in ReminderOption.sorted(snapshot.reminderCodes) {
                guard let fireDate = ReminderOption.fireDate(for: snapshot.date, code: code, calendar: calendar),
                      fireDate > now
                else { continue }
                reminders.append(makeReminder(snapshot, code: code, fireDate: fireDate, calendar: calendar))
            }
        }
        reminders.sort { ($0.fireDate, $0.identifier) < ($1.fireDate, $1.identifier) }
        return Array(reminders.prefix(max(0, limit)))
    }

    static func identifier(appointmentID: UUID, code: Int) -> String {
        "\(identifierPrefix)\(appointmentID.uuidString)_\(code)"
    }

    private static func makeReminder(_ s: AppointmentSnapshot, code: Int, fireDate: Date, calendar: Calendar) -> PlannedReminder {
        let name = s.workerName.isEmpty ? "Công nhân" : s.workerName
        let title = "\(s.kindTitle): \(name)"

        let time = VNDate.time(s.date, calendar: calendar)
        let subtitle: String
        if code == 0 {
            subtitle = "Đến giờ hẹn \(time) rồi!"
        } else {
            let dayGap = VNDate.dayDifference(from: fireDate, to: s.date, calendar: calendar)
            let lead = VNDate.durationText(minutes: Int((s.date.timeIntervalSince(fireDate) / 60).rounded()))
            switch dayGap {
            case 0: subtitle = "Hôm nay lúc \(time) · còn \(lead)"
            case 1: subtitle = "Ngày mai lúc \(time) (\(VNDate.weekday(s.date, calendar: calendar)), \(VNDate.dayMonth(s.date, calendar: calendar)))"
            default: subtitle = "\(VNDate.timeAndDay(s.date, calendar: calendar)) · còn \(lead)"
            }
        }

        var lines: [String] = []
        let place = [s.company, s.location].filter { !$0.isEmpty }.joined(separator: " – ")
        if !place.isEmpty { lines.append("Tại: \(place)") }
        if !s.phone.isEmpty { lines.append("SĐT: \(PhoneNumber.format(s.phone))") }
        lines.append(code == 0 ? "Kiểm tra công nhân đã có mặt chưa." : "Gọi xác nhận để công nhân không lỡ hẹn.")

        return PlannedReminder(
            identifier: identifier(appointmentID: s.id, code: code),
            appointmentID: s.id,
            fireDate: fireDate,
            title: title,
            subtitle: subtitle,
            body: lines.joined(separator: "\n")
        )
    }
}
