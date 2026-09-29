import SwiftData
import SwiftUI

/// Thêm mới hoặc sửa lịch hẹn.
struct AppointmentFormView: View {
    /// `nil` = thêm mới.
    var appointment: Appointment?
    /// Công nhân được chọn sẵn (khi thêm từ trang công nhân).
    var presetWorker: Worker?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allWorkers: [Worker]
    @AppStorage("defaultReminders") private var defaultRemindersRaw = ReminderOption.serialize(ReminderOption.defaultCodes)

    @State private var draft = AppointmentDraft()
    @State private var selectedWorker: Worker?
    @State private var loaded = false

    private var isNew: Bool { appointment == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Công nhân") {
                    NavigationLink {
                        WorkerPickerView(selection: $selectedWorker)
                    } label: {
                        if let selectedWorker {
                            WorkerRow(worker: selectedWorker)
                        } else {
                            Label("Chọn công nhân", systemImage: "person.crop.circle.badge.plus")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }

                AppointmentFields(
                    draft: $draft,
                    companySuggestions: CompanySuggestions.from(workers: allWorkers),
                    showsStatus: !isNew
                )
            }
            .navigationTitle(isNew ? "Thêm lịch hẹn" : "Sửa lịch hẹn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu", action: save)
                        .fontWeight(.semibold)
                        .disabled(selectedWorker == nil)
                }
            }
            .onAppear(perform: load)
            .onChange(of: selectedWorker) { _, worker in
                if let worker, draft.company.isEmpty {
                    draft.company = worker.company
                }
            }
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let appointment {
            draft = AppointmentDraft(appointment: appointment)
            selectedWorker = appointment.worker
        } else {
            draft = AppointmentDraft(defaultReminders: ReminderOption.parse(defaultRemindersRaw))
            selectedWorker = presetWorker
            if let presetWorker { draft.company = presetWorker.company }
        }
    }

    private func save() {
        guard let selectedWorker else { return }
        let target: Appointment
        if let appointment {
            target = appointment
        } else {
            target = Appointment(date: draft.date, kind: draft.kind)
            modelContext.insert(target)
        }
        draft.apply(to: target)
        if target.worker?.id != selectedWorker.id {
            target.worker = selectedWorker
        }
        if target.status.isActive, selectedWorker.status == .new || selectedWorker.status == .noShow {
            selectedWorker.status = .scheduled
        }
        if selectedWorker.company.isEmpty { selectedWorker.company = target.company }
        selectedWorker.touch()

        DataSync.saveAndReschedule(modelContext)
        dismiss()
    }
}

/// Chọn công nhân cho lịch hẹn (có tìm kiếm và thêm mới).
struct WorkerPickerView: View {
    @Binding var selection: Worker?

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Worker.updatedAt, order: .reverse) private var workers: [Worker]
    @State private var search = ""
    @State private var showingNewWorker = false

    private var filtered: [Worker] {
        workers.filter { $0.matches(search: search) }
    }

    var body: some View {
        List {
            Section {
                Button {
                    showingNewWorker = true
                } label: {
                    Label("Thêm công nhân mới", systemImage: "person.badge.plus")
                }
            }
            Section {
                ForEach(filtered) { worker in
                    Button {
                        selection = worker
                        dismiss()
                    } label: {
                        HStack {
                            WorkerRow(worker: worker)
                            if selection?.id == worker.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .overlay {
            if filtered.isEmpty && !search.isEmpty {
                ContentUnavailableView.search(text: search)
            }
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Tìm tên hoặc SĐT")
        .navigationTitle("Chọn công nhân")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewWorker) {
            WorkerFormView(worker: nil, allowsAppointment: false) { created in
                selection = created
                dismiss()
            }
        }
    }
}
