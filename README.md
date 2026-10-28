# RoPhim iOS (WebView)

App iOS bọc trang https://rophim1.vip, có chặn quảng cáo, chặn popup và chuyển hướng lạ, hỗ trợ xem toàn màn hình và xoay ngang.

## Build ra file IPA bằng GitHub Actions
1. Tạo repo mới trên GitHub (để **Public** thì phút build macOS miễn phí).
2. Tải toàn bộ thư mục này lên repo, **giữ nguyên thư mục `.github`** (bị ẩn trên một số máy, nhớ bật hiện file ẩn).
3. Vào tab **Actions** → chọn **Build IPA (unsigned)** → **Run workflow**.
4. Chờ khoảng 3–5 phút, mở lần chạy vừa xong, kéo xuống phần **Artifacts** và tải `RoPhim-unsigned-ipa` (file zip, giải nén ra `RoPhim-unsigned.ipa`).
5. Ký và cài file IPA như bạn vẫn làm.

## Tùy chỉnh
- **Đổi tên miền** khi web đổi link: sửa `homeURL` trong `Sources/AppConfig.swift`.
- **Thêm tên miền quảng cáo** cần chặn: thêm vào `blockedDomains` cùng file.
- **Bundle ID**: sửa `PRODUCT_BUNDLE_IDENTIFIER` trong `project.yml` (công cụ ký thường cũng cho đổi lúc ký).
- **Icon**: thay file `Sources/Assets.xcassets/AppIcon.appiconset/icon-1024.png` (PNG 1024×1024, không trong suốt).
