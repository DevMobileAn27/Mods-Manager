# Phát hành XXMI Manager cho Windows

Ứng dụng dùng WinSparkle để kiểm tra bản mới từ GitHub Releases. Bộ cài Windows được đóng gói bằng Inno Setup; appcast và bộ cài được tạo từ cùng một tag. Việc build, ký và phát hành chạy trên GitHub Actions `windows-latest`, nên máy phát triển macOS không cần build Windows trực tiếp.

## Thiết lập một lần

1. Giữ an toàn khóa riêng ở `.local-keys/windows-update/dsa_priv.pem`. File này đã được `.gitignore` bỏ qua. Sao lưu khóa ngoài repo. Nếu mất khóa, các bản đã cài không thể xác thực bản cập nhật sau này.
2. Tạo repository secret tên `WINDOWS_DSA_PRIVATE_KEY_BASE64` trong **GitHub → Settings → Secrets and variables → Actions**. Giá trị là nội dung khóa riêng mã hóa base64 trên **một dòng**. Trên macOS, có thể lấy bằng `base64 -i .local-keys/windows-update/dsa_priv.pem | tr -d '\n'`. Dán kết quả vào secret, không đưa vào commit hoặc issue.
3. Repository [DevMobileAn27/Mods-Manager](https://github.com/DevMobileAn27/Mods-Manager) phải ở chế độ **Public** để ứng dụng Windows tải feed cập nhật mà không cần đăng nhập GitHub. Repository đã trả HTTP 200 khi kiểm tra vào ngày 05/10/2026. Feed sẽ nằm tại `https://github.com/DevMobileAn27/Mods-Manager/releases/latest/download/appcast.xml` sau Release đầu tiên.

Khóa công khai ở `dsa_pub.pem` được nhúng vào file EXE để xác minh bộ cài tải xuống. Không thay khóa riêng hoặc tên repository Releases giữa các bản phát hành nếu chưa có kế hoạch chuyển cho các bản đang dùng.

## Tạo bản phát hành

1. Tăng `version` trong `pubspec.yaml`, gồm số build sau dấu `+`, ví dụ `1.0.1+2`.
2. Commit và push mã nguồn, sau đó push tag **khớp chính xác** với version: `v1.0.1+2`.
3. Workflow `.github/workflows/windows-release.yml` chạy `flutter analyze`, `flutter test`, build Windows, tạo `XXMI-Manager-Setup.exe`, ký installer bằng khóa riêng rồi tạo `appcast.xml` và GitHub Release. Nếu thiếu secret hoặc version của tag không khớp, workflow dừng trước khi phát hành.
4. Tải bộ cài từ Release và thử trên Windows. Cài bản cũ, sau đó phát hành bản mới để xác nhận nút **Settings → Kiểm tra cập nhật** tìm và cài được bản mới. Chạy workflow thủ công qua **Actions → Windows release → Run workflow** chỉ tạo artifact để thử, không tạo Release.

Người dùng cài bằng `XXMI-Manager-Setup.exe` từ Release. Một file EXE build thô không đăng ký trình gỡ cài và không bảo đảm cùng đường dẫn cài đặt, nên không dùng file đó làm bản phát hành. App kiểm tra khi mở và mỗi 24 giờ; khi có bản mới, WinSparkle hiển thị cửa sổ xác nhận tải và chạy bộ cài.
