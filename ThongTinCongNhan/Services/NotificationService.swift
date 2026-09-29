import Foundation
import SwiftData
import UIKit
import UserNotifications

enum NotificationKeys {
    static let category = "APPOINTMENT_REMINDER"
    static let snoozeAction = "SNOOZE_15"
    /// Thông báo "nhắc lại" và thông báo thử — không bị xóa khi đặt lại lịch nhắc.
    static let snoozePrefix = "snooze-"
    static let appointmentID = "appointmentID"
}

/// Quản lý quyền và lịch thông báo nhắc hẹn trên máy (không cần Internet).
@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var pendingCount: Int = 0
    /// Lịch hẹn cần mở khi người dùng bấm vào thông báo.
    @Published var openedAppointmentID: UUID?

    private let center = UNUserNotificationCenter.current()

    func configure() {
        center.delegate = self
        let snooze = UNNotificationAction(identifier: NotificationKeys.snoozeAction, title: "Nhắc lại sau 15 phút", options: [])
        let category = UNNotificationCategory(
            identifier: NotificationKeys.category,
            actions: [snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func refreshStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        pendingCount = await center.pendingNotificationRequests().count
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshStatus()
        return granted
    }

    /// Đặt lại toàn bộ thông báo nhắc hẹn từ dữ liệu hiện có.
    /// Gọi sau mỗi lần thêm / sửa / xóa lịch hẹn và mỗi khi mở app.
    func reschedule(using context: ModelContext) async {
        let now = Date()
        let descriptor = FetchDescriptor<Appointment>(predicate: #Predicate<Appointment> { $0.date > now })
        let upcoming = (try? context.fetch(descriptor)) ?? []
        let snapshots = upcoming.map(\.snapshot)
        await reschedule(snapshots: snapshots)
    }

    func reschedule(snapshots: [AppointmentSnapshot]) async {
        let pending = await center.pendingNotificationRequests()
        let oldIDs = pending.map(\.identifier).filter { $0.hasPrefix(ReminderPlanner.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)

        let snoozeCount = pending.count - oldIDs.count
        let plan = ReminderPlanner.plan(snapshots, now: Date(), limit: ReminderPlanner.maxPending - snoozeCount)
        let calendar = VNDate.calendar
        for reminder in plan {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.subtitle = reminder.subtitle
            content.body = reminder.body
            content.sound = .default
            content.categoryIdentifier = NotificationKeys.category
            content.threadIdentifier = reminder.appointmentID.uuidString
            content.userInfo = [NotificationKeys.appointmentID: reminder.appointmentID.uuidString]

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
        await refreshStatus()
    }

    /// Gửi một thông báo thử sau vài giây để kiểm tra máy có nhận được không.
    func sendTestNotification() async {
        if authorizationStatus == .notDetermined {
            await requestAuthorization()
        }
        let content = UNMutableNotificationContent()
        content.title = "Thông báo thử"
        content.body = "Nếu bạn thấy dòng này, app sẽ nhắc hẹn đúng giờ. 👍"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "\(NotificationKeys.snoozePrefix)test-\(UUID().uuidString)", content: content, trigger: trigger)
        try? await center.add(request)
        await refreshStatus()
    }

    private func snooze(_ content: UNNotificationContent) async {
        guard let copy = content.mutableCopy() as? UNMutableNotificationContent else { return }
        copy.subtitle = "Nhắc lại · " + content.subtitle
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: "\(NotificationKeys.snoozePrefix)\(UUID().uuidString)", content: copy, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Hiện thông báo cả khi đang mở app.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let content = response.notification.request.content
        let actionIdentifier = response.actionIdentifier
        let idString = content.userInfo[NotificationKeys.appointmentID] as? String
        await MainActor.run {
            if actionIdentifier == NotificationKeys.snoozeAction {
                Task { await self.snooze(content) }
            } else if let idString, let id = UUID(uuidString: idString) {
                self.openedAppointmentID = id
            }
        }
    }
}

/// Mở Cài đặt của app (khi người dùng đã tắt thông báo).
enum AppSettingsLink {
    @MainActor
    static func open() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
