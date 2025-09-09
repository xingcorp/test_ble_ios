# Phase 1 — Tổng quan & Đánh giá khả thi

## Mục tiêu
- Chốt phạm vi nghiệp vụ chấm công theo **site** (UUID + major), không theo từng thiết bị khi **minor xoay**.
- Xác nhận đường đi kỹ thuật dùng **Region Monitoring** + **ranging burst** + **soft‑exit** + **SLCS/Geofence** + **server TTL/heartbeat**.
- Xây nền tảng kiểm thử hiện trường và telemetry.

## Yêu cầu nền tảng
- iOS 14+ (khuyến nghị 15+), Xcode 16+, Swift 5.9+.
- Quyền: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`. Tuỳ chọn: `NSBluetoothAlwaysUsageDescription` nếu dùng CoreBluetooth phụ trợ.
- Cấu hình: Bật **Background App Refresh** (UX onboarding + policy kiểm tra/nhắc).

## Ràng buộc & Hệ quả
- **20 regions**/app ⇒ quản lý theo **site** thay vì mỗi beacon.
- `didExitRegion` có thể trễ ~30–45s ⇒ triển khai **soft‑exit** để giảm thời gian checkout khi hợp lệ.
- App **terminated (not force‑quit)**: Region Monitoring vẫn **relaunch** để xử lý enter/exit; **force‑quit** thì không đảm bảo.

## Luồng chính
1) **Enter**: hệ thống đánh thức → app mở **ranging burst** 5–10s → xác định site gần nhất → `checkIn` (idempotent).
2) **Inside**: cập nhật **heartbeat** khi có dịp (mở màn hình, refresh lightweight, etc.).
3) **Soft‑exit pending**: RSSI tụt/no‑packet → đặt cờ + `requestState(for:)` + **grace** 30–60s.
4) **Exit**: `didExitRegion` hoặc xác nhận ngoài vùng sau grace → `checkOut`.

## Telemetry
- Ghi log: timestamps enter/exit, RSSI snapshots, ranging duration, network latency, retries.
- Metric: miss rate, false exit rate, median exit latency, battery impact.

## Rủi ro chính & Mitigation
- Người dùng **force‑quit** ⇒ cảnh báo UX + degrade (server TTL đóng phiên muộn có cờ).
- Beacon tắt/đứt nguồn ⇒ Geofence + SLCS "vá lưới".
- Nhiễu RSSI ⇒ smoothing + multi‑sample + grace window.
