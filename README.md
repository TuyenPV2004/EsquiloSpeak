# EsquiloSpeak

**EsquiloSpeak** là ứng dụng học ngoại ngữ thông minh được thiết kế dành riêng cho người Việt mới bắt đầu hoặc muốn khôi phục lại kiến thức tiếng Anh căn bản (A0/A1).

Tên gọi **EsquiloSpeak** là sự kết hợp giữa **Esquilo** (tiếng Bồ Đào Nha có nghĩa là "chú sóc") và **Speak** ("nói"), thể hiện triết lý học ngôn ngữ: tích lũy kiến thức mỗi ngày từng chút một một cách bền bỉ, giống như chú sóc gom góp hạt dẻ cho mùa đông.

---

## 🌟 Triết lý & Tính năng nổi bật

- **Vòng lặp học tập hiệu quả (Core Learning Loop)**: Giúp người học dễ dàng nắm bắt bài học ngắn mỗi ngày, thực hành bài tập tương tác và nhận phản hồi chi tiết bằng tiếng Việt.
- **Thuật toán Lặp lại ngắt quãng (Spaced Repetition)**: Đẩy mạnh khả năng ghi nhớ từ vựng và mẫu câu dài hạn thông qua lịch ôn tập SM-2 thông minh.
- **Hỗ trợ học Ngoại tuyến (Offline-ready)**: Cho phép tải và lưu trữ bài học cục bộ, tự động đồng bộ tiến độ học tập lên máy chủ ngay khi có kết nối mạng trở lại.
- **Luyện nghe và nói tương tác (Listen & Repeat)**: Tích hợp trình phát âm thanh chuẩn và tính năng thu âm tự đánh giá giúp người học phát âm tự tin hơn.

---

## 🏗 Kiến trúc Hệ thống & Công nghệ

Ứng dụng được xây dựng theo kiến trúc hiện đại, đảm bảo tính mở rộng và hiệu năng cao:

- **Mobile App**: Xây dựng bằng **Flutter & Dart** (hỗ trợ Android và iOS). Quản lý dữ liệu offline qua Drift (SQLite) và quản lý trạng thái bằng Riverpod.
- **Backend Services**: Hệ thống Microservices bằng **Java & Spring Boot** (API Gateway, Auth Service, Content Service, Learning Service, Media Service) kết hợp cơ sở dữ liệu PostgreSQL và Flyway migration.
- **API Contract**: Chuẩn hóa giao tiếp giữa Mobile và Backend qua RESTful API phiên bản `/api/v1` (OpenAPI/Swagger).
