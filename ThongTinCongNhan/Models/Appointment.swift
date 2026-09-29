import Foundation
import SwiftData

/// Lịch hẹn với công nhân (đi làm, phỏng vấn, đưa đón...).
@Model
final class Appointment {
    var id: UUID = UUID()
    var date: Date = Date()
    var kindRaw: String = AppointmentKind.firstDay.rawValue
    var statusRaw: String = AppointmentStatus.pending.rawValue
    /// Nhà máy / công ty
    var company: String = ""
    /// Địa điểm hẹn / điểm đón
    var location: String = ""
    var notes: String = ""
    /// Các mốc nhắc, lưu dạng "-1200,60" (xem `ReminderOption`).
    var remindersRaw: String = "-1200,60"
    var createdAt: Date = Date()

    var worker: Worker?

    init(date: Date, kind: AppointmentKind = .firstDay) {
        self.id = UUID()
        self.date = date
        self.kindRaw = kind.rawValue
        self.createdAt = Date()
    }

    var kind: AppointmentKind {
        get { AppointmentKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var status: AppointmentStatus {
        get { AppointmentStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var reminderCodes: [Int] {
        get { ReminderOption.parse(remindersRaw) }
        set { remindersRaw = ReminderOption.serialize(newValue) }
    }

    var workerName: String { worker?.displayName ?? "(Đã xóa công nhân)" }

    /// Nhà máy + địa điểm gộp lại để hiển thị.
    var placeText: String {
        [company, location]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " – ")
    }

    /// Đã qua giờ hẹn nhưng chưa cập nhật kết quả (đến / không đến).
    func isOverdue(now: Date = Date()) -> Bool {
        status.isActive && date < now
    }

    func matches(search text: String) -> Bool {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        if let worker, worker.matches(search: query) { return true }
        return [company, location, notes, kind.title].contains { $0.localizedStandardContains(query) }
    }

    var snapshot: AppointmentSnapshot {
        AppointmentSnapshot(
            id: id,
            date: date,
            kindTitle: kind.title,
            workerName: worker?.fullName ?? "",
            phone: worker?.phone ?? "",
            company: company,
            location: location,
            reminderCodes: reminderCodes,
            isActive: status.isActive && worker != nil
        )
    }

    var messageValues: MessageTemplate.Values {
        MessageTemplate.Values(
            fullName: worker?.fullName ?? "",
            kind: kind,
            date: date,
            company: company,
            location: location
        )
    }
}

extension Appointment {
    var record: AppointmentRecord {
        AppointmentRecord(
            id: id,
            date: date,
            kind: kindRaw,
            status: statusRaw,
            company: company,
            location: location,
            notes: notes,
            reminderCodes: reminderCodes,
            createdAt: createdAt
        )
    }

    /// Tạo lịch hẹn từ bản sao lưu (chưa chèn vào context).
    convenience init(record: AppointmentRecord) {
        self.init(date: record.date)
        id = record.id
        kindRaw = record.kind
        statusRaw = record.status
        company = record.company
        location = record.location
        notes = record.notes
        reminderCodes = record.reminderCodes
        createdAt = record.createdAt
    }
}
