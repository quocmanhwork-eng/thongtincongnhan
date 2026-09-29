import XCTest
@testable import ThongTinCongNhan

private let vnCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
    calendar.locale = Locale(identifier: "vi_VN")
    calendar.firstWeekday = 2
    return calendar
}()

private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    vnCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

final class PhoneNumberTests: XCTestCase {
    func testNormalize() {
        XCTAssertEqual(PhoneNumber.normalize("0912 345 678"), "0912345678")
        XCTAssertEqual(PhoneNumber.normalize("+84 912.345.678"), "0912345678")
        XCTAssertEqual(PhoneNumber.normalize("84912345678"), "0912345678")
        XCTAssertEqual(PhoneNumber.normalize("(028) 3812 3456"), "02838123456")
    }

    func testFormatAndValidity() {
        XCTAssertEqual(PhoneNumber.format("0912345678"), "0912 345 678")
        XCTAssertTrue(PhoneNumber.isValid("+84912345678"))
        XCTAssertFalse(PhoneNumber.isValid("12345"))
    }

    func testExtractFromChat() {
        XCTAssertEqual(PhoneNumber.extract(from: "Em tên Hùng, sđt 0987.654.321 nha anh"), "0987654321")
        XCTAssertEqual(PhoneNumber.extract(from: "zalo: +84 353 111 222"), "0353111222")
        XCTAssertNil(PhoneNumber.extract(from: "Em 25 tuổi, quê Nghệ An"))
        // Không lấy một phần của dãy số dài hơn.
        XCTAssertNil(PhoneNumber.extract(from: "CCCD 001099012345"))
    }

    func testLinks() {
        XCTAssertEqual(PhoneNumber.zaloURL("0912 345 678")?.absoluteString, "https://zalo.me/0912345678")
        XCTAssertEqual(PhoneNumber.callURL("0912345678")?.absoluteString, "tel:0912345678")
        XCTAssertEqual(SocialLinks.tiktokURL("@congnhan.vn")?.absoluteString, "https://www.tiktok.com/@congnhan.vn")
        XCTAssertEqual(SocialLinks.facebookURL("facebook.com/abc")?.absoluteString, "https://facebook.com/abc")
    }
}

final class VNDateTests: XCTestCase {
    func testFormatting() {
        let d = date(2026, 9, 28, 7, 5) // Thứ 2
        XCTAssertEqual(VNDate.time(d, calendar: vnCalendar), "07:05")
        XCTAssertEqual(VNDate.weekday(d, calendar: vnCalendar), "Thứ 2")
        XCTAssertEqual(VNDate.longDate(d, calendar: vnCalendar), "Thứ 2, 28/09/2026")
        XCTAssertEqual(VNDate.weekday(date(2026, 9, 27), calendar: vnCalendar), "Chủ nhật")
    }

    func testRelativeDays() {
        let now = date(2026, 9, 28, 22, 0)
        XCTAssertEqual(VNDate.relativeDayName(date(2026, 9, 29, 6, 0), now: now, calendar: vnCalendar), "Ngày mai")
        XCTAssertEqual(VNDate.relativeDayName(date(2026, 9, 28, 1, 0), now: now, calendar: vnCalendar), "Hôm nay")
        XCTAssertNil(VNDate.relativeDayName(date(2026, 10, 5), now: now, calendar: vnCalendar))
    }

    func testCountdown() {
        let now = date(2026, 9, 28, 7, 0)
        XCTAssertEqual(VNDate.countdown(to: date(2026, 9, 28, 9, 15), now: now), "còn 2 giờ 15 phút")
        XCTAssertEqual(VNDate.countdown(to: date(2026, 9, 28, 6, 40), now: now), "đã qua 20 phút")
        XCTAssertEqual(VNDate.countdown(to: now, now: now), "ngay bây giờ")
        XCTAssertEqual(VNDate.durationText(minutes: 1440), "1 ngày")
    }
}

final class ReminderTests: XCTestCase {
    func testFireDates() {
        let appointment = date(2026, 9, 30, 7, 30)
        XCTAssertEqual(ReminderOption.fireDate(for: appointment, code: 60, calendar: vnCalendar), date(2026, 9, 30, 6, 30))
        XCTAssertEqual(ReminderOption.fireDate(for: appointment, code: 0, calendar: vnCalendar), appointment)
        XCTAssertEqual(ReminderOption.fireDate(for: appointment, code: 1440, calendar: vnCalendar), date(2026, 9, 29, 7, 30))
        // Tối hôm trước lúc 20:00
        XCTAssertEqual(ReminderOption.fireDate(for: appointment, code: -1200, calendar: vnCalendar), date(2026, 9, 29, 20, 0))
    }

    func testTitlesAndSerialization() {
        XCTAssertEqual(ReminderOption.eveningBefore.title, "Tối hôm trước (20:00)")
        XCTAssertEqual(ReminderOption(code: 60).title, "Trước 1 giờ")
        XCTAssertEqual(ReminderOption(code: 0).title, "Đúng giờ hẹn")
        XCTAssertEqual(ReminderOption.parse("-1200, 60,60,abc"), [-1200, 60])
        XCTAssertEqual(ReminderOption.serialize([0, 60, -1200]), "-1200,60,0")
    }

    private func snapshot(_ day: Int, hour: Int, codes: [Int], active: Bool = true, name: String = "Nguyễn Văn An") -> AppointmentSnapshot {
        AppointmentSnapshot(
            id: UUID(),
            date: date(2026, 9, day, hour, 0),
            kindTitle: "Đi làm ngày đầu",
            workerName: name,
            phone: "0912345678",
            company: "Nhà máy ABC",
            location: "Cổng 2",
            reminderCodes: codes,
            isActive: active
        )
    }

    func testPlanSkipsPastAndInactiveAndSorts() {
        let now = date(2026, 9, 29, 21, 0)
        let tomorrow = snapshot(30, hour: 7, codes: [-1200, 60, 0])      // 20:00 hôm nay đã qua
        let later = snapshot(30, hour: 13, codes: [120])
        let cancelled = snapshot(30, hour: 8, codes: [60], active: false)
        let plan = ReminderPlanner.plan([later, tomorrow, cancelled], now: now, calendar: vnCalendar)

        XCTAssertEqual(plan.map(\.fireDate), [date(2026, 9, 30, 6, 0), date(2026, 9, 30, 7, 0), date(2026, 9, 30, 11, 0)])
        XCTAssertFalse(plan.contains { $0.appointmentID == cancelled.id })
        XCTAssertEqual(plan[0].title, "Đi làm ngày đầu: Nguyễn Văn An")
        XCTAssertEqual(plan[0].subtitle, "Hôm nay lúc 07:00 · còn 1 giờ")
        XCTAssertTrue(plan[0].body.contains("Nhà máy ABC – Cổng 2"))
        XCTAssertTrue(plan[0].body.contains("0912 345 678"))
        XCTAssertEqual(plan[1].subtitle, "Đến giờ hẹn 07:00 rồi!")
    }

    func testPlanEveningBeforeSubtitle() {
        let now = date(2026, 9, 29, 9, 0)
        let plan = ReminderPlanner.plan([snapshot(30, hour: 7, codes: [-1200])], now: now, calendar: vnCalendar)
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan[0].subtitle, "Ngày mai lúc 07:00 (Thứ 4, 30/09)")
    }

    func testPlanRespectsLimitKeepingSoonest() {
        let now = date(2026, 9, 1, 0, 0)
        let snapshots = (2...28).map { snapshot($0, hour: 8, codes: [-1200, 60, 0]) }
        let plan = ReminderPlanner.plan(snapshots, now: now, limit: 10, calendar: vnCalendar)
        XCTAssertEqual(plan.count, 10)
        XCTAssertEqual(plan.first?.fireDate, date(2026, 9, 1, 20, 0))
        XCTAssertEqual(plan.map(\.fireDate), plan.map(\.fireDate).sorted())
        XCTAssertEqual(Set(plan.map(\.identifier)).count, 10)
    }
}

final class MessageTemplateTests: XCTestCase {
    func testRenderDefaultTemplate() {
        let values = MessageTemplate.Values(fullName: "Trần Thị Mai", kind: .firstDay, date: date(2026, 9, 30, 7, 30), company: "Nhà máy ABC", location: "Cổng 2")
        let text = MessageTemplate.render(MessageTemplate.defaultTemplate, values: values, calendar: vnCalendar)
        XCTAssertTrue(text.hasPrefix("Chào Mai, em nhắc lịch đi làm ngày đầu lúc 07:30 Thứ 4, 30/09 tại Nhà máy ABC (Cổng 2)."), text)
        XCTAssertFalse(text.contains("{"))
    }

    func testRenderFallbacks() {
        let values = MessageTemplate.Values(fullName: "", kind: .interview, date: date(2026, 9, 30, 14, 0), company: "", location: "")
        XCTAssertEqual(MessageTemplate.render("{ten} - {diadiem} - {congty}", values: values, calendar: vnCalendar), "anh/chị - địa điểm đã hẹn - công ty")
        XCTAssertEqual(MessageTemplate.render("   ", values: values, calendar: vnCalendar),
                       MessageTemplate.render(MessageTemplate.defaultTemplate, values: values, calendar: vnCalendar))
    }
}

final class SmartPasteTests: XCTestCase {
    func testParseChatMessage() {
        let now = date(2026, 9, 29)
        let result = SmartPaste.parse("Em tên Nguyễn Văn Hùng, sn 1998, quê Thanh Hóa, sđt 0912 345 678 ạ", now: now, calendar: vnCalendar)
        XCTAssertEqual(result.fullName, "Nguyễn Văn Hùng")
        XCTAssertEqual(result.birthYear, 1998)
        XCTAssertEqual(result.hometown, "Thanh Hóa")
        XCTAssertEqual(result.phone, "0912345678")
    }

    func testParseAgeAndShortYear() {
        let now = date(2026, 9, 29)
        XCTAssertEqual(SmartPaste.parse("mình 25 tuổi", now: now, calendar: vnCalendar).birthYear, 2001)
        XCTAssertEqual(SmartPaste.parse("sinh năm 02", now: now, calendar: vnCalendar).birthYear, 2002)
        XCTAssertEqual(SmartPaste.parse("ns: 95", now: now, calendar: vnCalendar).birthYear, 1995)
        XCTAssertTrue(SmartPaste.parse("ok anh", now: now, calendar: vnCalendar).isEmpty)
    }
}

final class ExportTests: XCTestCase {
    private func sampleRecord() -> WorkerRecord {
        WorkerRecord(
            id: UUID(),
            fullName: "Lê Văn \"Tí\"",
            phone: "0912345678",
            birthYear: 1999,
            gender: Gender.male.rawValue,
            hometown: "Nghệ An",
            address: "Phòng trọ 5, KCN",
            idNumber: "001099012345",
            source: WorkerSource.tiktok.rawValue,
            socialHandle: "@ti",
            desiredJob: "Công nhân may",
            company: "Nhà máy ABC",
            status: WorkerStatus.scheduled.rawValue,
            notes: "Ghi chú, có dấu phẩy\nvà xuống dòng",
            createdAt: date(2026, 9, 1),
            updatedAt: date(2026, 9, 2),
            appointments: [
                AppointmentRecord(id: UUID(), date: date(2026, 10, 1, 7, 30), kind: AppointmentKind.firstDay.rawValue,
                                  status: AppointmentStatus.pending.rawValue, company: "Nhà máy ABC", location: "Cổng 2",
                                  notes: "", reminderCodes: [-1200, 60], createdAt: date(2026, 9, 2)),
            ]
        )
    }

    func testWorkersCSV() {
        let csv = CSVExport.workers([sampleRecord()], now: date(2026, 9, 29), calendar: vnCalendar)
        XCTAssertTrue(csv.hasPrefix("\u{FEFF}STT,Họ và tên,SĐT"))
        XCTAssertTrue(csv.contains("\"Lê Văn \"\"Tí\"\"\""))
        XCTAssertTrue(csv.contains(",0912 345 678,"))
        XCTAssertTrue(csv.contains("\"=\"\"001099012345\"\"\""))
        XCTAssertTrue(csv.contains("\"Ghi chú, có dấu phẩy\nvà xuống dòng\""))
        XCTAssertTrue(csv.contains("07:30 01/10/2026 - Đi làm ngày đầu"))
        XCTAssertTrue(csv.contains(",Đã hẹn,"))
    }

    func testAppointmentsCSV() {
        let csv = CSVExport.appointments([sampleRecord()], calendar: vnCalendar)
        let lines = csv.components(separatedBy: "\r\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[1].hasPrefix("01/10/2026,07:30,Thứ 5,"))
    }

    func testBackupRoundTrip() throws {
        let file = BackupFile(exportedAt: date(2026, 9, 29, 10, 0), workers: [sampleRecord()])
        let data = try BackupCodec.encode(file)
        XCTAssertEqual(try BackupCodec.decode(data), file)
    }

    func testBackupRejectsOtherFiles() {
        XCTAssertThrowsError(try BackupCodec.decode(Data("{\"hello\":1}".utf8)))
    }

    func testBackupToleratesMissingFields() throws {
        let json = """
        {"app":"ThongTinCongNhan","version":1,"exportedAt":"2026-09-29T03:00:00Z",
         "workers":[{"id":"6F1C1B4E-1C39-4E57-9D0C-0A4C1F1B2D3E","fullName":"An",
           "appointments":[{"id":"7F1C1B4E-1C39-4E57-9D0C-0A4C1F1B2D3E","date":"2026-10-01T00:30:00Z"}]}]}
        """
        let file = try BackupCodec.decode(Data(json.utf8))
        XCTAssertEqual(file.workers.first?.fullName, "An")
        XCTAssertEqual(file.workers.first?.status, WorkerStatus.new.rawValue)
        XCTAssertEqual(file.workers.first?.appointments.first?.reminderCodes, ReminderOption.defaultCodes)
    }
}

final class DraftTests: XCTestCase {
    func testBirthYearParsing() {
        var draft = WorkerDraft()
        draft.birthYearText = "1998"
        XCTAssertEqual(draft.birthYear, 1998)
        draft.birthYearText = "abc"
        XCTAssertNil(draft.birthYear)
        draft.birthYearText = "95"
        XCTAssertEqual(draft.birthYear, 1995)
    }

    func testFillOnlyEmptyFields() {
        var draft = WorkerDraft()
        draft.fullName = "Đã nhập"
        let filled = draft.fill(from: SmartPaste.Result(fullName: "Khác", phone: "0912345678", birthYear: 2000, hometown: nil))
        XCTAssertEqual(filled, 2)
        XCTAssertEqual(draft.fullName, "Đã nhập")
        XCTAssertEqual(draft.phone, "0912345678")
    }

    func testQuickDates() {
        let wednesday = date(2026, 9, 30, 15, 0)
        XCTAssertEqual(QuickDate.tomorrow(hour: 7, minute: 30, now: wednesday, calendar: vnCalendar), date(2026, 10, 1, 7, 30))
        XCTAssertEqual(QuickDate.nextMonday(hour: 7, minute: 0, now: wednesday, calendar: vnCalendar), date(2026, 10, 5, 7, 0))
        let monday = date(2026, 9, 28, 6, 0)
        XCTAssertEqual(QuickDate.nextMonday(hour: 7, minute: 0, now: monday, calendar: vnCalendar), date(2026, 10, 5, 7, 0))
    }
}
