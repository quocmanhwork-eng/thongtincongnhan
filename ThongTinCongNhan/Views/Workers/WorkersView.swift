import SwiftData
import SwiftUI

/// Danh sách công nhân với tìm kiếm và lọc theo trạng thái / nguồn.
struct WorkersView: View {
    enum SortOrder: String, CaseIterable, Identifiable {
        case recent, name, created
        var id: String { rawValue }
        var title: String {
            switch self {
            case .recent: "Cập nhật gần đây"
            case .name: "Tên A → Z"
            case .created: "Mới thêm"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \Worker.updatedAt, order: .reverse) private var workers: [Worker]

    @State private var search = ""
    @State private var statusFilter: WorkerStatus?
    @State private var sourceFilter: WorkerSource?
    @State private var sortOrder: SortOrder = .recent
    @State private var showingNewWorker = false
    @State private var workerToDelete: Worker?

    private var filtered: [Worker] {
        let result = workers.filter { worker in
            (statusFilter == nil || worker.status == statusFilter)
                && (sourceFilter == nil || worker.source == sourceFilter)
                && worker.matches(search: search)
        }
        switch sortOrder {
        case .recent:
            return result
        case .name:
            return result.sorted {
                MessageTemplate.givenName($0.fullName).localizedStandardCompare(MessageTemplate.givenName($1.fullName)) == .orderedAscending
            }
        case .created:
            return result.sorted { $0.createdAt > $1.createdAt }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statusChips
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section {
                    ForEach(filtered) { worker in
                        NavigationLink {
                            WorkerDetailView(worker: worker)
                        } label: {
                            WorkerRow(worker: worker)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if let url = PhoneNumber.callURL(worker.phone) {
                                Button { openURL(url) } label: { Label("Gọi", systemImage: "phone.fill") }
                                    .tint(.green)
                            }
                            if let url = PhoneNumber.zaloURL(worker.phone) {
                                Button { openURL(url) } label: { Label("Zalo", systemImage: "bubble.left.and.bubble.right.fill") }
                                    .tint(WorkerSource.zalo.color)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                workerToDelete = worker
                            } label: {
                                Label("Xóa", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                } header: {
                    if !workers.isEmpty {
                        Text("\(filtered.count) / \(workers.count) công nhân")
                    }
                }
            }
            .overlay {
                if workers.isEmpty {
                    ContentUnavailableView {
                        Label("Chưa có công nhân", systemImage: "person.3")
                    } description: {
                        Text("Thêm ứng viên từ Zalo, Facebook, TikTok để theo dõi và nhắc hẹn đi làm.")
                    } actions: {
                        Button("Thêm công nhân") { showingNewWorker = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .searchable(text: $search, prompt: "Tên, SĐT, nhà máy, quê...")
            .navigationTitle("Công nhân")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewWorker = true
                    } label: {
                        Label("Thêm công nhân", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewWorker) {
                WorkerFormView(worker: nil)
            }
            .confirmationDialog(
                "Xóa \(workerToDelete?.displayName ?? "")?",
                isPresented: Binding(get: { workerToDelete != nil }, set: { if !$0 { workerToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Xóa công nhân và các lịch hẹn", role: .destructive) {
                    if let workerToDelete {
                        modelContext.delete(workerToDelete)
                        DataSync.saveAndReschedule(modelContext)
                    }
                    workerToDelete = nil
                }
            } message: {
                Text("Không thể hoàn tác.")
            }
        }
    }

    private var statusChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Tất cả", count: workers.count, color: .accentColor, isSelected: statusFilter == nil) {
                    statusFilter = nil
                }
                ForEach(WorkerStatus.allCases) { status in
                    let count = workers.filter { $0.status == status }.count
                    if count > 0 || statusFilter == status {
                        FilterChip(title: status.title, count: count, color: status.color, isSelected: statusFilter == status) {
                            statusFilter = statusFilter == status ? nil : status
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Sắp xếp", selection: $sortOrder) {
                ForEach(SortOrder.allCases) { Text($0.title).tag($0) }
            }
            Picker("Nguồn", selection: $sourceFilter) {
                Text("Mọi nguồn").tag(WorkerSource?.none)
                ForEach(WorkerSource.allCases) { source in
                    Label(source.title, systemImage: source.systemImage).tag(WorkerSource?.some(source))
                }
            }
        } label: {
            Label("Lọc", systemImage: sourceFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }
}

/// Nút lọc dạng viên thuốc có số đếm.
struct FilterChip: View {
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                Text("\(count)")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(isSelected ? Color.white.opacity(0.25) : color.opacity(0.15), in: Capsule())
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Color.white : color)
            .background(isSelected ? color : Color(.secondarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
