import Foundation

/// Xử lý số điện thoại Việt Nam: chuẩn hóa, định dạng, tách từ đoạn chat.
enum PhoneNumber {
    /// Chuẩn hóa về dạng chỉ gồm chữ số, bắt đầu bằng 0.
    /// "+84 912.345.678" -> "0912345678", "84912345678" -> "0912345678".
    static func normalize(_ raw: String) -> String {
        var digits = raw.filter(\.isASCIIDigit)
        if raw.trimmingCharacters(in: .whitespaces).hasPrefix("+84") || (digits.hasPrefix("84") && digits.count == 11) {
            digits = "0" + digits.dropFirst(2)
        }
        return digits
    }

    /// Số di động / cố định Việt Nam hợp lệ: 10 chữ số (di động) hoặc 11 chữ số (cố định), bắt đầu bằng 0.
    static func isValid(_ raw: String) -> Bool {
        let digits = normalize(raw)
        return digits.hasPrefix("0") && (digits.count == 10 || digits.count == 11)
    }

    /// Hiển thị dễ đọc: "0912 345 678".
    static func format(_ raw: String) -> String {
        let digits = normalize(raw)
        guard digits.count == 10 else { return raw.trimmingCharacters(in: .whitespaces) }
        let chars = Array(digits)
        return String(chars[0..<4]) + " " + String(chars[4..<7]) + " " + String(chars[7..<10])
    }

    /// Tìm số điện thoại đầu tiên trong một đoạn văn bản (vd: tin nhắn Zalo được sao chép).
    static func extract(from text: String) -> String? {
        let pattern = #"(?<![\d+])(?:\+?84|0)[\s.\-]?\d(?:[\s.\-]?\d){8}(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        for match in regex.matches(in: text, range: range) {
            guard let swiftRange = Range(match.range, in: text) else { continue }
            let candidate = normalize(String(text[swiftRange]))
            if candidate.hasPrefix("0") && candidate.count == 10 {
                return candidate
            }
        }
        return nil
    }

    static func callURL(_ raw: String) -> URL? {
        let digits = normalize(raw)
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel:\(digits)")
    }

    static func smsURL(_ raw: String) -> URL? {
        let digits = normalize(raw)
        guard !digits.isEmpty else { return nil }
        return URL(string: "sms:\(digits)")
    }

    /// Mở khung chat Zalo theo số điện thoại.
    static func zaloURL(_ raw: String) -> URL? {
        let digits = normalize(raw)
        guard !digits.isEmpty else { return nil }
        return URL(string: "https://zalo.me/\(digits)")
    }
}

/// Đường dẫn mở mạng xã hội / bản đồ.
enum SocialLinks {
    static func facebookURL(_ handle: String) -> URL? {
        let trimmed = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = webURL(trimmed) { return url }
        let username = trimmed.replacingOccurrences(of: " ", with: "")
        return URL(string: "https://www.facebook.com/\(username)")
    }

    static func tiktokURL(_ handle: String) -> URL? {
        let trimmed = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = webURL(trimmed) { return url }
        let username = trimmed.hasPrefix("@") ? String(trimmed.dropFirst()) : trimmed
        return URL(string: "https://www.tiktok.com/@\(username.replacingOccurrences(of: " ", with: ""))")
    }

    static func mapsURL(_ address: String) -> URL? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        return URL(string: "https://maps.apple.com/?q=\(query)")
    }

    private static func webURL(_ text: String) -> URL? {
        let lower = text.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            return URL(string: text)
        }
        if lower.hasPrefix("www.") || lower.hasPrefix("facebook.com") || lower.hasPrefix("fb.com")
            || lower.hasPrefix("m.facebook.com") || lower.hasPrefix("tiktok.com") || lower.hasPrefix("vt.tiktok.com") {
            return URL(string: "https://\(text)")
        }
        return nil
    }
}

private extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
