import Foundation

/// Tệp sao lưu toàn bộ dữ liệu (JSON). Dùng để chuyển sang máy mới hoặc phòng khi mất máy.
struct BackupFile: Codable, Equatable {
    var app: String = BackupFile.appIdentifier
    var version: Int = 1
    var exportedAt: Date
    var workers: [WorkerRecord]

    static let appIdentifier = "ThongTinCongNhan"
}

struct WorkerRecord: Codable, Equatable {
    var id: UUID
    var fullName: String
    var phone: String
    var birthYear: Int?
    var gender: String
    var hometown: String
    var address: String
    var idNumber: String
    var source: String
    var socialHandle: String
    var desiredJob: String
    var company: String
    var status: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var appointments: [AppointmentRecord]
}

struct AppointmentRecord: Codable, Equatable {
    var id: UUID
    var date: Date
    var kind: String
    var status: String
    var company: String
    var location: String
    var notes: String
    var reminderCodes: [Int]
    var createdAt: Date
}

// Giải mã "dễ tính": thiếu trường nào thì lấy giá trị mặc định, để bản sao lưu cũ vẫn khôi phục được.
extension WorkerRecord {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        fullName = try c.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        phone = try c.decodeIfPresent(String.self, forKey: .phone) ?? ""
        birthYear = try c.decodeIfPresent(Int.self, forKey: .birthYear)
        gender = try c.decodeIfPresent(String.self, forKey: .gender) ?? Gender.unknown.rawValue
        hometown = try c.decodeIfPresent(String.self, forKey: .hometown) ?? ""
        address = try c.decodeIfPresent(String.self, forKey: .address) ?? ""
        idNumber = try c.decodeIfPresent(String.self, forKey: .idNumber) ?? ""
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? WorkerSource.other.rawValue
        socialHandle = try c.decodeIfPresent(String.self, forKey: .socialHandle) ?? ""
        desiredJob = try c.decodeIfPresent(String.self, forKey: .desiredJob) ?? ""
        company = try c.decodeIfPresent(String.self, forKey: .company) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? WorkerStatus.new.rawValue
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        appointments = try c.decodeIfPresent([AppointmentRecord].self, forKey: .appointments) ?? []
    }
}

extension AppointmentRecord {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        kind = try c.decodeIfPresent(String.self, forKey: .kind) ?? AppointmentKind.other.rawValue
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? AppointmentStatus.pending.rawValue
        company = try c.decodeIfPresent(String.self, forKey: .company) ?? ""
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        reminderCodes = try c.decodeIfPresent([Int].self, forKey: .reminderCodes) ?? ReminderOption.defaultCodes
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

enum BackupCodec {
    enum BackupError: LocalizedError {
        case notABackup

        var errorDescription: String? {
            "Tệp này không phải bản sao lưu của app Quản lý công nhân."
        }
    }

    static func encode(_ file: BackupFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(file)
    }

    static func decode(_ data: Data) throws -> BackupFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file: BackupFile
        do {
            file = try decoder.decode(BackupFile.self, from: data)
        } catch {
            throw BackupError.notABackup
        }
        guard file.app == BackupFile.appIdentifier else { throw BackupError.notABackup }
        return file
    }

    /// Tên tệp kèm ngày giờ, vd "CongNhan_2026-09-30_0730.json".
    static func fileName(prefix: String, ext: String, date: Date = Date(), calendar: Calendar = VNDate.calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let stamp = String(format: "%04d-%02d-%02d_%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0)
        return "\(prefix)_\(stamp).\(ext)"
    }
}

/// Xuất dữ liệu ra CSV mở được bằng Excel / Google Sheets / Numbers.
enum CSVExport {
    /// UTF-8 BOM giúp Excel hiển thị đúng tiếng Việt có dấu.
    static let byteOrderMark = "\u{FEFF}"

    static func escape(_ field: String) -> String {
        let needsQuotes = field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" || $0 == ";" })
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }

    /// Giữ nguyên chuỗi số (vd CCCD có số 0 ở đầu) khi mở bằng Excel.
    static func keepAsText(_ digits: String) -> String {
        let trimmed = digits.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.allSatisfy({ ("0"..."9").contains($0) }) else { return trimmed }
        return "=\"\(trimmed)\""
    }

    static func document(header: [String], rows: [[String]]) -> String {
        let lines = ([header] + rows).map { $0.map(escape).joined(separator: ",") }
        return byteOrderMark + lines.joined(separator: "\r\n") + "\r\n"
    }

    static func workers(_ workers: [WorkerRecord], now: Date = Date(), calendar: Calendar = VNDate.calendar) -> String {
        let header = [
            "STT", "Họ và tên", "SĐT", "Năm sinh", "Giới tính", "Quê quán", "Chỗ ở hiện tại", "CCCD",
            "Nguồn", "Zalo/Facebook/TikTok", "Vị trí mong muốn", "Nhà máy/Công ty", "Trạng thái",
            "Lịch hẹn sắp tới", "Số lịch hẹn", "Ghi chú", "Ngày thêm",
        ]
        let rows = workers.enumerated().map { index, w -> [String] in
            let next = w.appointments
                .filter { $0.date >= now && (AppointmentStatus(rawValue: $0.status)?.isActive ?? false) }
                .min { $0.date < $1.date }
            let nextText = next.map { "\(VNDate.time($0.date, calendar: calendar)) \(VNDate.shortDate($0.date, calendar: calendar)) - \(AppointmentKind(rawValue: $0.kind)?.title ?? $0.kind)" } ?? ""
            return [
                String(index + 1),
                w.fullName,
                PhoneNumber.format(w.phone),
                w.birthYear.map(String.init) ?? "",
                Gender(rawValue: w.gender)?.title ?? w.gender,
                w.hometown,
                w.address,
                keepAsText(w.idNumber),
                WorkerSource(rawValue: w.source)?.title ?? w.source,
                w.socialHandle,
                w.desiredJob,
                w.company,
                WorkerStatus(rawValue: w.status)?.title ?? w.status,
                nextText,
                String(w.appointments.count),
                w.notes,
                VNDate.shortDate(w.createdAt, calendar: calendar),
            ]
        }
        return document(header: header, rows: rows)
    }

    static func appointments(_ workers: [WorkerRecord], calendar: Calendar = VNDate.calendar) -> String {
        let header = ["Ngày", "Giờ", "Thứ", "Họ và tên", "SĐT", "Loại hẹn", "Nhà máy/Công ty", "Địa điểm", "Trạng thái", "Ghi chú"]
        let pairs = workers.flatMap { w in w.appointments.map { (worker: w, appointment: $0) } }
            .sorted { $0.appointment.date < $1.appointment.date }
        let rows = pairs.map { pair -> [String] in
            let a = pair.appointment
            return [
                VNDate.shortDate(a.date, calendar: calendar),
                VNDate.time(a.date, calendar: calendar),
                VNDate.weekday(a.date, calendar: calendar),
                pair.worker.fullName,
                PhoneNumber.format(pair.worker.phone),
                AppointmentKind(rawValue: a.kind)?.title ?? a.kind,
                a.company,
                a.location,
                AppointmentStatus(rawValue: a.status)?.title ?? a.status,
                a.notes,
            ]
        }
        return document(header: header, rows: rows)
    }
}
