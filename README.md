# Công Nhân – App quản lý ứng viên & nhắc hẹn đi làm (iOS)

App iPhone giúp người làm **tuyển dụng lao động phổ thông** lưu thông tin công nhân tìm được trên
Zalo, Facebook, TikTok… và **tự động nhắc hẹn** để không bỏ lỡ ngày công nhân đi làm, phỏng vấn, khám sức khỏe.

- Viết bằng SwiftUI + SwiftData, chạy trên **iOS 17 trở lên**.
- **Không cần Internet, không cần tài khoản.** Dữ liệu nằm ngay trên iPhone.
- Thông báo nhắc hẹn do chính iPhone phát, **kể cả khi không mở app**.

---

## Tính năng

### 1. Tab "Hôm nay"
- Ô thống kê: số hẹn hôm nay, ngày mai, số lịch **chưa xác nhận** trong 48 giờ tới, số người đang đi làm.
- **Quá giờ – cần cập nhật**: lịch hẹn đã qua mà chưa đánh dấu công nhân có đến hay không.
- Danh sách hẹn hôm nay / ngày mai.
- **Mới liên hệ, chưa hẹn**: ứng viên mới nhắn tin nhưng chưa chốt lịch, để chăm sóc tiếp.
- Vuốt nhanh trên mỗi lịch hẹn: **→ Đã đến / Gọi**, **← Không đến / Xác nhận**.

### 2. Tab "Công nhân"
- Lưu: họ tên, SĐT, năm sinh (tự tính tuổi), giới tính, quê quán, chỗ ở, CCCD,
  **nguồn (Zalo / Facebook / TikTok / người giới thiệu / đến trực tiếp)**, tên/link mạng xã hội,
  vị trí mong muốn, nhà máy/công ty, trạng thái, ghi chú.
- Trạng thái: *Mới liên hệ → Đã hẹn → Đang đi làm*, hoặc *Bùng hẹn / Đã nghỉ / Không phù hợp*.
- **Dán nhanh từ tin nhắn**: chép tin nhắn ứng viên trên Zalo/Facebook, ví dụ
  `Em tên Nguyễn Văn Hùng, sn 1998, quê Thanh Hóa, sđt 0912 345 678` → bấm **Dán**,
  app tự điền tên, SĐT, năm sinh, quê.
- **Cảnh báo trùng SĐT** (một người nhắn qua nhiều kênh).
- Nút liên hệ nhanh: **Gọi, Zalo, SMS, mở Facebook/TikTok, chép SĐT**.
- Tìm theo tên, SĐT, nhà máy, quê; lọc theo trạng thái, nguồn; sắp xếp.
- Khi thêm công nhân có thể **tạo lịch hẹn luôn** trong cùng một màn hình.

### 3. Tab "Lịch hẹn"
- Loại hẹn: Đi làm ngày đầu, Phỏng vấn, Đón/đưa đi làm, Khám sức khỏe, Nộp hồ sơ, Gọi lại tư vấn…
- Chọn nhanh giờ: *Sáng mai 7:00, Sáng mai 7:30, Chiều mai 13:30, Thứ 2 tới 7:00…*
- Nhà máy (gợi ý từ những nhà máy đã nhập), địa điểm/điểm đón (mở Bản đồ), ghi chú.
- **Nhắc hẹn nhiều mốc**: tối hôm trước (20:00), trước 1 ngày, 3 giờ, 2 giờ, 1 giờ, 30 phút, 15 phút, đúng giờ.
  Mặc định: *tối hôm trước* (để gọi xác nhận) + *trước 1 giờ*.
- Thông báo có nút **"Nhắc lại sau 15 phút"**; bấm vào thông báo mở đúng lịch hẹn đó.
- Kết quả: Đã xác nhận / Đã đến / Không đến / Hủy. Đánh dấu **Đã đến** lịch *đi làm ngày đầu*
  → công nhân tự chuyển sang **Đang đi làm**; **Không đến** → **Bùng hẹn**.
- **Tin nhắn nhắc công nhân soạn sẵn**, gửi qua Zalo/Messenger bằng 1 chạm, ví dụ:
  > Chào Hùng, em nhắc lịch đi làm ngày đầu lúc 07:30 Thứ 4, 30/09 tại Nhà máy ABC (Cổng 2).
  > Anh/chị nhớ mang theo CCCD và đến đúng giờ giúp em nhé. Có gì thay đổi thì báo em sớm ạ!

### 4. Tab "Cài đặt"
- Kiểm tra quyền thông báo, **gửi thông báo thử**.
- Chọn mốc nhắc mặc định.
- Sửa **mẫu tin nhắn** với các từ khóa `{ten}`, `{hoten}`, `{loai}`, `{gio}`, `{ngay}`, `{congty}`, `{diachi}`, `{diadiem}`.
- **Xuất Excel (CSV)** danh sách công nhân và lịch hẹn (mở được bằng Excel, Google Sheets, Numbers; giữ đúng tiếng Việt và số 0 đầu SĐT/CCCD).
- **Sao lưu / khôi phục** toàn bộ dữ liệu (tệp `.json`) – gửi qua Zalo, Email hoặc lưu iCloud Drive.

---

## Cài app lên iPhone

App chưa đưa lên App Store nên cần tự cài. Có 2 cách:

### Cách 1 – Có máy Mac (khuyên dùng)

1. Cài **Xcode** (miễn phí) từ App Store trên Mac (Xcode 16 trở lên).
2. Tải code về: trên GitHub bấm **Code → Download ZIP**, giải nén.
3. Mở tệp `ThongTinCongNhan.xcodeproj`.
4. Bấm vào dự án **ThongTinCongNhan** (cột trái) → tab **Signing & Capabilities**:
   - **Team**: chọn *Add an Account…* và đăng nhập Apple ID của bạn, rồi chọn team đó.
   - Nếu báo lỗi Bundle Identifier, đổi `com.quocmanh.thongtincongnhan` thành tên khác, ví dụ `com.tenban.congnhan`.
5. Cắm iPhone vào Mac bằng cáp, chọn iPhone ở thanh trên cùng của Xcode, bấm nút ▶ (Run).
6. Lần đầu trên iPhone:
   - **Cài đặt → Quyền riêng tư & Bảo mật → Chế độ nhà phát triển** → Bật (máy sẽ khởi động lại).
   - **Cài đặt → Cài đặt chung → Quản lý VPN & thiết bị** → chọn Apple ID của bạn → **Tin cậy**.
7. Mở app **Công Nhân**, bấm **Cho phép** thông báo.

### Cách 2 – Không có Mac (dùng máy tính Windows + Sideloadly)

1. Trên GitHub, vào tab **Actions** → chọn lần chạy mới nhất có dấu ✅ → phần **Artifacts** tải
   **ThongTinCongNhan-ipa** (giải nén ra tệp `ThongTinCongNhan-unsigned.ipa`).
2. Cài **iTunes** (bản tải từ apple.com) và **Sideloadly** (sideloadly.io) trên máy tính.
3. Cắm iPhone, mở Sideloadly, kéo tệp `.ipa` vào, nhập Apple ID, bấm **Start**.
4. Trên iPhone làm bước 6–7 như Cách 1.

### Lưu ý khi dùng Apple ID miễn phí
- App **hết hạn sau 7 ngày**; chỉ cần cắm máy và cài lại (bấm ▶ trong Xcode hoặc Start trong Sideloadly).
  **Dữ liệu vẫn còn** nếu bạn không xóa app.
- Với tài khoản **Apple Developer (99 USD/năm)**: app dùng được 1 năm, có thể cài cho nhiều máy qua TestFlight.
- **Không xóa app** khi chưa sao lưu – xóa app là mất dữ liệu.

---

## Mẹo để không bỏ lỡ công nhân

1. Mỗi khi chốt được lịch trên Zalo/Facebook/TikTok → mở app, **Thêm công nhân → Dán** tin nhắn → bật **Tạo lịch hẹn luôn**.
2. Tối hôm trước app nhắc → gọi / nhắn Zalo (dùng **tin nhắn soạn sẵn**) → bấm **Xác nhận** nếu công nhân chắc chắn đi.
3. Trước giờ hẹn 1 tiếng app nhắc lần nữa → gọi hỏi đã lên đường chưa.
4. Sau giờ hẹn → vuốt **Đã đến** hoặc **Không đến**. Mục *Quá giờ – cần cập nhật* giúp không sót ai.
5. Vào **Cài đặt → Sao lưu** mỗi tuần, gửi tệp sao lưu vào Zalo "Cloud của tôi".
6. Trong **Cài đặt iPhone → Tập trung**, cho phép app Công Nhân báo cả khi bật *Không làm phiền*.

---

## Dành cho lập trình viên

```
ThongTinCongNhan/
├── ThongTinCongNhanApp.swift     # Điểm vào app, AppDelegate (gắn delegate thông báo)
├── Models/                       # SwiftData: Worker, Appointment; enum trạng thái; bản nháp form
├── Services/                     # Logic thuần (có test): SĐT, ngày giờ, lập lịch nhắc,
│                                 #   mẫu tin nhắn, dán nhanh, CSV, sao lưu; NotificationService
└── Views/                        # SwiftUI: Hôm nay, Công nhân, Lịch hẹn, Cài đặt, thành phần dùng chung
ThongTinCongNhanTests/            # Unit test (XCTest)
.github/workflows/ios.yml         # CI: chạy test trên simulator + build tệp .ipa chưa ký
```

- Thông báo: mỗi lần dữ liệu thay đổi hoặc mở app, `NotificationService.reschedule` tính lại toàn bộ lịch
  nhắc bằng `ReminderPlanner` và chỉ đặt **58 thông báo gần nhất** (iOS giới hạn 64 thông báo chờ/app),
  nên không bao giờ bị "rơi" nhắc hẹn dù có rất nhiều lịch.
- Chạy test: `xcodebuild test -project ThongTinCongNhan.xcodeproj -scheme ThongTinCongNhan -destination 'platform=iOS Simulator,name=iPhone 16'`
- Dự án dùng *folder đồng bộ* của Xcode 16: thêm tệp `.swift` vào thư mục là tự có trong dự án.
