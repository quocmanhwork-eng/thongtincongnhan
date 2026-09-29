import Foundation

/// Soạn tin nhắn nhắc hẹn để gửi cho công nhân qua Zalo / Messenger / SMS.
enum MessageTemplate {
    static let storageKey = "messageTemplate"

    static let defaultTemplate = """
    Chào {ten}, em nhắc lịch {loai} lúc {gio} {ngay} tại {diadiem}. \
    Anh/chị nhớ mang theo CCCD và đến đúng giờ giúp em nhé. Có gì thay đổi thì báo em sớm ạ!
    """

    struct Placeholder: Identifiable {
        let key: String
        let meaning: String
        var id: String { key }
    }

    /// Danh sách từ khóa có thể dùng trong mẫu tin nhắn.
    static let placeholders: [Placeholder] = [
        Placeholder(key: "{ten}", meaning: "Tên gọi (chữ cuối của họ tên)"),
        Placeholder(key: "{hoten}", meaning: "Họ và tên đầy đủ"),
        Placeholder(key: "{loai}", meaning: "Loại hẹn (đi làm ngày đầu, phỏng vấn...)"),
        Placeholder(key: "{gio}", meaning: "Giờ hẹn, vd 07:30"),
        Placeholder(key: "{ngay}", meaning: "Thứ và ngày, vd Thứ 2, 30/09"),
        Placeholder(key: "{congty}", meaning: "Nhà máy / công ty"),
        Placeholder(key: "{diachi}", meaning: "Địa điểm / điểm đón"),
        Placeholder(key: "{diadiem}", meaning: "Nhà máy + địa điểm gộp lại"),
    ]

    struct Values {
        var fullName: String
        var kind: AppointmentKind
        var date: Date
        var company: String
        var location: String
    }

    static func render(_ template: String, values v: Values, calendar: Calendar = VNDate.calendar) -> String {
        let trimmedTemplate = template.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmedTemplate.isEmpty ? defaultTemplate : trimmedTemplate

        let company = v.company.trimmingCharacters(in: .whitespacesAndNewlines)
        let location = v.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let combinedPlace: String
        switch (company.isEmpty, location.isEmpty) {
        case (false, false): combinedPlace = "\(company) (\(location))"
        case (false, true): combinedPlace = company
        case (true, false): combinedPlace = location
        case (true, true): combinedPlace = "địa điểm đã hẹn"
        }

        let replacements: [String: String] = [
            "{ten}": givenName(v.fullName),
            "{hoten}": v.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "{loai}": v.kind.messageTitle,
            "{gio}": VNDate.time(v.date, calendar: calendar),
            "{ngay}": "\(VNDate.weekday(v.date, calendar: calendar)), \(VNDate.dayMonth(v.date, calendar: calendar))",
            "{congty}": company.isEmpty ? "công ty" : company,
            "{diachi}": location.isEmpty ? "địa điểm đã hẹn" : location,
            "{diadiem}": combinedPlace,
        ]
        var result = source
        for (key, value) in replacements {
            result = result.replacingOccurrences(of: key, with: value)
        }
        return result
    }

    /// Tên gọi theo kiểu Việt Nam: "Nguyễn Văn An" -> "An".
    static func givenName(_ fullName: String) -> String {
        let parts = fullName.split(whereSeparator: \.isWhitespace)
        guard let last = parts.last else { return "anh/chị" }
        return String(last)
    }
}

extension AppointmentKind {
    /// Cách gọi loại hẹn trong câu tin nhắn.
    var messageTitle: String {
        switch self {
        case .firstDay: "đi làm ngày đầu"
        case .interview: "phỏng vấn"
        case .pickup: "đưa đón đi làm"
        case .healthCheck: "khám sức khỏe"
        case .documents: "nộp hồ sơ"
        case .callBack: "trao đổi"
        case .other: "hẹn"
        }
    }
}
