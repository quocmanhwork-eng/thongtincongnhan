import SwiftUI
import UIKit

/// Hàng nút liên hệ nhanh: Gọi, Zalo, SMS, Facebook/TikTok, Sao chép SĐT.
struct ContactButtonsRow: View {
    let worker: Worker
    @Environment(\.openURL) private var openURL
    @State private var copied = false

    var body: some View {
        HStack(spacing: 10) {
            if let url = PhoneNumber.callURL(worker.phone) {
                ContactButton(title: "Gọi", systemImage: "phone.fill", color: .green) { openURL(url) }
            }
            if let url = PhoneNumber.zaloURL(worker.phone) {
                ContactButton(title: "Zalo", systemImage: "bubble.left.and.bubble.right.fill", color: WorkerSource.zalo.color) { openURL(url) }
            }
            if let url = PhoneNumber.smsURL(worker.phone) {
                ContactButton(title: "SMS", systemImage: "message.fill", color: .teal) { openURL(url) }
            }
            if let link = socialLink {
                ContactButton(title: link.title, systemImage: worker.source.systemImage, color: worker.source.color) { openURL(link.url) }
            }
            if !worker.phone.isEmpty {
                ContactButton(title: copied ? "Đã chép" : "Chép SĐT", systemImage: copied ? "checkmark" : "doc.on.doc", color: .gray) {
                    UIPasteboard.general.string = PhoneNumber.normalize(worker.phone)
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        copied = false
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var socialLink: (title: String, url: URL)? {
        switch worker.source {
        case .facebook:
            SocialLinks.facebookURL(worker.socialHandle).map { (title: "Facebook", url: $0) }
        case .tiktok:
            SocialLinks.tiktokURL(worker.socialHandle).map { (title: "TikTok", url: $0) }
        default:
            nil
        }
    }
}

struct ContactButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(height: 22)
                Text(title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
