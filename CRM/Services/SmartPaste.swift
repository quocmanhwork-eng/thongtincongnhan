import Foundation

/// Đọc nhanh thông tin ứng viên từ tin nhắn được sao chép (Zalo, Facebook, TikTok).
///
/// Ví dụ: "Em tên Nguyễn Văn Hùng, sn 1998, quê Thanh Hóa, sđt 0912 345 678"
/// -> tên "Nguyễn Văn Hùng", năm sinh 1998, quê "Thanh Hóa", SĐT "0912345678".
enum SmartPaste {
    struct Result: Equatable {
        var fullName: String?
        var phone: String?
        var birthYear: Int?
        var hometown: String?

        var isEmpty: Bool {
            fullName == nil && phone == nil && birthYear == nil && hometown == nil
        }
    }

    static func parse(_ rawText: String, now: Date = Date(), calendar: Calendar = VNDate.calendar) -> Result {
        // Chuẩn hóa dấu tiếng Việt (tổ hợp -> dựng sẵn) để regex nhận đúng chữ hoa / thường.
        let text = rawText.precomposedStringWithCanonicalMapping
        let currentYear = calendar.component(.year, from: now)
        return Result(
            fullName: firstCapture(#"(?<!\p{L})(?i:tên là|tên|em là|mình là|tôi là|anh là|chị là|họ tên|họ và tên)\s*[:\-]?\s*(\p{Lu}\p{Ll}*(?:[ \t]+\p{Lu}\p{Ll}*){0,4})"#, in: text),
            phone: PhoneNumber.extract(from: text),
            birthYear: birthYear(in: text, currentYear: currentYear),
            hometown: firstCapture(#"(?<!\p{L})(?i:quê quán|quê ở|quê)\s*[:\-]?\s*(\p{Lu}\p{Ll}*(?:[ \t]+\p{Lu}\p{Ll}*){0,3})"#, in: text)
        )
    }

    private static func birthYear(in text: String, currentYear: Int) -> Int? {
        let yearPattern = #"(?<!\p{L})(?i:sinh năm|năm sinh|sn|ns)\s*[:\-.]?\s*(\d{4}|\d{2})(?!\d)"#
        if let raw = firstCapture(yearPattern, in: text), let value = Int(raw) {
            let year: Int
            if raw.count == 2 {
                year = value + (value <= currentYear % 100 ? 2000 : 1900)
            } else {
                year = value
            }
            if (currentYear - 80)...(currentYear - 14) ~= year { return year }
        }
        if let raw = firstCapture(#"(?<!\d)(\d{2})\s*(?i:tuổi|t\b)"#, in: text), let age = Int(raw), (15...75).contains(age) {
            return currentYear - age
        }
        return nil
    }

    private static func firstCapture(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let captured = Range(match.range(at: 1), in: text)
        else { return nil }
        let value = text[captured].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
