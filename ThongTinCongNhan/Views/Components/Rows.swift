import SwiftData
import SwiftUI

/// Một dòng lịch hẹn trong danh sách.
struct AppointmentRow: View {
    let appointment: Appointment
    var showsDate = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 2) {
                Text(VNDate.time(appointment.date))
                    .font(.headline.monospacedDigit())
                if showsDate {
                    Text(VNDate.dayMonth(appointment.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 54)
            .padding(.vertical, 2)
            .foregroundStyle(appointment.isOverdue() ? Color.red : Color.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.workerName)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Label(appointment.kind.title, systemImage: appointment.kind.systemImage)
                    .font(.subheadline)
                    .foregroundStyle(appointment.kind.color)
                    .lineLimit(1)
                if !appointment.placeText.isEmpty {
                    Label(appointment.placeText, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 4) {
                Badge(text: appointment.status.title, systemImage: appointment.status.systemImage, color: appointment.status.color)
                if appointment.isOverdue() {
                    Badge(text: "Cần cập nhật", color: .red)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

/// Một dòng công nhân trong danh sách.
struct WorkerRow: View {
    let worker: Worker

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: worker.initials, color: worker.source.color)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(worker.displayName)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    if let age = worker.age {
                        Text("\(age) tuổi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !worker.phone.isEmpty {
                    Text(worker.formattedPhone)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if let next = worker.nextAppointment() {
                    Label("\(next.kind.title) · \(VNDate.time(next.date)) \(VNDate.relativeDayName(next.date) ?? VNDate.dayMonth(next.date))",
                          systemImage: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                } else if !worker.company.isEmpty {
                    Label(worker.company, systemImage: "building.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 4) {
                Badge(text: worker.status.title, color: worker.status.color)
                Image(systemName: worker.source.systemImage)
                    .font(.caption)
                    .foregroundStyle(worker.source.color)
                    .accessibilityLabel(worker.source.title)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Thao tác vuốt nhanh cho lịch hẹn: đánh dấu đã đến / không đến, gọi điện.
struct AppointmentSwipeActions: ViewModifier {
    let appointment: Appointment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if appointment.status.isActive {
                    Button {
                        AppointmentActions.setStatus(.arrived, for: appointment, context: modelContext)
                    } label: {
                        Label("Đã đến", systemImage: "checkmark.seal.fill")
                    }
                    .tint(.green)
                }
                if let phone = appointment.worker?.phone, let url = PhoneNumber.callURL(phone) {
                    Button {
                        openURL(url)
                    } label: {
                        Label("Gọi", systemImage: "phone.fill")
                    }
                    .tint(.blue)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if appointment.status.isActive {
                    Button {
                        AppointmentActions.setStatus(.noShow, for: appointment, context: modelContext)
                    } label: {
                        Label("Không đến", systemImage: "xmark.octagon.fill")
                    }
                    .tint(.red)
                    if appointment.status == .pending {
                        Button {
                            AppointmentActions.setStatus(.confirmed, for: appointment, context: modelContext)
                        } label: {
                            Label("Xác nhận", systemImage: "checkmark.circle")
                        }
                        .tint(.blue)
                    }
                }
            }
            .contextMenu {
                ForEach(AppointmentStatus.allCases) { status in
                    Button {
                        AppointmentActions.setStatus(status, for: appointment, context: modelContext)
                    } label: {
                        Label(status.title, systemImage: status.systemImage)
                    }
                    .disabled(status == appointment.status)
                }
            }
    }
}

extension View {
    func appointmentSwipeActions(_ appointment: Appointment) -> some View {
        modifier(AppointmentSwipeActions(appointment: appointment))
    }
}

/// Các thao tác thay đổi lịch hẹn dùng chung giữa các màn hình.
@MainActor
enum AppointmentActions {
    /// Đổi trạng thái lịch hẹn, đồng thời cập nhật trạng thái công nhân cho hợp lý.
    static func setStatus(_ status: AppointmentStatus, for appointment: Appointment, context: ModelContext) {
        appointment.status = status
        if let worker = appointment.worker {
            switch status {
            case .arrived where appointment.kind == .firstDay:
                worker.status = .working
            case .noShow where worker.status == .scheduled || worker.status == .new:
                worker.status = .noShow
            case .pending, .confirmed:
                if worker.status == .new || worker.status == .noShow { worker.status = .scheduled }
            default:
                break
            }
            worker.touch()
        }
        DataSync.saveAndReschedule(context)
    }

    static func delete(_ appointment: Appointment, context: ModelContext) {
        context.delete(appointment)
        DataSync.saveAndReschedule(context)
    }
}
