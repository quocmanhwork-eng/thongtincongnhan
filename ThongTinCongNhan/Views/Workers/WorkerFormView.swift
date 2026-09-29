import SwiftData
import SwiftUI

/// Thêm mới hoặc sửa thông tin công nhân.
struct WorkerFormView: View {
    /// `nil` = thêm mới.
    let worker: Worker?
    /// Cho phép tạo lịch hẹn ngay khi thêm công nhân.
    var allowsAppointment = true
    var onCreated: ((Worker) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allWorkers: [Worker]
    @AppStorage("defaultReminders") private var defaultRemindersRaw = ReminderOption.serialize(ReminderOption.defaultCodes)

    @State private var draft = WorkerDraft()
    @State private var withAppointment = false
    @State private var appointmentDraft = AppointmentDraft()
    @State private var loaded = false
    @State private var pasteMessage: String?
    @State private var showsMoreInfo = false

    private var isNew: Bool { worker == nil }

    var body: some View {
        NavigationStack {
            Form {
                if isNew {
                    pasteSection
                }

                Section("Thông tin chính") {
                    TextField("Họ và tên", text: $draft.fullName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                    TextField("Số điện thoại", text: $draft.phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    if let duplicate {
                        Label("SĐT này đã có: \(duplicate.displayName) (\(duplicate.status.title))", systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                    TextField("Năm sinh (vd 1998)", text: $draft.birthYearText)
                        .keyboardType(.numberPad)
                    Picker("Giới tính", selection: $draft.gender) {
                        ForEach(Gender.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Nguồn liên hệ") {
                    Picker("Kênh", selection: $draft.source) {
                        ForEach(WorkerSource.allCases) { source in
                            Label(source.title, systemImage: source.systemImage).tag(source)
                        }
                    }
                    TextField(draft.source.handlePlaceholder, text: $draft.socialHandle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Công việc") {
                    TextField("Vị trí mong muốn (vd: công nhân may, bốc xếp)", text: $draft.desiredJob)
                    CompanyField(title: "Nhà máy / công ty", text: $draft.company, suggestions: companySuggestions)
                    Picker("Trạng thái", selection: $draft.status) {
                        ForEach(WorkerStatus.allCases) { status in
                            Label(status.title, systemImage: status.systemImage).tag(status)
                        }
                    }
                }

                Section {
                    DisclosureGroup("Quê quán, chỗ ở, CCCD", isExpanded: $showsMoreInfo) {
                        TextField("Quê quán", text: $draft.hometown)
                        TextField("Chỗ ở hiện tại", text: $draft.address, axis: .vertical)
                        TextField("Số CCCD", text: $draft.idNumber)
                            .keyboardType(.numberPad)
                    }
                    TextField("Ghi chú", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                if isNew && allowsAppointment {
                    Section {
                        Toggle(isOn: $withAppointment.animation()) {
                            Label("Tạo lịch hẹn luôn", systemImage: "calendar.badge.plus")
                        }
                    } footer: {
                        if !withAppointment {
                            Text("Bật lên nếu công nhân đã hẹn ngày đi làm / phỏng vấn.")
                        }
                    }
                    if withAppointment {
                        AppointmentFields(draft: $appointmentDraft, companySuggestions: companySuggestions)
                    }
                }
            }
            .navigationTitle(isNew ? "Thêm công nhân" : "Sửa thông tin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu", action: save)
                        .fontWeight(.semibold)
                        .disabled(!draft.canSave)
                }
            }
            .onAppear(perform: load)
            .onChange(of: draft.company) { oldValue, newValue in
                // Công ty của lịch hẹn đi theo công ty của công nhân nếu chưa nhập riêng.
                if appointmentDraft.company.isEmpty || appointmentDraft.company == oldValue {
                    appointmentDraft.company = newValue
                }
            }
        }
    }

    private var pasteSection: some View {
        Section {
            HStack(spacing: 12) {
                PasteButton(payloadType: String.self) { strings in
                    let text = strings.joined(separator: "\n")
                    Task { @MainActor in handlePaste(text) }
                }
                .labelStyle(.titleAndIcon)
                .buttonBorderShape(.capsule)
                Text(pasteMessage ?? "Chép tin nhắn của ứng viên trên Zalo / Facebook / TikTok rồi bấm Dán.")
                    .font(.footnote)
                    .foregroundStyle(pasteMessage == nil ? Color.secondary : Color.green)
            }
        } header: {
            Text("Dán nhanh")
        }
    }

    private var duplicate: Worker? {
        let normalized = PhoneNumber.normalize(draft.phone)
        guard normalized.count >= 9 else { return nil }
        return allWorkers.first { $0.id != worker?.id && PhoneNumber.normalize($0.phone) == normalized }
    }

    private var companySuggestions: [String] {
        CompanySuggestions.from(workers: allWorkers)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let worker {
            draft = WorkerDraft(worker: worker)
        } else {
            appointmentDraft = AppointmentDraft(defaultReminders: ReminderOption.parse(defaultRemindersRaw))
        }
    }

    private func handlePaste(_ text: String) {
        let result = SmartPaste.parse(text)
        let filled = draft.fill(from: result)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !draft.notes.contains(trimmed) && trimmed.count > 15 {
            draft.notes = draft.notes.isEmpty ? trimmed : draft.notes + "\n" + trimmed
        }
        if result.hometown != nil { showsMoreInfo = true }
        pasteMessage = filled > 0 ? "Đã điền \(filled) ô từ tin nhắn. Kiểm tra lại trước khi lưu." : "Không tìm thấy SĐT / tên trong tin nhắn — đã chép vào ghi chú."
    }

    private func save() {
        let target: Worker
        if let worker {
            target = worker
        } else {
            target = Worker()
            modelContext.insert(target)
        }
        draft.apply(to: target)

        if isNew && allowsAppointment && withAppointment {
            let appointment = Appointment(date: appointmentDraft.date, kind: appointmentDraft.kind)
            modelContext.insert(appointment)
            appointmentDraft.apply(to: appointment)
            if appointment.company.isEmpty { appointment.company = target.company }
            appointment.worker = target
            if target.status == .new { target.status = .scheduled }
        }

        DataSync.saveAndReschedule(modelContext)
        if isNew { onCreated?(target) }
        dismiss()
    }
}
