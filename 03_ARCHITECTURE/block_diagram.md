# A08 · Sơ đồ khối bên trong (Block Diagram)

Sơ đồ dưới đây vẽ theo **đúng RTL đã viết** (`04_IMPLEMENTATION/rtl/a08_popcount8.sv` và
`a08_adders.sv`), không phải vẽ theo ý tưởng chung chung. Mỗi hộp là một **instance module
thật**, mỗi mũi tên là một **net thật** có tên trong mã nguồn.

---

## 1. Toàn cảnh cây cộng 3 tầng

```
        TẦNG 1                 TẦNG 2                  TẦNG 3
   4 bộ cộng 1-bit        2 bộ cộng 2-bit          1 bộ cộng 3-bit
   8 bit → 4 số (0..2)    4 số → 2 số (0..4)       2 số → 1 số (0..8)

 a[0] ──┐
        │ ┌──────────────┐ l1_0
 a[1] ──┴─│ u_l1_0    HA │══════╗   2
          └──────────────┘      ║
                                ╠══▶┌──────────────┐ l2_0
 a[2] ──┐                       ║   │ u_l2_0  ADD2 │════════╗  3
        │ ┌──────────────┐ l1_1 ║   └──────────────┘        ║
 a[3] ──┴─│ u_l1_1    HA │══════╝   2                       ║
          └──────────────┘                                  ║
                                                            ╠═▶┌──────────────┐
 a[4] ──┐                                                   ║  │ u_l3_0  ADD3 │══▶ ones[3:0]
        │ ┌──────────────┐ l1_2                             ║  └──────────────┘  4   (0..8)
 a[5] ──┴─│ u_l1_2    HA │══════╗   2                       ║
          └──────────────┘      ║                           ║
                                ╠══▶┌──────────────┐ l2_1   ║
 a[6] ──┐                       ║   │ u_l2_1  ADD2 │════════╝  3
        │ ┌──────────────┐ l1_3 ║   └──────────────┘
 a[7] ──┴─│ u_l1_3    HA │══════╝   2
          └──────────────┘

          ↑ SONG SONG              ↑ SONG SONG               ↑ hội tụ
          4 bộ chạy đồng thời      2 bộ chạy đồng thời        1 bộ duy nhất
```

Số ghi cạnh mỗi bó dây là **độ rộng bit**. Quy luật độ rộng là điểm cần giảng:

| Tầng | Toán hạng vào | Dải giá trị vào | Dải giá trị ra | Bit ra cần |
|---|---|---|---|---:|
| 1 | 2 bit đơn | `0…1` mỗi cái | `0…2` | 2 |
| 2 | 2 số 2-bit | `0…2` mỗi cái | `0…4` | 3 |
| 3 | 2 số 3-bit | `0…4` mỗi cái | `0…8` | 4 |

Mỗi tầng làm độ rộng tăng đúng **1 bit** và làm số toán hạng giảm đúng **một nửa**. Sau
`log₂ 8 = 3` tầng thì còn 1 toán hạng, rộng `1 + 3 = 4` bit. Đó là lý do hình học của cả
"3 tầng" lẫn "4 bit ra".

## 2. Bên trong một bộ cộng 1-bit (half adder) — tầng 1

```
        ┌────────────────────────────┐
  x ────┤──┬──────▶╲                 │
        │  │        )XOR ──────────▶ │──── s   (trọng số 1)
  y ────┤──┼──┬───▶╱                 │
        │  │  │                      │
        │  └──┼───▶╲                 │
        │     │     )AND ──────────▶ │──── c   (trọng số 2)
        │     └───▶╱                 │
        └────────────────────────────┘
              a08_half_adder
```

`s = x ⊕ y`, `c = x ∧ y`. Hai cổng **song song**: `c` không chờ `s`. Kết quả là số 2-bit
`{c, s}` ∈ `{0, 1, 2}` — lưu ý `{c,s}` **không bao giờ** bằng `3` (`x=y=1` cho `{1,0} = 2`).

Sau ánh xạ thư viện sky130: đúng **1 `xor2_1` + 1 `and2_0`** — 2 cell, 15,0144 µm².

## 3. Bên trong một bộ cộng 2-bit — tầng 2

```
   p[0] ──┐  ┌──────────┐
          ├──│ u_ha0 HA │──── s ───────────────────────────▶ s[0]
   q[0] ──┘  │          │──── c ──┐  (net `c0`)
             └──────────┘         │
                                  │
   p[1] ──┐  ┌──────────┐         │
          ├──│ u_fa1 FA │◀── cin ─┘
   q[1] ──┘  │          │──── s ───────────────────────────▶ s[1]
             │          │──── cout ────────────────────────▶ s[2]
             └──────────┘             (net `c1`, chỉ là dây)
```

Vị trí 0 **không** có carry vào nên dùng half adder — tiết kiệm đúng một cổng so với dùng
full adder rồi nối `cin = 0`. Vị trí 1 có carry vào nên phải là full adder.
`s[2]` lấy thẳng `c1`: **0 cổng thêm**.

## 4. Bên trong bộ cộng 3-bit — tầng 3

```
   p[0] ──┐  ┌──────────┐
          ├──│ u_ha0 HA │──── s ───────────────────────────▶ ones[0]
   q[0] ──┘  │          │──── c ──┐  (net `c0`)
             └──────────┘         │
   p[1] ──┐  ┌──────────┐         │
          ├──│ u_fa1 FA │◀── cin ─┘
   q[1] ──┘  │          │──── s ───────────────────────────▶ ones[1]
             │          │──── cout ─┐  (net `c1`)
             └──────────┘           │
   p[2] ──┐  ┌──────────┐           │
          ├──│ u_fa2 FA │◀── cin ───┘
   q[2] ──┘  │          │──── s ───────────────────────────▶ ones[2]
             │          │──── cout ────────────────────────▶ ones[3]
             └──────────┘             (net `c2`, chỉ là dây)
```

**Đây là khối nặng nhất của thiết kế** và là nơi đường tới hạn kết thúc. Nó chứa một
**chuỗi carry ripple 3 mắt xích** (`c0 → c1 → c2`) — nghĩa là bên trong "một tầng" của cây
cộng vẫn còn một cấu trúc nối tiếp. Điểm này là mấu chốt để trả lời Charter mục 9; xem
`datapath.md` §4 và `timing_diagram.md` §2.

## 5. Ánh xạ RTL → cell thư viện: đếm từng viên gạch

Mỗi half adder ánh xạ thành 2 cell, mỗi full adder cũng 2 cell (sky130 có sẵn `xor3_1` và
`maj3_1` khớp đúng hai phương trình của full adder):

| Khối | Số instance | Cell mỗi instance | Cell | Diện tích mỗi cái (µm²) | Tổng (µm²) |
|---|---:|---|---:|---:|---:|
| `a08_half_adder` (tầng 1) | 4 | `xor2_1` + `and2_0` | 8 | 8,7584 + 6,2560 | 60,0576 |
| `a08_half_adder` (trong 2× `add2`) | 2 | `xor2_1` + `and2_0` | 4 | như trên | 30,0288 |
| `a08_full_adder` (trong 2× `add2`) | 2 | `xor3_1` + `maj3_1` | 4 | 23,7728 + 10,0096 | 67,5648 |
| `a08_half_adder` (trong `add3`) | 1 | `xor2_1` + `and2_0` | 2 | như trên | 15,0144 |
| `a08_full_adder` (trong `add3`) | 2 | `xor3_1` + `maj3_1` | 4 | như trên | 67,5648 |
| **TỔNG** | | | **22** | | **240,2304** |

Tổng hợp lại theo loại cell — đúng bảng Yosys in ra:

```
   sky130_fd_sc_hd__and2_0         7      7 half adder × 1 AND
   sky130_fd_sc_hd__maj3_1         4      4 full adder × 1 MAJ3
   sky130_fd_sc_hd__xor2_1         7      7 half adder × 1 XOR2
   sky130_fd_sc_hd__xor3_1         4      4 full adder × 1 XOR3
   ─────────────────────────────────
   Number of cells:               22
   Chip area:            240,230400 µm²
   Flip-flop:                      0
```

> 🔎 **Ánh xạ 1 : 1 hoàn hảo.** Thiết kế có tổng cộng 7 half adder (4 ở tầng 1 + 1 trong mỗi
> `add2` + 1 trong `add3`) và 4 full adder (1 trong mỗi `add2` + 2 trong `add3`).
> Netlist có đúng 7 `xor2` + 7 `and2` + 4 `xor3` + 4 `maj3`. **Không một cổng nào bị gộp,
> bị tách hay bị nhân bản.** Với một thiết kế đã tổng hợp qua `abc`, mức trùng khớp này là
> bất thường — và nó có nguyên nhân cụ thể, xem `tradeoff.md` §5.

## 6. Cái gì **không** có trong sơ đồ này

| Thành phần | Có trong A08? | Vì sao |
|---|---|---|
| Flip-flop / thanh ghi | ❌ **0 cái** | Mạch tổ hợp. Đã xác nhận bằng hai nguồn độc lập: bảng cell Yosys và `report_power` (Sequential = 0,0 %) |
| Latch | ❌ | `assign` liên tục, không có `always_comb` gán thiếu nhánh |
| Clock, reset, enable | ❌ | Không có trong danh sách cổng |
| Bộ ghép kênh (mux) | ❌ | Không có lựa chọn chế độ nào |
| Bộ điều khiển / FSM | ❌ | Xem `control.md` và `fsm.md` |
| Đường phản hồi (feedback) | ❌ | Dữ liệu chảy một chiều từ `a` tới `ones` |

---

*Phiên bản: v2.0 · Ngày: 2026-09-24 · Thành phần hồ sơ bắt buộc #5 (artifact số có chú thích).*
