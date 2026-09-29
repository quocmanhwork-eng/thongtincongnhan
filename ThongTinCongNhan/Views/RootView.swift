import SwiftData
import SwiftUI

struct RootView: View {
    enum AppTab: Hashable {
        case today, appointments, workers, settings
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var notifications: NotificationService

    @State private var selectedTab: AppTab = .today
    @State private var openedAppointment: Appointment?

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Hôm nay", systemImage: "sun.max.fill") }
                .tag(AppTab.today)
            AppointmentsView()
                .tabItem { Label("Lịch hẹn", systemImage: "calendar") }
                .tag(AppTab.appointments)
            WorkersView()
                .tabItem { Label("Công nhân", systemImage: "person.3.fill") }
                .tag(AppTab.workers)
            SettingsView()
                .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .sheet(item: $openedAppointment) { appointment in
            NavigationStack {
                AppointmentDetailView(appointment: appointment)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Đóng") { openedAppointment = nil }
                        }
                    }
            }
        }
        .task {
            await notifications.refreshStatus()
            if notifications.authorizationStatus == .notDetermined {
                await notifications.requestAuthorization()
            }
            await notifications.reschedule(using: modelContext)
            openAppointment(id: notifications.openedAppointmentID)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await notifications.reschedule(using: modelContext) }
            }
        }
        .onChange(of: notifications.openedAppointmentID) { _, id in
            openAppointment(id: id)
        }
    }

    /// Mở lịch hẹn khi người dùng bấm vào thông báo nhắc.
    private func openAppointment(id: UUID?) {
        guard let id else { return }
        notifications.openedAppointmentID = nil
        var descriptor = FetchDescriptor<Appointment>(predicate: #Predicate<Appointment> { $0.id == id })
        descriptor.fetchLimit = 1
        if let appointment = try? modelContext.fetch(descriptor).first {
            openedAppointment = appointment
        }
    }
}
