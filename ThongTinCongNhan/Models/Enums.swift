import Foundation

/// Kênh mà công nhân liên hệ / được tìm thấy.
enum WorkerSource: String, CaseIterable, Codable, Identifiable {
    case zalo
    case facebook
    case tiktok
    case referral
    case walkIn
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .zalo: "Zalo"
        case .facebook: "Facebook"
        case .tiktok: "TikTok"
        case .referral: "Người giới thiệu"
        case .walkIn: "Đến trực tiếp"
        case .other: "Khác"
        }
    }

    var systemImage: String {
        switch self {
        case .zalo: "bubble.left.and.bubble.right.fill"
        case .facebook: "f.circle.fill"
        case .tiktok: "music.note"
        case .referral: "person.2.fill"
        case .walkIn: "figure.walk"
        case .other: "ellipsis.circle.fill"
        }
    }

    /// Gợi ý cho ô nhập thông tin liên hệ mạng xã hội.
    var handlePlaceholder: String {
        switch self {
        case .zalo: "Tên Zalo (nếu khác SĐT)"
        case .facebook: "Link hoặc tên Facebook"
        case .tiktok: "Tên TikTok (vd: @tencongnhan)"
        case .referral: "Tên người giới thiệu"
        case .walkIn, .other: "Ghi chú nguồn"
        }
    }
}

/// Trạng thái của công nhân trong quá trình tuyển dụng.
enum WorkerStatus: String, CaseIterable, Codable, Identifiable {
    case new
    case scheduled
    case working
    case noShow
    case quit
    case rejected

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: "Mới liên hệ"
        case .scheduled: "Đã hẹn"
        case .working: "Đang đi làm"
        case .noShow: "Bùng hẹn"
        case .quit: "Đã nghỉ"
        case .rejected: "Không phù hợp"
        }
    }

    var systemImage: String {
        switch self {
        case .new: "sparkles"
        case .scheduled: "calendar.badge.clock"
        case .working: "hammer.fill"
        case .noShow: "person.fill.xmark"
        case .quit: "door.left.hand.open"
        case .rejected: "hand.thumbsdown.fill"
        }
    }
}

enum Gender: String, CaseIterable, Codable, Identifiable {
    case unknown
    case male
    case female

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unknown: "Chưa rõ"
        case .male: "Nam"
        case .female: "Nữ"
        }
    }
}

/// Loại lịch hẹn với công nhân.
enum AppointmentKind: String, CaseIterable, Codable, Identifiable {
    case firstDay
    case interview
    case pickup
    case healthCheck
    case documents
    case callBack
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstDay: "Đi làm ngày đầu"
        case .interview: "Phỏng vấn"
        case .pickup: "Đón / đưa đi làm"
        case .healthCheck: "Khám sức khỏe"
        case .documents: "Nộp hồ sơ"
        case .callBack: "Gọi lại tư vấn"
        case .other: "Khác"
        }
    }

    var systemImage: String {
        switch self {
        case .firstDay: "figure.walk.arrival"
        case .interview: "person.crop.rectangle.stack"
        case .pickup: "bus.fill"
        case .healthCheck: "cross.case.fill"
        case .documents: "doc.text.fill"
        case .callBack: "phone.arrow.up.right.fill"
        case .other: "calendar"
        }
    }
}

/// Trạng thái của một lịch hẹn.
enum AppointmentStatus: String, CaseIterable, Codable, Identifiable {
    case pending
    case confirmed
    case arrived
    case noShow
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: "Chờ"
        case .confirmed: "Đã xác nhận"
        case .arrived: "Đã đến"
        case .noShow: "Không đến"
        case .cancelled: "Đã hủy"
        }
    }

    var systemImage: String {
        switch self {
        case .pending: "clock"
        case .confirmed: "checkmark.circle"
        case .arrived: "checkmark.seal.fill"
        case .noShow: "xmark.octagon.fill"
        case .cancelled: "slash.circle"
        }
    }

    /// Lịch hẹn còn hiệu lực: vẫn cần nhắc và cần cập nhật kết quả.
    var isActive: Bool {
        self == .pending || self == .confirmed
    }
}
