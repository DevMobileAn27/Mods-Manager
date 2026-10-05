# XXMI Manager

XXMI Manager giúp quản lý mod **Zenless Zone Zero** theo nhân vật và skin trên desktop. Ứng dụng hiển thị avatar ngay cả khi không có Internet và đưa skin từ file ZIP vào đúng thư mục nhân vật.

![Màn hình thư viện Mods của XXMI Manager](docs/images/library.png)

## Thiết lập lần đầu

1. Bấm **Thư mục Mods** và chọn thư mục sẽ chứa các skin đã giải nén, chẳng hạn `ZZZ/Mods`.
2. Bấm **Thư mục Download**. Chọn **Đã có sẵn** nếu bạn đã có thư mục chứa ZIP; chọn **Tạo mới** nếu muốn ứng dụng tạo thư mục tại vị trí bạn chọn.
3. Bấm **Bắt đầu quản lý**.

Ứng dụng tạo thư mục skin mặc định và các skin có trong danh mục cho từng nhân vật ở cả Mods và Download. Mỗi skin thêm vào cũng có một thư mục cùng tên ở cả hai nơi. Trên grid, skin mặc định hiển thị tên nhân vật (ví dụ **Astra Yao**), còn skin khác hiển thị ngay bên cạnh (ví dụ **Astra Yao - Chandelier**). Tên thư mục đã có có thể viết hoa hoặc viết thường. Nếu macOS yêu cầu chọn lại thư mục sau khi mở lại ứng dụng, hãy chọn lại hai thư mục đó để cấp quyền truy cập.

## Xem và cài skin

Chuyển giữa hai tab **Mods** và **Download** ở đầu cửa sổ. Hai tab có cùng danh sách thư mục skin. Bấm avatar hoặc tên skin để mở nội dung thư mục đó.

- **Mods** hiển thị file đã giải nén trong từng thư mục skin.
- **Download** hiển thị file ZIP bạn đã đặt trong từng thư mục skin. Ứng dụng không tự tải mod.

Để cài một skin, đặt file ZIP vào thư mục skin tương ứng trong Download. Trong ứng dụng, mở thư mục đó, **chuột phải vào file ZIP** rồi chọn **Dùng skin này**. Ứng dụng giải nén ZIP vào thư mục cùng tên trong Mods; tên file ZIP có thể khác tên skin. Bấm biểu tượng **Làm mới** sau khi thêm thư mục hoặc file từ Finder để cập nhật danh sách.

Mỗi skin có một thư mục riêng. Ví dụ:

```text
Mods/
├── A (default)/
├── A - ABC/
└── A - DE/

ZZZ_Download/
├── A (default)/
│   └── A.zip
├── A - ABC/
│   └── A.zip
└── A - DE/
    └── A.zip
```

Với `ZZZ_Download/A - ABC/A.zip`, lệnh **Dùng skin này** sẽ giải nén vào `Mods/A - ABC/`. Các skin khác của A vẫn nằm trong thư mục riêng.

## Xoá và đổi thư mục

Trong màn hình nội dung skin, chuột phải vào file hoặc thư mục rồi chọn **Xoá** và xác nhận. Ứng dụng xoá trực tiếp trên ổ đĩa, không chuyển vào Thùng rác. Các card skin ở màn hình chính chỉ dùng để mở thư mục.

Để đổi vị trí Mods hoặc Download, bấm biểu tượng **Settings** bên phải thanh tab. Bấm **Change** tại thư mục cần đổi, chọn vị trí mới rồi bấm **Save changes**.

Avatar mặc định và ảnh riêng của các skin có trong danh mục được lưu trong ứng dụng để hiển thị ngoại tuyến. Nguồn ảnh: [Zenless Zone Zero Wiki](https://zenless-zone-zero.fandom.com/wiki/Agent_Outfit).

## Cập nhật trên Windows

Khi có Internet, ứng dụng Windows tự kiểm tra phiên bản mới từ GitHub Releases lúc mở và mỗi ngày sau đó. Nếu có bản mới, cửa sổ cập nhật sẽ hướng dẫn tải và cài đặt. Bạn cũng có thể vào **Settings → Kiểm tra cập nhật** bất kỳ lúc nào. Hãy đặt thư mục Mods và Download bên ngoài thư mục cài đặt ứng dụng để giữ dữ liệu khi cập nhật.
