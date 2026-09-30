import Foundation
import SwiftData

/// Xuất / nhập dữ liệu giữa SwiftData và tệp sao lưu.
@MainActor
enum DataTransfer {
    struct ImportSummary {
        var newWorkers = 0
        var newAppointments = 0
        var skipped = 0

        var message: String {
            var text = "Đã thêm \(newWorkers) công nhân và \(newAppointments) lịch hẹn."
            if skipped > 0 { text += " Bỏ qua \(skipped) mục đã có sẵn." }
            return text
        }
    }

    static func allRecords(in context: ModelContext) throws -> [WorkerRecord] {
        let workers = try context.fetch(FetchDescriptor<Worker>(sortBy: [SortDescriptor(\.createdAt)]))
        return workers.map(\.record)
    }

    /// Gộp bản sao lưu vào dữ liệu hiện tại; mục nào đã có (trùng mã) thì giữ nguyên.
    static func importBackup(_ file: BackupFile, into context: ModelContext) throws -> ImportSummary {
        let existingWorkers = try context.fetch(FetchDescriptor<Worker>())
        var workersByID = Dictionary(existingWorkers.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let existingAppointments = try context.fetch(FetchDescriptor<Appointment>())
        var appointmentIDs = Set(existingAppointments.map(\.id))

        var summary = ImportSummary()
        for record in file.workers {
            let worker: Worker
            if let existing = workersByID[record.id] {
                worker = existing
                summary.skipped += 1
            } else {
                worker = Worker(record: record)
                context.insert(worker)
                workersByID[record.id] = worker
                summary.newWorkers += 1
            }
            for appointmentRecord in record.appointments {
                guard !appointmentIDs.contains(appointmentRecord.id) else {
                    summary.skipped += 1
                    continue
                }
                let appointment = Appointment(record: appointmentRecord)
                context.insert(appointment)
                appointment.worker = worker
                appointmentIDs.insert(appointmentRecord.id)
                summary.newAppointments += 1
            }
        }
        try context.save()
        return summary
    }
}
