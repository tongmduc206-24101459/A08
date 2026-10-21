# A08 · Đường dữ liệu (Datapath)

---

## 1. Toàn bộ khối A08 **là** datapath

A08 không có phần điều khiển. Mọi tín hiệu đều là dữ liệu chảy một chiều từ đầu vào ra đầu
ra; không tín hiệu nào đóng vai trò lệnh, chọn chế độ, hay enable.

```
  a[7:0] ═══▶ ┌─────────────────────────────────────┐ ═══▶ ones[3:0]
              │  cây cộng 3 tầng                    │      (0 … 8)
              │  4 HA → 2 ADD2 → 1 ADD3             │
              └─────────────────────────────────────┘
              8 bit vào                        4 bit ra
              KHÔNG có nhánh điều khiển, KHÔNG có phản hồi
```

Một đặc điểm hiếm: **độ rộng dữ liệu co lại** dọc theo đường đi (8 bit → 4 bit), chứ không
giữ nguyên như bộ cộng hay bộ dịch. A08 là một khối **nén thông tin**: nó vứt bỏ thông tin
"kênh nào đang báo" và chỉ giữ lại "bao nhiêu kênh đang báo". Chính vì vậy hàm của nó
**không khả nghịch**: 70 giá trị đầu vào khác nhau cùng cho `ones = 4`.

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Dải | Từ | Đến | Bản chất |
|---|---:|---|---|---|---|
| `a[7:0]` | 8 | 0…255 | cổng vào | 4 half adder tầng 1 | Dữ liệu gốc — mỗi bit là một kênh cảm biến |
| `l1_0[1:0]` | 2 | 0…2 | `u_l1_0` | `u_l2_0.p` | Tổng riêng phần `a[0]+a[1]` |
| `l1_1[1:0]` | 2 | 0…2 | `u_l1_1` | `u_l2_0.q` | Tổng riêng phần `a[2]+a[3]` |
| `l1_2[1:0]` | 2 | 0…2 | `u_l1_2` | `u_l2_1.p` | Tổng riêng phần `a[4]+a[5]` |
| `l1_3[1:0]` | 2 | 0…2 | `u_l1_3` | `u_l2_1.q` | Tổng riêng phần `a[6]+a[7]` |
| `l2_0[2:0]` | 3 | 0…4 | `u_l2_0` | `u_l3_0.p` | **Số kênh đang báo ở nửa thấp `a[3:0]`** |
| `l2_1[2:0]` | 3 | 0…4 | `u_l2_1` | `u_l3_0.q` | **Số kênh đang báo ở nửa cao `a[7:4]`** |
| `u_l2_x.c0` | 1 | — | `u_ha0` | `u_fa1.cin` | Mắt xích carry nội bộ bộ cộng 2-bit |
| `u_l3_0.c0` | 1 | — | `u_ha0` | `u_fa1.cin` | Mắt xích carry 1 của bộ cộng 3-bit |
| `u_l3_0.c1` | 1 | — | `u_fa1` | `u_fa2.cin` | **Mắt xích carry 2 — nằm trên đường tới hạn** |
| `ones[3:0]` | 4 | 0…8 | `u_l3_0` | cổng ra | Kết quả |

`l2_0` và `l2_1` có ý nghĩa vật lý đọc được: chúng là **popcount của nửa từ**. Đây là lý do
INV-4 (`ones(a) = ones(a[3:0]) + ones(a[7:4])`) kiểm được **trực tiếp** trên net nội bộ chứ
không phải suy ra từ đầu ra.

## 3. Đồ thị phụ thuộc (dependency graph)

Ký hiệu `@k` = độ sâu tính bằng **số tầng cell** kể từ cổng vào.

```
 @0   a[0] a[1]   a[2] a[3]   a[4] a[5]   a[6] a[7]      ← sẵn sàng ngay
        │    │      │    │      │    │      │    │
        └─┬──┘      └─┬──┘      └─┬──┘      └─┬──┘
          │           │           │           │
 @1    l1_0[1:0]   l1_1[1:0]   l1_2[1:0]   l1_3[1:0]     ← TẦNG 1, 4 bộ SONG SONG
          │           │           │           │              (s và c cùng ở @1)
          └─────┬─────┘           └─────┬─────┘
                │                       │
             u_l2_0                  u_l2_1               ← TẦNG 2, 2 bộ SONG SONG
                │                       │
 @2       l2_0[0] ◀── ha0.s        l2_1[0] ◀── ha0.s      ← bit thấp ra SỚM
 @3       l2_0[1] ◀── fa1.s        l2_1[1] ◀── fa1.s      ← bit giữa chờ c0
 @3       l2_0[2] ◀── fa1.cout     l2_1[2] ◀── fa1.cout
                └───────────┬───────────┘
                            │
                         u_l3_0                            ← TẦNG 3, 1 bộ duy nhất
                            │
 @3               ones[0] ◀── ha0.s      (vào từ l2_*[0] @2)
 @4               ones[1] ◀── fa1.s
 @5               ones[2] ◀── fa2.s      ◀── ĐƯỜNG TỚI HẠN
 @5               ones[3] ◀── fa2.cout   ◀── ĐƯỜNG TỚI HẠN
```

**Độ sâu logic theo từng bit đầu ra:**

| Đầu ra | Độ sâu (tầng cell) | Vì sao |
|---|---:|---|
| `ones[0]` | **3** | Chỉ qua 3 XOR: HA tầng 1 → HA của `add2` → HA của `add3`. **Nông nhất.** |
| `ones[1]` | **4** | Thêm một mắt xích carry trong `add3` |
| `ones[2]` | **5** | Thêm mắt xích carry thứ hai |
| `ones[3]` | **5** | Cùng đáy chuỗi carry với `ones[2]` |

## 4. Đối chiếu dự đoán với STA — độ sâu lý thuyết 3 so với thực tế 5

Charter mục 9 yêu cầu đúng phép đối chiếu này.

| Cách đếm | Con số | Nguồn |
|---|---:|---|
| Độ sâu **lý thuyết** của cây cộng | **3** | `log₂ 8 = 3` — Charter mục 9 |
| Độ sâu đo bằng **số bước module** (`ltp` trên netlist giữ phân cấp) | **3** | Yosys `ltp -noff`: `a[7] → u_l1_3 → u_l2_1 → u_l3_0` |
| Độ sâu đo bằng **số tầng cell thật** (`ltp` sau khi làm phẳng netlist đã ánh xạ) | **5** | Yosys `ltp -noff` sau `flatten` |
| Số cell trên đường tới hạn trong **báo cáo STA** | **5** | OpenSTA `report_checks -path_delay max` |

Đường tới hạn thật, chép từ báo cáo OpenSTA:

| # | Cell | Instance | Delay (ns) | Time (ns) |
|---:|---|---|---:|---:|
| — | — | `a[6]` (in) | 0,00 | 0,00 |
| 1 | `xor2_1` | `u_l1_3/_1_` | 0,17 | 0,17 |
| 2 | `and2_0` | `u_l2_1/u_ha0/_0_` | 0,19 | 0,36 |
| 3 | `xor3_1` | `u_l2_1/u_fa1/_1_` | 0,26 | 0,62 |
| 4 | `maj3_1` | `u_l3_0/u_fa1/_0_` | 0,37 | 0,98 |
| 5 | `maj3_1` | `u_l3_0/u_fa2/_0_` | 0,33 | **1,31** |
| — | — | `ones[3]` (out) | 0,00 | 1,31 |

**Startpoint → Endpoint:** `a[6]` → `ones[3]`, **data arrival time 1,31 ns**, slack 8,69 ns
(clock ảo `vclk` chu kỳ 10 ns; WNS 0,00 / TNS 0,00).

Đường **nhanh nhất** (`report_checks -path_delay min`): `a[7]` → `ones[0]`, **0,29 ns**, đi
qua đúng **3** cell, cả ba đều là `xor2_1`. Chênh **≈ 4,5×** trên cùng một netlist.

> 🔎 **Vì sao 5 chứ không phải 3 — và vì sao cũng không phải 6.**
>
> Con số 3 đếm **tầng của cây**, không đếm **tầng của cổng**. Mỗi "tầng" từ số 2 trở đi
> **tự nó là một bộ cộng ripple** có chuỗi carry bên trong: `add2` sâu 2 mắt xích, `add3`
> sâu 3 mắt xích. Nếu cộng thẳng `1 + 2 + 3` sẽ ra **6**.
>
> Thực tế đo được là **5**, ít hơn 6 một tầng, vì chuỗi carry của `add3` **không khởi động
> muộn nhất**: nó bắt đầu từ `u_ha0`, mà `u_ha0` chỉ cần `l2_0[0]` và `l2_1[0]` — hai bit
> **thấp nhất**, vốn sẵn sàng ở `@2`, sớm hơn các bit `l2_*[2]` (`@3`) một tầng. Nói cách
> khác: bit thấp của một tổng riêng phần ra sớm, nên tầng sau đã kịp "chạy đà" trong lúc
> bit cao còn đang tính.
>
> Đây là một hiệu ứng **chỉ nhìn thấy khi phân tích thời điểm đến (arrival time) chứ không
> nhìn thấy khi đếm sơ đồ khối**, và nó là câu trả lời định lượng cho Charter mục 9.

## 5. Vì sao không có thanh ghi trong datapath

| Câu hỏi | Trả lời |
|---|---|
| Dữ liệu có cần giữ qua chu kỳ không? | Không — A08 tính xong trong một lần lan truyền |
| Có pipeline không? | Không — Charter chốt loại mạch **Tổ hợp** |
| Vậy kết quả được chốt ở đâu? | Ở thanh ghi 4-bit **bên ngoài** — xem `system_diagram.md` §1 |
| Đầu vào chống siêu ổn định ở đâu? | Ở bộ đồng bộ hoá 2 FF **bên ngoài** — cũng ở `system_diagram.md` §1 |
| Nếu thêm thanh ghi vào trong thì sao? | Vi phạm Charter mục 10 (*"dấu hiệu làm đúng: 0 ô nhớ"*). **Đây đúng là lỗi của gói nguồn ban đầu** — nó là một thanh ghi 8-bit, 8 FF. Xem `05_VERIFICATION/known_issues.md`. |

## 6. Cơ hội pipeline (chỉ để thảo luận — **ngoài phạm vi**)

Nếu được phép thêm ô nhớ, chỗ cắt tự nhiên là **giữa tầng 2 và tầng 3**:

```
 [tầng 1 + tầng 2] ──▶ REG 6 bit (l2_0, l2_1) ──▶ [tầng 3]
   độ sâu 3 tầng cell            độ sâu 3 tầng cell   (1,31 ns → ~0,7 ns mỗi chặng)
   chi phí: +6 FF, +1 chu kỳ độ trễ, +cây clock (CTS từ n/a thành bắt buộc)
```

Cắt ở đây cân hơn cắt sau tầng 1 (ở đó hai nửa lệch nhau: chặng sau sẽ sâu 4 tầng cell).

Phương án này **không được dùng** cho A08: nó đổi loại mạch từ Tổ hợp sang Tuần tự và phá
vỡ dấu hiệu làm đúng của Charter mục 10. Ghi ở đây chỉ để trả lời câu "có cách nào nhanh
hơn không" khi bảo vệ. Xem thêm `tradeoff.md`.

---

*Phiên bản: v2.0 · Ngày: 2026-09-24.*
