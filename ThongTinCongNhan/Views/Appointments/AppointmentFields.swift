import SwiftData
import SwiftUI

/// Các ô nhập của một lịch hẹn, dùng chung cho form lịch hẹn và form thêm công nhân.
struct AppointmentFields: View {
    @Binding var draft: AppointmentDraft
    let companySuggestions: [String]
    var showsStatus = false

    var body: some View {
        Section {
            Picker("Loại hẹn", selection: $draft.kind) {
                ForEach(AppointmentKind.allCases) { kind in
                    Label(kind.title, systemImage: kind.systemImage).tag(kind)
                }
            }
            DatePicker("Ngày giờ", selection: $draft.date, displayedComponents: [.date, .hourAndMinute])
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QuickDate.options()) { option in
                        Button(option.title) { draft.date = option.date }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(option.date == draft.date ? Color.accentColor : Color.gray)
                    }
                }
                .padding(.vertical, 2)
            }
            if showsStatus {
                Picker("Trạng thái", selection: $draft.status) {
                    ForEach(AppointmentStatus.allCases) { status in
                        Label(status.title, systemImage: status.systemImage).tag(status)
                    }
                }
            }
        } header: {
            Text("Lịch hẹn")
        } footer: {
            Text(VNDate.longDate(draft.date) + " lúc " + VNDate.time(draft.date) + " · " + VNDate.countdown(to: draft.date))
        }

        Section("Địa điểm") {
            CompanyField(title: "Nhà máy / công ty", text: $draft.company, suggestions: companySuggestions)
            TextField("Địa điểm hẹn / điểm đón", text: $draft.location, axis: .vertical)
            TextField("Ghi chú (mang CCCD, ảnh 3x4...)", text: $draft.notes, axis: .vertical)
                .lineLimit(1...4)
        }

        Section {
            ReminderPicker(codes: $draft.reminderCodes, appointmentDate: draft.date)
        } header: {
            Text("Nhắc hẹn")
        } footer: {
            Text("Điện thoại sẽ báo vào các mốc đã chọn, kể cả khi không mở app.")
        }
    }
}

/// Chọn các mốc nhắc hẹn.
struct ReminderPicker: View {
    @Binding var codes: Set<Int>
    var appointmentDate: Date?

    var body: some View {
        ForEach(ReminderOption.all) { option in
            Toggle(isOn: binding(for: option.code)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                    if let appointmentDate, let fire = ReminderOption.fireDate(for: appointmentDate, code: option.code) {
                        Text(fire > Date() ? "Báo lúc \(VNDate.timeAndDay(fire))" : "Đã qua mốc này")
                            .font(.caption)
                            .foregroundStyle(fire > Date() ? Color.secondary : Color.red)
                    }
                }
            }
        }
    }

    private func binding(for code: Int) -> Binding<Bool> {
        Binding(
            get: { codes.contains(code) },
            set: { isOn in
                if isOn { codes.insert(code) } else { codes.remove(code) }
            }
        )
    }
}

/// Ô nhập nhà máy / công ty với danh sách gợi ý từ dữ liệu đã có.
struct CompanyField: View {
    let title: String
    @Binding var text: String
    let suggestions: [String]

    var body: some View {
        HStack {
            TextField(title, text: $text)
            if !suggestions.isEmpty {
                Menu {
                    ForEach(suggestions, id: \.self) { name in
                        Button(name) { text = name }
                    }
                } label: {
                    Image(systemName: "list.bullet.circle")
                        .font(.title3)
                }
                .accessibilityLabel("Chọn nhà máy đã có")
            }
        }
    }
}

enum CompanySuggestions {
    /// Danh sách nhà máy / công ty đã từng nhập, dùng nhiều nhất xếp trước.
    static func from(workers: [Worker]) -> [String] {
        var counts: [String: Int] = [:]
        for worker in workers {
            let names = [worker.company] + worker.appointments.map(\.company)
            for name in names {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { counts[trimmed, default: 0] += 1 }
            }
        }
        return counts.sorted { ($1.value, $0.key) < ($0.value, $1.key) }.prefix(20).map { $0.key }
    }
}
