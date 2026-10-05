# Visual Mods Manager

Visual Mods Manager giúp quản lý trang phục mod **Zenless Zone Zero** theo từng nhân vật trên desktop. Ứng dụng có sẵn danh sách nhân vật và ảnh đại diện để sử dụng ngoại tuyến. Mỗi trang phục có một thư mục riêng trong **Mods** và **Download**.

![Thư viện nhân vật trong tab Download](docs/images/library.png)

## Thiết lập lần đầu

1. Bấm **Thư mục Mods** và chọn nơi lưu các mod đã giải nén, ví dụ `ZZZ/Mods`.
2. Bấm **Thư mục Download**. Chọn **Đã có sẵn** để chọn thư mục đang chứa file ZIP, hoặc **Tạo mới** để chọn vị trí và đặt tên thư mục mới.
3. Bấm **Bắt đầu quản lý**.

Ứng dụng tạo các thư mục trang phục có trong danh mục ở cả hai vị trí. Tên thư mục không phân biệt chữ hoa và chữ thường. Nếu macOS yêu cầu chọn lại thư mục khi mở app lần sau, hãy chọn lại để cấp quyền truy cập.

## Duyệt thư viện

Chuyển giữa hai tab **Mods** và **Download** ở đầu cửa sổ. Hai tab có cùng danh sách nhân vật và trang phục. Bấm trái vào card để xem các file và thư mục bên trong; card nhân vật ở màn hình chính không có menu chuột phải.

- **Mods** chứa các mod đã giải nén.
- **Download** chứa các file ZIP bạn tự tải và đặt vào đúng thư mục trang phục. Ứng dụng không tự tải mod.

Trang phục mặc định hiển thị trên card bằng tên nhân vật, ví dụ **Astra Yao**. Trang phục khác hiển thị ngay sau đó, ví dụ **Astra Yao - Chandelier**. Trong tên thư mục trên ổ đĩa, trang phục mặc định vẫn có hậu tố `(default)`.

Dùng biểu tượng kính lúp để tìm nhân vật hoặc trang phục, biểu tượng làm mới để cập nhật sau khi thêm file từ Finder hoặc File Explorer. Trong màn hình chi tiết, biểu tượng thư mục ở góc phải mở vị trí hiện tại bằng trình quản lý file.

## Cài trang phục bằng chuột phải

Đặt file ZIP vào thư mục trang phục tương ứng trong **Download**. Trong app, bấm trái vào card trang phục để mở nội dung, sau đó **bấm chuột phải vào card file ZIP** và chọn **Dùng trang phục này** (biểu tượng xanh lá).

![Menu chuột phải trên file ZIP trong tab Download](docs/images/right-click-menu.png)

App giải nén ZIP vào một thư mục mới trước, rồi chuyển thư mục đó sang trang phục tương ứng trong **Mods**. Tên thư mục mới có dạng `Ten_Nhan_Vat_dd_mm_yy`; nếu tên đã tồn tại, app thêm hậu tố số để không ghi đè. File ZIP gốc vẫn ở **Download**.

Ví dụ:

```text
ZZZ_Download/
└── Astra Yao - Chandelier/
    └── TrangPhuc.zip

Mods/
└── Astra Yao - Chandelier/
    └── Astra_Yao_05_10_26/
        └── ...các file đã giải nén...
```

Tên file ZIP không cần trùng tên trang phục. Mỗi trang phục có thư mục riêng, nên cài một trang phục không làm thay đổi thư mục của trang phục khác.

## Xoá file và thư mục

Trong màn hình chi tiết của **Mods** hoặc **Download**, bấm chuột phải vào card file hoặc thư mục, chọn **Xoá** (biểu tượng đỏ), rồi xác nhận. File ZIP ở tab Download có cả hai lựa chọn **Dùng trang phục này** và **Xoá**; các mục khác chỉ có **Xoá**. Lệnh xoá tác động trực tiếp lên ổ đĩa và không chuyển vào Thùng rác.

## Đổi thư mục và cập nhật app

Bấm biểu tượng **Settings** bên phải thanh tab. Bấm **Change** tại Mods hoặc Download và chọn vị trí mới; thay đổi được áp dụng ngay sau khi chọn, không cần nút lưu.

Trên Windows, app kiểm tra phiên bản mới từ GitHub Releases khi mở và định kỳ sau đó. Bạn cũng có thể vào **Settings → Kiểm tra cập nhật**. Nên đặt Mods và Download ngoài thư mục cài đặt app để dữ liệu không bị ảnh hưởng khi cập nhật.

Ảnh nhân vật và trang phục có trong danh mục được lưu sẵn trong app. Nguồn ảnh: [Zenless Zone Zero Wiki](https://zenless-zone-zero.fandom.com/wiki/Agent_Outfit).
