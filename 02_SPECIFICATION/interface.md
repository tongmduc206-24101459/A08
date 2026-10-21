# A08 · Giao diện (Interface)

---

## 1. Ánh xạ chân theo Charter (mục 4)

> Theo danh mục đề: ui_in[7:0]=dữ liệu · uo_out[3:0]=số bit 1
> Ngân sách chân: 8 bit vào + 4 bit ra = 12 trên 24 chân.
> Ánh xạ chân đã khả thi, không phải đổi gì.
> Một ô Tiny Tapeout có đúng 24 chân: ui_in 8 chỉ vào, uo_out 8 chỉ ra, uio 8 chọn chiều từng chân. uio_in và uio_out là cùng một bộ chân vật lý.

## 2. Bảng giao diện đã CHỐT — module `a08_popcount8`

Bảng dưới đây **đọc trực tiếp từ RTL** (`04_IMPLEMENTATION/rtl/`), không phải chép tay,
nên luôn nhất quán với mã nguồn.

| Tín hiệu | Chiều | Độ rộng (bit) | Vai trò | Mức tích cực / giả định |
|---|---|---:|---|---|
| _(không đọc được cổng)_ | | | | |

**Tổng hợp:** 0 cổng vào (0 bit) · 0 cổng ra (0 bit).

**Không có clock** — khối tổ hợp thuần.

**Không có reset** — không có trạng thái để đặt lại.

## 3. Ngân sách chân Tiny Tapeout

| Hạng mục | Số bit |
|---|---:|
| Tổng bit vào | **0** |
| Tổng bit ra | **0** |
| **Tổng cộng** | **0** |
| Ô Tiny Tapeout có | **24** |
| **Chênh lệch** | **24 chân còn dư** |

> Nhắc lại cấu trúc chân Tiny Tapeout: một ô có đúng 24 chân — `ui_in` 8 chỉ vào,
> `uo_out` 8 chỉ ra, `uio` 8 chọn chiều từng chân; **`uio_in` và `uio_out` là cùng một bộ
> chân vật lý**.

> ✅ Ngân sách chân **đủ**: tổng số bit logic nằm trong 24 chân vật lý, không cần
> nạp nhiều nhịp và không phải hy sinh tín hiệu nào.

## 4. Điều kiện hợp lệ của đầu vào

| Điều kiện | Ai bảo đảm |
|---|---|
| Các cổng vào không chứa `X`/`Z` khi lấy mẫu | Tầng ngoài |
| Đầu ra được lấy mẫu sau khi mạch đã ổn định | Tầng ngoài, theo số liệu `06_GDSII/sta/` |


---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-A08-002, AC-1.*
