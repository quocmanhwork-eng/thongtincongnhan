import SwiftData
import SwiftUI

/// Danh sách lịch hẹn, nhóm theo ngày.
struct AppointmentsView: View {
    enum Scope: String, CaseIterable, Identifiable {
        case upcoming, past, all
        var id: String { rawValue }
        var title: String {
            switch self {
            case .upcoming: "Sắp tới"
            case .past: "Đã qua"
            case .all: "Tất cả"
            }
        }
    }

    struct DayGroup: Identifiable {
        let day: Date
        let items: [Appointment]
        var id: Date { day }
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.date) private var appointments: [Appointment]

    @State private var scope: Scope = .upcoming
    @State private var search = ""
    @State private var statusFilter: AppointmentStatus?
    @State private var showingNewAppointment = false

    private var groups: [DayGroup] {
        let calendar = VNDate.calendar
        let startOfToday = calendar.startOfDay(for: Date())
        var items = appointments.filter { appointment in
            (statusFilter == nil || appointment.status == statusFilter) && appointment.matches(search: search)
        }
        switch scope {
        case .upcoming:
            items = items.filter { $0.date >= startOfToday }
        case .past:
            items = items.filter { $0.date < startOfToday }.reversed()
        case .all:
            items = items.reversed()
        }
        var groups: [DayGroup] = []
        var currentDay: Date?
        var bucket: [Appointment] = []
        for item in items {
            let day = calendar.startOfDay(for: item.date)
            if day != currentDay, let currentDay {
                groups.append(DayGroup(day: currentDay, items: bucket))
                bucket = []
            }
            currentDay = day
            bucket.append(item)
        }
        if let currentDay, !bucket.isEmpty {
            groups.append(DayGroup(day: currentDay, items: bucket))
        }
        return groups
    }

    private var emptyTitle: String {
        scope == .upcoming ? "Không có lịch hẹn sắp tới" : "Không có lịch hẹn"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Phạm vi", selection: $scope) {
                        ForEach(Scope.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { appointment in
                            NavigationLink {
                                AppointmentDetailView(appointment: appointment)
                            } label: {
                                AppointmentRow(appointment: appointment)
                            }
                            .appointmentSwipeActions(appointment)
                        }
                    } header: {
                        HStack {
                            Text(VNDate.sectionTitle(group.day))
                            Spacer()
                            Text("\(group.items.count) hẹn")
                        }
                    }
                }
            }
            .overlay {
                if appointments.isEmpty {
                    ContentUnavailableView {
                        Label("Chưa có lịch hẹn", systemImage: "calendar")
                    } description: {
                        Text("Tạo lịch hẹn đi làm, phỏng vấn... để được nhắc đúng giờ.")
                    } actions: {
                        Button("Thêm lịch hẹn") { showingNewAppointment = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else if groups.isEmpty {
                    if search.isEmpty {
                        ContentUnavailableView(emptyTitle, systemImage: "calendar.badge.checkmark")
                    } else {
                        ContentUnavailableView.search(text: search)
                    }
                }
            }
            .searchable(text: $search, prompt: "Tên, SĐT, nhà máy...")
            .navigationTitle("Lịch hẹn")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Trạng thái", selection: $statusFilter) {
                            Text("Mọi trạng thái").tag(AppointmentStatus?.none)
                            ForEach(AppointmentStatus.allCases) { status in
                                Label(status.title, systemImage: status.systemImage).tag(AppointmentStatus?.some(status))
                            }
                        }
                    } label: {
                        Label("Lọc", systemImage: statusFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewAppointment = true
                    } label: {
                        Label("Thêm lịch hẹn", systemImage: "calendar.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewAppointment) {
                AppointmentFormView()
            }
        }
    }
}
