import SwiftUI
import UIKit

/// Tệp cần chia sẻ (xuất Excel / sao lưu).
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Bảng chia sẻ của iOS: gửi qua Zalo, lưu vào Tệp, AirDrop, Email...
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

enum TemporaryFile {
    /// Ghi dữ liệu ra thư mục tạm để chia sẻ.
    static func write(_ data: Data, named name: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("export", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }
}
