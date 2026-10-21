# A08 · Sơ đồ hệ thống (System Diagram)

---

## 1. Sơ đồ khối hệ thống — hệ giám sát 8 cảm biến

Bối cảnh ứng dụng theo Charter mục 1: *"Khối đếm số cảm biến đang báo động trong hệ 8 cảm
biến: đếm số bit 1 chính là đếm số kênh đang tích cực."*

```
        ┌──────────────── MIỀN ANALOG / MIXED ─────────────────┐
        │                                                      │
 hiện   │  ┌──────────┐   ┌──────────┐                         │
 tượng ─┼─▶│ Cảm biến │──▶│ So sánh  │─┐                       │
 vật lý │  │   #0     │   │ ngưỡng   │ │ 1 bit "đang báo"      │
        │  └──────────┘   └──────────┘ │                       │
        │        ⋮             ⋮       ├── 8 đường ────────┐   │
        │  ┌──────────┐   ┌──────────┐ │                   │   │
        │  │ Cảm biến │──▶│ So sánh  │─┘                   │   │
        │  │   #7     │   │ ngưỡng   │                     │   │
        │  └──────────┘   └──────────┘                     │   │
        └──────────────────────────────────────────────────┼───┘
                                                           │
        ┌──────────────────── MIỀN SỐ ─────────────────────┼──────────────────┐
        │                                                  ▼                  │
        │   ┌──────────────────┐   a[7:0]   ╔═══════════════════════════╗     │
        │   │ Đồng bộ hoá 2 FF │──────────▶ ║        ►► A08 ◄◄          ║     │
        │   │ (chống siêu ổn   │            ║  a08_popcount8            ║     │
        │   │  định, CÓ clock) │            ║  cây cộng 3 tầng          ║     │
        │   └──────────────────┘            ║  TỔ HỢP THUẦN, 0 ô nhớ    ║     │
        │        ▲                          ╚════════════╤══════════════╝     │
        │        │ clk hệ thống                          │ ones[3:0]          │
        │        │                                       ▼                    │
        │        │                          ┌─────────────────────────┐       │
        │        │                          │ Thanh ghi chốt kết quả  │       │
        │        │                          │ (4-bit, CÓ clock)       │       │
        │        │                          │ ◀── ô nhớ nằm Ở ĐÂY     │       │
        │        │                          └────────────┬────────────┘       │
        │        │                                       ▼                    │
        │        │                          ┌─────────────────────────┐       │
        │        │                          │ Logic quyết định / MCU  │       │
        │        │                          │ · ones ≥ 3 → báo động   │       │
        │        │                          │   mức hệ thống          │       │
        │        │                          │ · ones = 8 → sự cố toàn │       │
        │        │                          │   cục, không phải 1 kênh│       │
        │        │                          │ · ones = 0 → hệ yên tĩnh│       │
        │        │                          └────────────┬────────────┘       │
        │        └───────────────────────────────────────┤                    │
        │                                                ▼                    │
        │                                    ┌─────────────────────────┐      │
        │                                    │  Hiển thị / truyền tin  │      │
        │                                    └─────────────────────────┘      │
        └──────────────────────────────────────────────────────────────────────┘
```

**Điểm cốt lõi của sơ đồ:** trong toàn hệ có ô nhớ ở **hai** chỗ — bộ đồng bộ hoá ở đầu vào
và thanh ghi chốt kết quả ở đầu ra — nhưng **cả hai đều nằm ngoài A08**. A08 chỉ là hàm tổ
hợp `f(a) → ones`.

Đây chính là chỗ gói nguồn ban đầu đã sai: nó hiện thực **thanh ghi** (một trong hai khối
láng giềng) thay vì **bộ đếm bit** (khối ở giữa). Xem `05_VERIFICATION/known_issues.md`.

**Vì sao ứng dụng này cần đúng một con số chứ không phải 8 đường riêng lẻ:** logic quyết
định quan tâm "có bao nhiêu kênh đang báo", không quan tâm "kênh nào". Một sự kiện vật lý
lớn làm nhiều kênh cùng báo; nhiễu làm đúng một kênh báo. `ones` là đại lượng phân biệt hai
tình huống đó, và nó gọn hơn 8 đường tới 2 lần (4 bit so với 8 bit).

## 2. Ranh giới khối A08

```
                 ╔═══════════════════════════════════════════════╗
    a[7:0] ─────▶║                                               ║
                 ║         a08_popcount8                         ║────▶ ones[3:0]
   (không clock) ║   cây cộng 3 tầng, tổ hợp thuần               ║      0 … 8
   (không reset) ║   22 cell · 0 flip-flop · 240,2304 µm²        ║
   (không enable)║                                               ║
                 ╚═══════════════════════════════════════════════╝
                      8 bit vào                      4 bit ra
                              └──── 12 / 24 chân — còn dư 12 ────┘
```

Ngân sách chân **không** phải điểm mở của đề này: Charter mục 4 ghi rõ *"Ánh xạ chân đã
khả thi, không phải đổi gì."*

## 3. Phân rã một tầng xuống dưới — đúng như phân cấp Yosys in ra

```
 a08_popcount8                        ← 1 instance
 ├── u_l1_0 : a08_half_adder          ┐
 ├── u_l1_1 : a08_half_adder          │ TẦNG 1 — 4 bộ cộng 1-bit
 ├── u_l1_2 : a08_half_adder          │ 8 bit  →  4 số 2-bit (0..2)
 ├── u_l1_3 : a08_half_adder          ┘
 │
 ├── u_l2_0 : a08_add2                ┐ TẦNG 2 — 2 bộ cộng 2-bit
 │     ├── u_ha0 : a08_half_adder     │ 4 số   →  2 số 3-bit (0..4)
 │     └── u_fa1 : a08_full_adder     │
 ├── u_l2_1 : a08_add2                ┘
 │     ├── u_ha0 : a08_half_adder
 │     └── u_fa1 : a08_full_adder
 │
 └── u_l3_0 : a08_add3                ┐ TẦNG 3 — 1 bộ cộng 3-bit
       ├── u_ha0 : a08_half_adder     │ 2 số   →  1 số 4-bit (0..8)
       ├── u_fa1 : a08_full_adder     │
       └── u_fa2 : a08_full_adder     ┘
```

Bảng phân cấp thật của Yosys (`stat -liberty`), chép nguyên văn:

```
   a08_popcount8                     1
     a08_add2                        2
       a08_full_adder                1
       a08_half_adder                1
     a08_add3                        1
       a08_full_adder                2
       a08_half_adder                1
     a08_half_adder                  4
```

> 🔎 Đọc bảng này là **bằng chứng kiến trúc trực tiếp**, không phải suy luận: `4` half adder
> ở mức đỉnh (tầng 1), `2` instance `a08_add2` (tầng 2), `1` instance `a08_add3` (tầng 3) —
> đúng từng chữ với Charter mục 10. Đây là lý do RTL giữ phân cấp module thay vì viết phẳng:
> Charter mục 10 cảnh báo *"đề yêu cầu dựng cây cộng để netlist đọc được"*, và bảng này
> chính là "đọc được" nghĩa là gì.

## 4. Sơ đồ vòng đời (Lifecycle) — RTL đến GDSII

Đây là thành phần bắt buộc số 6 của hồ sơ (Charter mục 3).

```
 ┌─────────────┐   ┌─────────────┐   ┌──────────────┐   ┌────────────┐
 │ 01 YÊU CẦU  │──▶│ 02 ĐẶC TẢ   │──▶│03 KIẾN TRÚC  │──▶│04 HIỆN THỰC│
 │  Charter    │   │ hành vi +   │   │ cây cộng     │   │  RTL .sv   │
 │             │   │ cấu trúc    │   │ 3 tầng       │   │ 2 file     │
 └─────────────┘   └─────────────┘   └──────────────┘   └─────┬──────┘
                                                              │
        ┌─────────────────────────────────────────────────────┘
        ▼
 ┌──────────────┐        ✅ ĐÃ CHẠY: 266 vector (256 vét cạn), 0 lỗi
 │05 KIỂM CHỨNG │        Icarus Verilog 12.0 + 2 golden model SV + Python
 │ sim + golden │        INV-1…INV-6 đều PASS
 └──────┬───────┘
        ▼
 ┌──────────────┐        ✅ ĐÃ CHẠY: Yosys 0.33 + sky130_fd_sc_hd
 │ TỔNG HỢP     │        22 cell · **0 FF** · 240,2304 µm²
 │ (06/synth)   │        phân cấp giữ nguyên → netlist đọc được
 └──────┬───────┘
        ▼
 ┌──────────────┐        ✅ ĐÃ CHẠY: OpenSTA, clock ảo `vclk`
 │ STA          │        đường tới hạn a[6] → ones[3] = 1,31 ns, 5 tầng cell
 │ (06/sta)     │        → đây là nơi trả lời câu phân tích riêng (mục 9)
 └──────┬───────┘
        ▼
 ┌──────────────┬──────────────┬──────────────┬──────────────┐
 │ FLOORPLAN    │  PLACEMENT   │ CTS (n/a)    │  ROUTING     │  ⬜ CHƯA CHẠY
 └──────────────┴──────────────┴──────┬───────┴──────────────┘
                                      ▼
                           ┌──────────────────┐
                           │  DRC · LVS · GDS │                  ⬜ CHƯA CHẠY
                           └────────┬─────────┘
                                    ▼
                           ┌──────────────────┐
                           │ 07 TRUY VẾT +    │
                           │ KẾT LUẬN/GIỚI HẠN│
                           └──────────────────┘

        ─────── NGOÀI PHẠM VI (Charter mục 3) ───────
        sign-off · tape-out · chế tạo · kiểm tra sau chế tạo
        đếm bit 1 trên dữ liệu rộng hơn 8 bit · đếm bit 0 liên tiếp (CLZ)
```

> **CTS ghi (n/a)** vì A08 không có clock — không có cây clock để dựng. Đây là kết quả hợp
> lệ của tầng đó, không phải bước bị bỏ sót. Báo cáo công suất của OpenSTA xác nhận độc lập:
> nhóm **Clock = 0,0 %**, nhóm **Sequential = 0,0 %**, nhóm **Combinational = 100 %**.

> ⚠️ **Lưu ý về thư mục `06_GDSII/`:** các báo cáo đang nằm ở đó được sinh ra từ **thiết kế
> cũ** (`a08_register`, 24 cell, 8 FF, 270,2592 µm²) và **chưa** phản ánh thiết kế mới. Chúng
> sẽ được sinh lại bằng chính chuỗi công cụ đã chạy ở đây. Số liệu đúng của thiết kế mới nằm
> trong tài liệu này, trong `implementation-notes_A08.md` §6 và trong
> `08_ORIGINAL_SOURCE/PATCHLOG.md`.

---

*Phiên bản: v2.0 · Ngày: 2026-09-24 · Thành phần hồ sơ bắt buộc #2 và #6.*
