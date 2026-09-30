import Foundation

/// Bản nháp khi thêm / sửa công nhân (chỉ ghi vào dữ liệu khi bấm Lưu).
struct WorkerDraft {
    var fullName = ""
    var phone = ""
    var birthYearText = ""
    var gender: Gender = .unknown
    var hometown = ""
    var address = ""
    var idNumber = ""
    var source: WorkerSource = .zalo
    var socialHandle = ""
    var desiredJob = ""
    var company = ""
    var status: WorkerStatus = .new
    var notes = ""

    init() {}

    init(worker: Worker) {
        fullName = worker.fullName
        phone = worker.phone
        birthYearText = worker.birthYear.map(String.init) ?? ""
        gender = worker.gender
        hometown = worker.hometown
        address = worker.address
        idNumber = worker.idNumber
        source = worker.source
        socialHandle = worker.socialHandle
        desiredJob = worker.desiredJob
        company = worker.company
        status = worker.status
        notes = worker.notes
    }

    var trimmedName: String { fullName.trimmingCharacters(in: .whitespacesAndNewlines) }

    var birthYear: Int? {
        guard let value = Int(birthYearText.trimmingCharacters(in: .whitespaces)) else { return nil }
        if (0...99).contains(value) {
            let currentYY = VNDate.calendar.component(.year, from: Date()) % 100
            return value + (value <= currentYY ? 2000 : 1900)
        }
        return (1900...2100).contains(value) ? value : nil
    }

    var canSave: Bool { !trimmedName.isEmpty || !phone.trimmingCharacters(in: .whitespaces).isEmpty }

    func apply(to worker: Worker) {
        worker.fullName = trimmedName
        worker.phone = PhoneNumber.isValid(phone) ? PhoneNumber.normalize(phone) : phone.trimmingCharacters(in: .whitespaces)
        worker.birthYear = birthYear
        worker.gender = gender
        worker.hometown = hometown.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.idNumber = idNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.source = source
        worker.socialHandle = socialHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.desiredJob = desiredJob.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.company = company.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.status = status
        worker.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.touch()
    }

    /// Điền các ô còn trống từ tin nhắn được dán. Trả về số ô đã điền.
    @discardableResult
    mutating func fill(from pasted: SmartPaste.Result) -> Int {
        var filled = 0
        if let phone = pasted.phone, self.phone.isEmpty { self.phone = phone; filled += 1 }
        if let name = pasted.fullName, trimmedName.isEmpty { fullName = name; filled += 1 }
        if let year = pasted.birthYear, birthYearText.isEmpty { birthYearText = String(year); filled += 1 }
        if let town = pasted.hometown, hometown.isEmpty { hometown = town; filled += 1 }
        return filled
    }
}

/// Bản nháp khi thêm / sửa lịch hẹn.
struct AppointmentDraft {
    var date: Date
    var kind: AppointmentKind = .firstDay
    var status: AppointmentStatus = .pending
    var company = ""
    var location = ""
    var notes = ""
    var reminderCodes: Set<Int>

    init(defaultReminders: [Int] = ReminderOption.defaultCodes) {
        date = QuickDate.tomorrow(hour: 7, minute: 0)
        reminderCodes = Set(defaultReminders)
    }

    init(appointment: Appointment) {
        date = appointment.date
        kind = appointment.kind
        status = appointment.status
        company = appointment.company
        location = appointment.location
        notes = appointment.notes
        reminderCodes = Set(appointment.reminderCodes)
    }

    func apply(to appointment: Appointment) {
        appointment.date = date
        appointment.kind = kind
        appointment.status = status
        appointment.company = company.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.reminderCodes = Array(reminderCodes)
    }
}

/// Các mốc thời gian chọn nhanh khi đặt lịch.
enum QuickDate {
    struct Option: Identifiable {
        let title: String
        let date: Date
        var id: String { title }
    }

    static func tomorrow(hour: Int, minute: Int, now: Date = Date(), calendar: Calendar = VNDate.calendar) -> Date {
        let start = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow) ?? tomorrow
    }

    /// Thứ 2 tuần sau (hoặc thứ 2 gần nhất nếu hôm nay chưa tới thứ 2).
    static func nextMonday(hour: Int, minute: Int, now: Date = Date(), calendar: Calendar = VNDate.calendar) -> Date {
        let start = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: start) // 1 = Chủ nhật, 2 = Thứ 2
        let daysUntilMonday = (9 - weekday) % 7
        let monday = calendar.date(byAdding: .day, value: daysUntilMonday == 0 ? 7 : daysUntilMonday, to: start) ?? start
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: monday) ?? monday
    }

    static func options(now: Date = Date()) -> [Option] {
        [
            Option(title: "Sáng mai 7:00", date: tomorrow(hour: 7, minute: 0, now: now)),
            Option(title: "Sáng mai 7:30", date: tomorrow(hour: 7, minute: 30, now: now)),
            Option(title: "Chiều mai 13:30", date: tomorrow(hour: 13, minute: 30, now: now)),
            Option(title: "Tối mai 19:00", date: tomorrow(hour: 19, minute: 0, now: now)),
            Option(title: "Thứ 2 tới 7:00", date: nextMonday(hour: 7, minute: 0, now: now)),
        ]
    }
}
