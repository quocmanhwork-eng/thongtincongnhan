import SwiftData
import SwiftUI
import UIKit

/// Chi tiết một lịch hẹn: liên hệ, cập nhật kết quả, soạn tin nhắn nhắc.
struct AppointmentDetailView: View {
    let appointment: Appointment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(MessageTemplate.storageKey) private var template = MessageTemplate.defaultTemplate

    @State private var showingEdit = false
    @State private var confirmingDelete = false
    @State private var copiedMessage = false

    var body: some View {
        if appointment.isDeleted || appointment.modelContext == nil {
            ContentUnavailableView("Lịch hẹn đã bị xóa", systemImage: "calendar.badge.minus")
        } else {
            content
        }
    }

    private var content: some View {
        List {
            headerSection

            if let worker = appointment.worker {
                Section("Công nhân") {
                    NavigationLink {
                        WorkerDetailView(worker: worker)
                    } label: {
                        WorkerRow(worker: worker)
                    }
                    ContactButtonsRow(worker: worker)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }

            Section {
                statusButtons
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            } header: {
                Text("Cập nhật kết quả")
            } footer: {
                Text("Đánh dấu \"Đã đến\" cho lịch đi làm ngày đầu sẽ chuyển công nhân sang \"Đang đi làm\".")
            }

            detailsSection
            remindersSection
            messageSection

            Section {
                Button("Xóa lịch hẹn", role: .destructive) { confirmingDelete = true }
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(appointment.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Sửa") { showingEdit = true }
        }
        .sheet(isPresented: $showingEdit) {
            AppointmentFormView(appointment: appointment)
        }
        .confirmationDialog("Xóa lịch hẹn này?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Xóa", role: .destructive, action: delete)
        } message: {
            Text("Các nhắc hẹn của lịch này cũng sẽ bị hủy.")
        }
    }

    private var headerSection: some View {
        Section {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: appointment.kind.systemImage)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(appointment.kind.color.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(VNDate.time(appointment.date))
                        .font(.largeTitle.bold().monospacedDigit())
                    Text(VNDate.sectionTitle(appointment.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Badge(text: appointment.status.title, systemImage: appointment.status.systemImage, color: appointment.status.color)
                        if appointment.status.isActive {
                            Text(VNDate.countdown(to: appointment.date))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(appointment.isOverdue() ? Color.red : Color.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var statusButtons: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach([AppointmentStatus.confirmed, .arrived, .noShow, .cancelled]) { status in
                let selected = appointment.status == status
                Button {
                    let newStatus: AppointmentStatus = selected ? .pending : status
                    withAnimation { AppointmentActions.setStatus(newStatus, for: appointment, context: modelContext) }
                } label: {
                    Label(status.title, systemImage: status.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(selected ? Color.white : status.color)
                        .background(selected ? status.color : status.color.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        if !appointment.company.isEmpty || !appointment.location.isEmpty || !appointment.notes.isEmpty {
            Section("Chi tiết") {
                if !appointment.company.isEmpty {
                    LabeledContent("Nhà máy / công ty", value: appointment.company)
                }
                if !appointment.location.isEmpty {
                    HStack {
                        LabeledContent("Địa điểm", value: appointment.location)
                        if let url = SocialLinks.mapsURL(appointment.location) {
                            Button {
                                openURL(url)
                            } label: {
                                Image(systemName: "map.fill")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Mở bản đồ")
                        }
                    }
                }
                if !appointment.notes.isEmpty {
                    Text(appointment.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var remindersSection: some View {
        Section("Nhắc hẹn") {
            let codes = ReminderOption.sorted(appointment.reminderCodes)
            if codes.isEmpty {
                Text("Không đặt nhắc hẹn")
                    .foregroundStyle(.secondary)
            }
            ForEach(codes, id: \.self) { code in
                let fire = ReminderOption.fireDate(for: appointment.date, code: code)
                let isPast = (fire ?? .distantPast) <= Date()
                HStack {
                    Image(systemName: isPast ? "bell.slash" : "bell.fill")
                        .foregroundStyle(isPast ? Color.secondary : Color.orange)
                    Text(ReminderOption(code: code).title)
                    Spacer()
                    if let fire {
                        Text(VNDate.timeAndDay(fire))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .strikethrough(isPast)
                    }
                }
            }
            if !appointment.status.isActive && !codes.isEmpty {
                Text("Lịch hẹn đã \(appointment.status.title.lowercased()) nên sẽ không nhắc nữa.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var messageSection: some View {
        let message = MessageTemplate.render(template, values: appointment.messageValues)
        return Section {
            Text(message)
                .font(.callout)
                .textSelection(.enabled)
            ShareLink(item: message) {
                Label("Gửi tin nhắn (Zalo, Messenger...)", systemImage: "square.and.arrow.up")
            }
            if let phone = appointment.worker?.phone, let zalo = PhoneNumber.zaloURL(phone) {
                Button {
                    UIPasteboard.general.string = message
                    copiedMessage = true
                    openURL(zalo)
                } label: {
                    Label(copiedMessage ? "Đã chép — dán vào khung chat Zalo" : "Chép tin nhắn & mở Zalo",
                          systemImage: copiedMessage ? "checkmark" : "doc.on.clipboard")
                }
            }
        } header: {
            Text("Tin nhắn nhắc công nhân")
        } footer: {
            Text("Sửa mẫu tin nhắn trong tab Cài đặt.")
        }
    }

    private func delete() {
        dismiss()
        let target = appointment
        let context = modelContext
        Task { @MainActor in
            // Chờ màn hình đóng hẳn rồi mới xóa để tránh hiển thị dữ liệu đã xóa.
            try? await Task.sleep(for: .milliseconds(400))
            AppointmentActions.delete(target, context: context)
        }
    }
}
