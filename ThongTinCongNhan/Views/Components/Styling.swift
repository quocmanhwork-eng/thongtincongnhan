import SwiftUI

extension WorkerSource {
    var color: Color {
        switch self {
        case .zalo: Color(red: 0.0, green: 0.41, blue: 1.0)
        case .facebook: Color(red: 0.09, green: 0.47, blue: 0.95)
        case .tiktok: Color(red: 0.93, green: 0.11, blue: 0.36)
        case .referral: .purple
        case .walkIn: .teal
        case .other: .gray
        }
    }
}

extension WorkerStatus {
    var color: Color {
        switch self {
        case .new: .blue
        case .scheduled: .orange
        case .working: .green
        case .noShow: .red
        case .quit: .gray
        case .rejected: .brown
        }
    }
}

extension AppointmentStatus {
    var color: Color {
        switch self {
        case .pending: .orange
        case .confirmed: .blue
        case .arrived: .green
        case .noShow: .red
        case .cancelled: .gray
        }
    }
}

extension AppointmentKind {
    var color: Color {
        switch self {
        case .firstDay: .green
        case .interview: .indigo
        case .pickup: .orange
        case .healthCheck: .red
        case .documents: .brown
        case .callBack: .blue
        case .other: .gray
        }
    }
}

/// Nhãn nhỏ bo tròn.
struct Badge: View {
    let text: String
    var systemImage: String?
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(.caption2.weight(.semibold))
        .lineLimit(1)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .foregroundStyle(color)
        .background(color.opacity(0.14), in: Capsule())
    }
}

/// Ảnh đại diện bằng chữ cái đầu.
struct AvatarView: View {
    let initials: String
    let color: Color
    var size: CGFloat = 42

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Ô thống kê nhỏ trên màn hình Hôm nay.
struct StatTile: View {
    let title: String
    let value: Int
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title2.bold())
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
