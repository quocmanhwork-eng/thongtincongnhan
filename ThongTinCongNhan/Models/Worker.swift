import Foundation
import SwiftData

/// Công nhân / ứng viên.
@Model
final class Worker {
    var id: UUID = UUID()
    var fullName: String = ""
    var phone: String = ""
    var birthYear: Int?
    var genderRaw: String = Gender.unknown.rawValue
    /// Quê quán
    var hometown: String = ""
    /// Chỗ ở hiện tại
    var address: String = ""
    /// Số CCCD
    var idNumber: String = ""
    var sourceRaw: String = WorkerSource.zalo.rawValue
    /// Tên Zalo, link Facebook, tên TikTok hoặc người giới thiệu
    var socialHandle: String = ""
    /// Vị trí / công việc mong muốn
    var desiredJob: String = ""
    /// Nhà máy / công ty đang giới thiệu
    var company: String = ""
    var statusRaw: String = WorkerStatus.new.rawValue
    var notes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Appointment.worker)
    var appointments: [Appointment] = []

    init(fullName: String = "", phone: String = "") {
        self.id = UUID()
        self.fullName = fullName
        self.phone = phone
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var gender: Gender {
        get { Gender(rawValue: genderRaw) ?? .unknown }
        set { genderRaw = newValue.rawValue }
    }

    var source: WorkerSource {
        get { WorkerSource(rawValue: sourceRaw) ?? .other }
        set { sourceRaw = newValue.rawValue }
    }

    var status: WorkerStatus {
        get { WorkerStatus(rawValue: statusRaw) ?? .new }
        set { statusRaw = newValue.rawValue }
    }

    var displayName: String {
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "(Chưa có tên)" : name
    }

    var formattedPhone: String { PhoneNumber.format(phone) }

    var age: Int? { VNDate.age(birthYear: birthYear) }

    /// Chữ cái viết tắt cho ảnh đại diện: "Nguyễn Văn An" -> "NA".
    var initials: String {
        let parts = fullName.split(whereSeparator: \.isWhitespace)
        let letters = [parts.first, parts.count > 1 ? parts.last : nil].compactMap { $0?.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    var sortedAppointments: [Appointment] {
        appointments.sorted { $0.date > $1.date }
    }

    /// Lịch hẹn sắp tới gần nhất còn hiệu lực.
    func nextAppointment(after now: Date = Date()) -> Appointment? {
        appointments
            .filter { $0.status.isActive && $0.date >= now }
            .min { $0.date < $1.date }
    }

    func matches(search text: String) -> Bool {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        let digits = query.filter(\.isNumber)
        if digits.count >= 3, PhoneNumber.normalize(phone).contains(digits) { return true }
        return [fullName, company, hometown, address, desiredJob, socialHandle, notes]
            .contains { $0.localizedStandardContains(query) }
    }

    func touch() {
        updatedAt = Date()
    }
}

extension Worker {
    var record: WorkerRecord {
        WorkerRecord(
            id: id,
            fullName: fullName,
            phone: phone,
            birthYear: birthYear,
            gender: genderRaw,
            hometown: hometown,
            address: address,
            idNumber: idNumber,
            source: sourceRaw,
            socialHandle: socialHandle,
            desiredJob: desiredJob,
            company: company,
            status: statusRaw,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            appointments: appointments.sorted { $0.date < $1.date }.map(\.record)
        )
    }

    /// Tạo công nhân mới từ bản sao lưu (chưa chèn vào context).
    convenience init(record: WorkerRecord) {
        self.init(fullName: record.fullName, phone: record.phone)
        id = record.id
        birthYear = record.birthYear
        genderRaw = record.gender
        hometown = record.hometown
        address = record.address
        idNumber = record.idNumber
        sourceRaw = record.source
        socialHandle = record.socialHandle
        desiredJob = record.desiredJob
        company = record.company
        statusRaw = record.status
        notes = record.notes
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }
}
