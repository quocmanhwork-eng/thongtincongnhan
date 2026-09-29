import SwiftData
import SwiftUI

/// Hồ sơ công nhân: liên hệ nhanh, lịch hẹn, thông tin chi tiết.
struct WorkerDetailView: View {
    let worker: Worker

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingEdit = false
    @State private var showingNewAppointment = false
    @State private var confirmingDelete = false

    var body: some View {
        if worker.isDeleted || worker.modelContext == nil {
            ContentUnavailableView("Công nhân đã bị xóa", systemImage: "person.crop.circle.badge.xmark")
        } else {
            content
        }
    }

    private var content: some View {
        List {
            Section {
                header
                ContactButtonsRow(worker: worker)
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }

            Section {
                Button {
                    showingNewAppointment = true
                } label: {
                    Label("Thêm lịch hẹn", systemImage: "calendar.badge.plus")
                }
                ForEach(worker.sortedAppointments) { appointment in
                    NavigationLink {
                        AppointmentDetailView(appointment: appointment)
                    } label: {
                        AppointmentRow(appointment: appointment, showsDate: true)
                    }
                    .appointmentSwipeActions(appointment)
                }
            } header: {
                Text("Lịch hẹn (\(worker.appointments.count))")
            }

            infoSection

            if !worker.notes.isEmpty {
                Section("Ghi chú") {
                    Text(worker.notes)
                        .textSelection(.enabled)
                }
            }

            Section {
                LabeledContent("Ngày thêm", value: VNDate.shortDate(worker.createdAt))
                LabeledContent("Cập nhật", value: "\(VNDate.time(worker.updatedAt)) \(VNDate.shortDate(worker.updatedAt))")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Section {
                Button("Xóa công nhân", role: .destructive) { confirmingDelete = true }
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(worker.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Sửa") { showingEdit = true }
        }
        .sheet(isPresented: $showingEdit) {
            WorkerFormView(worker: worker)
        }
        .sheet(isPresented: $showingNewAppointment) {
            AppointmentFormView(presetWorker: worker)
        }
        .confirmationDialog("Xóa \(worker.displayName)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Xóa công nhân và \(worker.appointments.count) lịch hẹn", role: .destructive, action: delete)
        } message: {
            Text("Không thể hoàn tác. Nên sao lưu dữ liệu trước nếu chưa chắc.")
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            AvatarView(initials: worker.initials, color: worker.source.color, size: 60)
            VStack(alignment: .leading, spacing: 5) {
                Text(worker.displayName)
                    .font(.title3.bold())
                HStack(spacing: 6) {
                    if let age = worker.age {
                        Text("\(age) tuổi")
                    }
                    if worker.gender != .unknown {
                        Text(worker.gender.title)
                    }
                    Label(worker.source.title, systemImage: worker.source.systemImage)
                        .foregroundStyle(worker.source.color)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                Menu {
                    ForEach(WorkerStatus.allCases) { status in
                        Button {
                            worker.status = status
                            worker.touch()
                            try? modelContext.save()
                        } label: {
                            Label(status.title, systemImage: status.systemImage)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Badge(text: worker.status.title, systemImage: worker.status.systemImage, color: worker.status.color)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("Đổi trạng thái: \(worker.status.title)")
            }
        }
        .padding(.vertical, 4)
    }

    private var infoSection: some View {
        Section("Thông tin") {
            InfoRow(title: "Số điện thoại", value: worker.formattedPhone)
            InfoRow(title: "Năm sinh", value: worker.birthYear.map(String.init) ?? "")
            InfoRow(title: "Quê quán", value: worker.hometown)
            InfoRow(title: "Chỗ ở hiện tại", value: worker.address)
            InfoRow(title: "CCCD", value: worker.idNumber)
            InfoRow(title: "Vị trí mong muốn", value: worker.desiredJob)
            InfoRow(title: "Nhà máy / công ty", value: worker.company)
            InfoRow(title: worker.source == .referral ? "Người giới thiệu" : "\(worker.source.title)", value: worker.socialHandle)
        }
    }

    private func delete() {
        dismiss()
        let target = worker
        let context = modelContext
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            context.delete(target)
            DataSync.saveAndReschedule(context)
        }
    }
}

/// Dòng thông tin, tự ẩn khi trống.
struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            LabeledContent(title) {
                Text(value)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
