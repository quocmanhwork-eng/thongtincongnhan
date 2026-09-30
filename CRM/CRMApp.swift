import SwiftData
import SwiftUI
import UIKit

@main
struct CRMApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(NotificationService.shared)
                .environment(\.locale, Locale(identifier: "vi_VN"))
        }
        .modelContainer(for: [Worker.self, Appointment.self])
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Phải gán delegate trước khi app khởi động xong để bấm vào thông báo mở đúng lịch hẹn.
        NotificationService.shared.configure()
        return true
    }
}

/// Lưu thay đổi và đặt lại thông báo nhắc hẹn.
@MainActor
enum DataSync {
    static func saveAndReschedule(_ context: ModelContext) {
        try? context.save()
        Task { await NotificationService.shared.reschedule(using: context) }
    }
}
