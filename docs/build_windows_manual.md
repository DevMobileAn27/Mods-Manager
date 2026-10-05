# Build Windows thủ công

Tài liệu này dùng cho máy Windows và script `scripts\build_windows_release.ps1`.

## Yêu cầu

- Flutter có hỗ trợ Windows desktop.
- Visual Studio với workload **Desktop development with C++**, CMake và Windows SDK.
- Python 3.12 trở lên.
- Inno Setup 6 hoặc 7.
- Khóa ký riêng `dsa_priv.pem`.

Không đưa khóa riêng vào Git hoặc thư mục phát hành công khai.

## Chuẩn bị

Mở PowerShell trong thư mục repository:

```powershell
cd "C:\Users\ASUS_ROG\Documents\Github\visual-mods-manager"
```

Kiểm tra version trong `pubspec.yaml`:

```yaml
version: 1.0.1+2
```

Tag GitHub tương ứng phải là `v1.0.1+2`.

## Build một lượt

Nếu Flutter, Dart, Inno Setup và OpenSSL đã có trong `PATH`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_windows_release.ps1 `
  -PrivateKeyPath "C:\Users\ASUS_ROG\Documents\dsa_priv.pem"
```

Script sẽ tự động:

1. Tải dependencies.
2. Chạy `flutter analyze` và `flutter test`.
3. Build Windows release.
4. Tạo installer Inno Setup.
5. Ký installer bằng DSA private key.
6. Tạo `appcast.xml` cho GitHub Release.
7. Mở thư mục `dist` sau khi hoàn tất.

## Nếu công cụ nằm trong thư mục `.tools`

```powershell
$env:PATH = `
  "C:\Users\ASUS_ROG\Documents\visual-mods-manager-main\.tools\flutter\bin;" + `
  "C:\Users\ASUS_ROG\Documents\visual-mods-manager-main\.tools\flutter\bin\cache\dart-sdk\bin;" + `
  "C:\Users\ASUS_ROG\Documents\visual-mods-manager-main\.tools\innosetup;" + `
  "C:\Users\ASUS_ROG\Documents\visual-mods-manager-main\.tools\openssl\bin;" + $env:PATH

powershell -ExecutionPolicy Bypass -File .\scripts\build_windows_release.ps1 `
  -PrivateKeyPath "C:\Users\ASUS_ROG\Documents\dsa_priv.pem"
```

## File đầu ra

Sau khi thành công, thư mục `dist` có:

```text
Visual-Mods-Manager-Setup.exe
appcast.xml
```

Chỉ upload hai file này vào GitHub Release. GitHub tự tạo các mục `Source code (zip)` và `Source code (tar.gz)` cho tag; không cần upload thủ công.

## Tạo Release

1. Tăng version trong `pubspec.yaml` trước mỗi bản phát hành.
2. Dùng tag đúng dạng `vMAJOR.MINOR.PATCH+BUILD`.
3. Upload installer và `appcast.xml` vào cùng Release.
4. Đánh dấu Release là **Latest**.

Không thay private key giữa các bản phát hành, vì các bản app cũ dùng public key hiện tại để xác minh update.

## Lỗi thường gặp

- **Building with plugins requires symlink support**: bật Windows Developer Mode hoặc chạy terminal có quyền tạo symlink.
- **Unable to find suitable Visual Studio toolchain**: cài workload Desktop development with C++ và CMake tools.
- **Installer signing failed**: kiểm tra đường dẫn private key và bảo đảm key khớp với `dsa_pub.pem`.
- **App không thấy update**: kiểm tra tag, version, URL trong `appcast.xml` và Release đã được đánh dấu Latest.
