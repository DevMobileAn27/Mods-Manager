# Phát hành Visual Mods Manager cho Windows

Ứng dụng dùng WinSparkle để kiểm tra bản mới từ GitHub Releases. Bộ cài Windows được đóng gói bằng Inno Setup; appcast và bộ cài được tạo từ cùng một tag. Việc build, ký và phát hành chạy trên GitHub Actions `windows-latest`, nên máy phát triển macOS không cần build Windows trực tiếp.

## Thiết lập một lần

1. Giữ an toàn khóa riêng ở `.local-keys/windows-update/dsa_priv.pem`. File này đã được `.gitignore` bỏ qua. Sao lưu khóa ngoài repo. Nếu mất khóa, các bản đã cài không thể xác thực bản cập nhật sau này.
2. Tạo repository secret tên `WINDOWS_DSA_PRIVATE_KEY_BASE64` trong **GitHub → Settings → Secrets and variables → Actions**. Giá trị là nội dung khóa riêng mã hóa base64 trên **một dòng**. Trên macOS, có thể lấy bằng `base64 -i .local-keys/windows-update/dsa_priv.pem | tr -d '\n'`. Dán kết quả vào secret, không đưa vào commit hoặc issue.
3. Repository [DevMobileAn27/visual-mods-manager](https://github.com/DevMobileAn27/visual-mods-manager) phải ở chế độ **Public** để ứng dụng Windows tải feed cập nhật mà không cần đăng nhập GitHub. Repository đã trả HTTP 200 khi kiểm tra vào ngày 05/10/2026. Feed sẽ nằm tại `https://github.com/DevMobileAn27/visual-mods-manager/releases/latest/download/appcast.xml` sau Release đầu tiên.

Khóa công khai ở `dsa_pub.pem` được nhúng vào file EXE để xác minh bộ cài tải xuống. Không thay khóa riêng hoặc tên repository Releases giữa các bản phát hành nếu chưa có kế hoạch chuyển cho các bản đang dùng.

## Tạo bản phát hành trên Windows

1. Clone hoặc tải source mới về Windows. Với bản này, version trong `pubspec.yaml` là `1.0.1+2`.
2. Đặt khóa riêng tại `.local-keys\windows-update\dsa_priv.pem` trên máy Windows. Không commit khóa này.
3. Cài Flutter Windows desktop, Python, Inno Setup 6 và thêm Flutter/Dart vào `PATH`.
4. Chạy PowerShell từ thư mục repo:

   ```powershell
   .\scripts\build_windows_release.ps1
   ```

   Script tự chạy test, build Windows, đóng gói `XXMI-Manager-Setup.exe`, ký installer và tạo `dist\appcast.xml` cho tag `v1.0.1+2`.

   Nếu khóa nằm ở nơi khác:

   ```powershell
   .\scripts\build_windows_release.ps1 -PrivateKeyPath C:\keys\dsa_priv.pem
   ```

5. Upload `dist\XXMI-Manager-Setup.exe` và `dist\appcast.xml` vào GitHub Release có tag `v1.0.1+2`.

GitHub Actions vẫn có thể build tự động bằng `.github/workflows/windows-release.yml`; workflow đọc version từ `pubspec.yaml`, ký bằng secret và tạo cùng cấu trúc installer/appcast.

Người dùng cài bằng `XXMI-Manager-Setup.exe` từ Release. Một file EXE build thô không đăng ký trình gỡ cài và không bảo đảm cùng đường dẫn cài đặt, nên không dùng file đó làm bản phát hành. App kiểm tra khi mở và mỗi 24 giờ; khi có bản mới, WinSparkle hiển thị cửa sổ xác nhận tải và chạy bộ cài.
