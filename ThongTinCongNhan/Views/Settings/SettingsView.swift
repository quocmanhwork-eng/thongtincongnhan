import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Cài đặt: thông báo, nhắc hẹn mặc định, mẫu tin nhắn, xuất / sao lưu dữ liệu.
struct SettingsView: View {
    @EnvironmentObject private var notifications: NotificationService
    @Environment(\.modelContext) private var modelContext
    @Query private var workers: [Worker]
    @Query private var appointments: [Appointment]

    @AppStorage("defaultReminders") private var defaultRemindersRaw = ReminderOption.serialize(ReminderOption.defaultCodes)
    @AppStorage(MessageTemplate.storageKey) private var template = MessageTemplate.defaultTemplate

    @State private var shareItem: ShareItem?
    @State private var importing = false
    @State private var alertMessage: String?
    @State private var testSent = false

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                defaultRemindersSection
                templateSection
                dataSection
                aboutSection
            }
            .navigationTitle("Cài đặt")
            .task { await notifications.refreshStatus() }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url])
                    .presentationDetents([.medium, .large])
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
            .alert("Thông báo", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    // MARK: - Thông báo

    private var notificationSection: some View {
        Section {
            HStack {
                Label("Trạng thái", systemImage: "bell.badge")
                Spacer()
                Text(statusText)
                    .foregroundStyle(statusColor)
            }
            switch notifications.authorizationStatus {
            case .notDetermined:
                Button("Cho phép app gửi thông báo") {
                    Task { await notifications.requestAuthorization() }
                }
            case .denied:
                Button("Mở Cài đặt để bật thông báo") { AppSettingsLink.open() }
            default:
                EmptyView()
            }
            LabeledContent("Số lần nhắc đang chờ", value: "\(notifications.pendingCount)")
            Button {
                testSent = true
                Task { await notifications.sendTestNotification() }
            } label: {
                Label(testSent ? "Đã gửi — chờ 5 giây, có thể khóa màn hình" : "Gửi thông báo thử",
                      systemImage: testSent ? "checkmark" : "paperplane")
            }
            .disabled(notifications.authorizationStatus == .denied)
        } header: {
            Text("Thông báo nhắc hẹn")
        } footer: {
            Text("Nhắc hẹn chạy ngay trên iPhone, không cần mạng. Hãy tắt chế độ Tập trung / Không làm phiền cho app này để không bỏ lỡ.")
        }
    }

    private var statusText: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: "Đã bật"
        case .denied: "Đang tắt"
        case .notDetermined: "Chưa cho phép"
        default: "Không rõ"
        }
    }

    private var statusColor: Color {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: .green
        case .denied: .red
        default: .orange
        }
    }

    // MARK: - Nhắc hẹn mặc định

    private var defaultRemindersSection: some View {
        Section {
            ReminderPicker(codes: Binding(
                get: { Set(ReminderOption.parse(defaultRemindersRaw)) },
                set: { defaultRemindersRaw = ReminderOption.serialize(Array($0)) }
            ))
        } header: {
            Text("Nhắc mặc định cho lịch hẹn mới")
        } footer: {
            Text("Gợi ý: \"Tối hôm trước\" để gọi xác nhận, \"Trước 1 giờ\" để kiểm tra công nhân đã lên đường chưa.")
        }
    }

    // MARK: - Mẫu tin nhắn

    private var templateSection: some View {
        Section {
            TextEditor(text: $template)
                .frame(minHeight: 110)
                .font(.callout)
            DisclosureGroup("Từ khóa có thể dùng") {
                ForEach(MessageTemplate.placeholders) { placeholder in
                    HStack(alignment: .firstTextBaseline) {
                        Text(placeholder.key)
                            .font(.callout.monospaced())
                            .foregroundStyle(Color.accentColor)
                        Text(placeholder.meaning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Xem trước")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(MessageTemplate.render(template, values: sampleValues))
                    .font(.callout)
            }
            Button("Khôi phục mẫu mặc định") { template = MessageTemplate.defaultTemplate }
                .disabled(template == MessageTemplate.defaultTemplate)
        } header: {
            Text("Mẫu tin nhắn nhắc hẹn")
        }
    }

    private var sampleValues: MessageTemplate.Values {
        MessageTemplate.Values(
            fullName: "Nguyễn Văn An",
            kind: .firstDay,
            date: QuickDate.tomorrow(hour: 7, minute: 30),
            company: "Nhà máy ABC",
            location: "Cổng số 2 KCN"
        )
    }

    // MARK: - Dữ liệu

    private var dataSection: some View {
        Section {
            LabeledContent("Công nhân", value: "\(workers.count)")
            LabeledContent("Lịch hẹn", value: "\(appointments.count)")
            Button {
                export(kind: .workersCSV)
            } label: {
                Label("Xuất danh sách công nhân (Excel)", systemImage: "tablecells")
            }
            .disabled(workers.isEmpty)
            Button {
                export(kind: .appointmentsCSV)
            } label: {
                Label("Xuất lịch hẹn (Excel)", systemImage: "calendar")
            }
            .disabled(appointments.isEmpty)
            Button {
                export(kind: .backup)
            } label: {
                Label("Sao lưu toàn bộ dữ liệu", systemImage: "externaldrive.badge.icloud")
            }
            .disabled(workers.isEmpty)
            Button {
                importing = true
            } label: {
                Label("Khôi phục từ bản sao lưu", systemImage: "arrow.down.doc")
            }
        } header: {
            Text("Dữ liệu")
        } footer: {
            Text("Dữ liệu chỉ lưu trên iPhone này. Nên sao lưu mỗi tuần và gửi tệp qua Zalo, Email hoặc lưu vào iCloud Drive để không mất khi đổi / mất máy.")
        }
    }

    private enum ExportKind {
        case workersCSV, appointmentsCSV, backup
    }

    private func export(kind: ExportKind) {
        do {
            let records = try DataTransfer.allRecords(in: modelContext)
            let data: Data
            let name: String
            switch kind {
            case .workersCSV:
                data = Data(CSVExport.workers(records).utf8)
                name = BackupCodec.fileName(prefix: "DanhSachCongNhan", ext: "csv")
            case .appointmentsCSV:
                data = Data(CSVExport.appointments(records).utf8)
                name = BackupCodec.fileName(prefix: "LichHen", ext: "csv")
            case .backup:
                data = try BackupCodec.encode(BackupFile(exportedAt: Date(), workers: records))
                name = BackupCodec.fileName(prefix: "SaoLuu_CongNhan", ext: "json")
            }
            shareItem = ShareItem(url: try TemporaryFile.write(data, named: name))
        } catch {
            alertMessage = "Không xuất được dữ liệu: \(error.localizedDescription)"
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            let file = try BackupCodec.decode(Data(contentsOf: url))
            let summary = try DataTransfer.importBackup(file, into: modelContext)
            Task { await notifications.reschedule(using: modelContext) }
            alertMessage = summary.message
        } catch {
            alertMessage = "Không khôi phục được: \(error.localizedDescription)"
        }
    }

    // MARK: - Giới thiệu

    private var aboutSection: some View {
        Section("Giới thiệu") {
            LabeledContent("Ứng dụng", value: "Quản lý công nhân")
            LabeledContent("Phiên bản", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
        }
    }
}
