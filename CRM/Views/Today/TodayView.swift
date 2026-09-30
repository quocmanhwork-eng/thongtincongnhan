import SwiftData
import SwiftUI

/// Màn hình chính: việc cần làm hôm nay và ngày mai.
struct TodayView: View {
    @EnvironmentObject private var notifications: NotificationService
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @Query(sort: \Worker.createdAt, order: .reverse) private var workers: [Worker]

    @State private var now = Date()
    @State private var showingNewWorker = false
    @State private var showingNewAppointment = false

    private var calendar: Calendar { VNDate.calendar }

    private func dayAppointments(offset: Int) -> [Appointment] {
        appointments.filter {
            $0.status != .cancelled && VNDate.dayDifference(from: now, to: $0.date, calendar: calendar) == offset
        }
    }

    /// Đã qua giờ hẹn nhưng chưa đánh dấu đến / không đến (trước hôm nay).
    private var overdue: [Appointment] {
        let startOfToday = calendar.startOfDay(for: now)
        return appointments.filter { $0.isOverdue(now: now) && $0.date < startOfToday }
    }

    /// Lịch trong 2 ngày tới chưa được công nhân xác nhận.
    private var needConfirmation: Int {
        let limit = now.addingTimeInterval(48 * 3600)
        return appointments.filter { $0.status == .pending && $0.date >= now && $0.date <= limit }.count
    }

    /// Công nhân mới liên hệ nhưng chưa có lịch hẹn.
    private var newWithoutAppointment: [Worker] {
        workers.filter { $0.status == .new && $0.nextAppointment(after: now) == nil }
    }

    var body: some View {
        let today = dayAppointments(offset: 0)
        let tomorrow = dayAppointments(offset: 1)
        let followUps = newWithoutAppointment

        NavigationStack {
            List {
                if notifications.authorizationStatus == .denied {
                    Section {
                        Button {
                            AppSettingsLink.open()
                        } label: {
                            Label("Thông báo đang tắt — app sẽ không nhắc hẹn được. Bấm để bật.", systemImage: "bell.slash.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        StatTile(title: "Hẹn hôm nay", value: today.count, systemImage: "sun.max.fill", color: .orange)
                        StatTile(title: "Hẹn ngày mai", value: tomorrow.count, systemImage: "sunrise.fill", color: .blue)
                        StatTile(title: "Chưa xác nhận (48h)", value: needConfirmation, systemImage: "phone.badge.waveform.fill", color: .purple)
                        StatTile(title: "Đang đi làm", value: workers.filter { $0.status == .working }.count, systemImage: "hammer.fill", color: .green)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if !overdue.isEmpty {
                    Section {
                        ForEach(Array(overdue.reversed())) { appointment in
                            appointmentLink(appointment, showsDate: true)
                        }
                    } header: {
                        Label("Quá giờ – cần cập nhật (\(overdue.count))", systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    } footer: {
                        Text("Vuốt sang phải: Đã đến · Vuốt sang trái: Không đến")
                    }
                }

                Section {
                    if today.isEmpty {
                        Text("Không có lịch hẹn hôm nay")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(today) { appointment in
                        appointmentLink(appointment, showsDate: false)
                    }
                } header: {
                    Text("Hôm nay · \(VNDate.longDate(now))")
                }

                Section {
                    if tomorrow.isEmpty {
                        Text("Chưa có lịch hẹn ngày mai")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(tomorrow) { appointment in
                        appointmentLink(appointment, showsDate: false)
                    }
                } header: {
                    Text("Ngày mai · \(VNDate.longDate(calendar.date(byAdding: .day, value: 1, to: now) ?? now))")
                } footer: {
                    if !tomorrow.isEmpty {
                        Text("Nên gọi xác nhận với công nhân từ tối hôm nay.")
                    }
                }

                if !followUps.isEmpty {
                    Section {
                        ForEach(followUps.prefix(10)) { worker in
                            NavigationLink {
                                WorkerDetailView(worker: worker)
                            } label: {
                                WorkerRow(worker: worker)
                            }
                        }
                    } header: {
                        Text("Mới liên hệ, chưa hẹn (\(followUps.count))")
                    }
                }
            }
            .navigationTitle("Hôm nay")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingNewWorker = true
                        } label: {
                            Label("Thêm công nhân", systemImage: "person.badge.plus")
                        }
                        Button {
                            showingNewAppointment = true
                        } label: {
                            Label("Thêm lịch hẹn", systemImage: "calendar.badge.plus")
                        }
                    } label: {
                        Label("Thêm", systemImage: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingNewWorker) {
                WorkerFormView(worker: nil)
            }
            .sheet(isPresented: $showingNewAppointment) {
                AppointmentFormView()
            }
            .refreshable { now = Date() }
            .task {
                // Cập nhật mốc "bây giờ" mỗi phút để danh sách quá giờ luôn đúng.
                while !Task.isCancelled {
                    now = Date()
                    try? await Task.sleep(for: .seconds(60))
                }
            }
        }
    }

    private func appointmentLink(_ appointment: Appointment, showsDate: Bool) -> some View {
        NavigationLink {
            AppointmentDetailView(appointment: appointment)
        } label: {
            AppointmentRow(appointment: appointment, showsDate: showsDate)
        }
        .appointmentSwipeActions(appointment)
    }
}
