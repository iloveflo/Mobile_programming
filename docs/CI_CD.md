# 2.5. Kế hoạch triển khai kiểm thử và CI/CD

**Người phụ trách:** Thắng — Backend, Database và CI/CD.

## Mục tiêu

Quy trình CI/CD tự động kiểm tra chất lượng mã nguồn, chạy kiểm thử và tạo file APK Android. Pull request chỉ nên được hợp nhất vào `main` khi pipeline CI thành công. Phiên bản có tag dạng `vX.Y.Z` sẽ được pipeline CD đóng gói và phát hành trên GitHub Releases.

## Luồng CI (Continuous Integration)

File `.github/workflows/ci.yml` chạy khi có pull request vào `main`, hoặc push lên `main`/`develop`:

1. Checkout mã nguồn và cài Flutter stable.
2. Cài dependency bằng `flutter pub get`.
3. Kiểm tra định dạng bằng `dart format`.
4. Phân tích tĩnh bằng `flutter analyze --fatal-infos`.
5. Chạy unit/widget test và sinh báo cáo coverage.
6. Chỉ khi các bước kiểm tra thành công, build Android debug APK.
7. Lưu APK và coverage thành GitHub Actions Artifact trong 14 ngày.

## Luồng CD (Continuous Delivery)

File `.github/workflows/release.yml` chạy thủ công hoặc tự động khi push tag `vX.Y.Z`. Pipeline phân tích và kiểm thử lại trước khi build release APK. Với tag hợp lệ, APK được đính kèm vào GitHub Release và release notes được tạo tự động.

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Chiến lược nhánh và kiểm soát chất lượng

- `main`: mã nguồn ổn định, dùng để phát hành.
- `develop`: nhánh tích hợp tính năng trước khi đưa vào `main`.
- `feature/*`: nhánh làm việc riêng của từng chức năng/thành viên.
- Bật Branch Protection cho `main`; yêu cầu pull request và hai status check `Quality and tests`, `Build Android APK` thành công.
- Không commit khóa ký, mật khẩu, token hoặc file môi trường bí mật lên Git.

## Kiểm thử hiện có

- Widget smoke test xác nhận ứng dụng khởi động tại màn hình đăng nhập.
- Unit test đăng nhập thành công, đăng nhập thất bại và đăng xuất.
- Mỗi chức năng mới cần có test tương ứng trước khi merge.

## Triển khai production trong tương lai

Pipeline hiện tạo APK phục vụ demo nội bộ; Android đang dùng debug signing cho release build. Trước khi đưa ứng dụng lên Google Play, nhóm cần tạo release keystore, lưu dữ liệu ký trong GitHub Actions Secrets, ký Android App Bundle (`.aab`) và bổ sung bước triển khai lên Internal Testing của Google Play.

## Tiêu chí hoàn thành

- Format, analyzer và toàn bộ test đều đạt.
- APK được build thành công và tải được từ artifact/release.
- Pipeline thất bại rõ ràng khi code lỗi, test lỗi hoặc không tạo được APK.
- Thông tin bí mật không xuất hiện trong repository hay log CI.
