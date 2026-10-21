# A08 · Phần điều khiển (Control)

---

## 1. Kết luận đặt lên đầu: A08 **không có** phần điều khiển

Không có bộ điều khiển, không có tín hiệu lệnh, không có bộ ghép kênh chọn chế độ, không có
enable, không có handshake. Danh sách cổng của `a08_popcount8` chỉ có **hai** mục:

```systemverilog
module a08_popcount8 (
    input  logic [7:0] a,
    output logic [3:0] ones
);
```

Đây **không** phải thiếu sót, mà là hệ quả trực tiếp của phân loại **Tổ hợp** ở Charter và
của bản chất bài toán.

## 2. Vì sao bài toán này không sinh ra điều khiển

Một khối cần điều khiển khi nó phải **chọn** giữa nhiều hành vi, hoặc phải **sắp xếp** công
việc theo thứ tự thời gian. A08 không rơi vào cả hai:

| Câu hỏi sàng lọc | A08 | Hệ quả |
|---|---|---|
| Khối có nhiều chế độ hoạt động không? | Không — chỉ một hàm duy nhất `a → ones` | Không cần tín hiệu chọn chế độ |
| Kết quả có phụ thuộc đầu vào **trước đó** không? | Không | Không cần ô nhớ trạng thái |
| Công việc có phải chia thành nhiều bước theo thời gian không? | Không — 3 tầng chạy đồng thời theo dòng lan truyền | Không cần bộ đếm bước / FSM |
| Có tài nguyên dùng chung cần phân xử không? | Không — mỗi bộ cộng có phần cứng riêng | Không cần trọng tài (arbiter) |
| Có giao thức với bên ngoài không? | Không — chỉ dây tín hiệu | Không cần valid/ready |

Đối chiếu với các đề cùng nhóm A để thấy ranh giới: **A04 (ALU 8 chức năng)** *có* phần
điều khiển — ba bit `op` chọn nhánh chức năng qua một bộ ghép kênh. A08 không có gì tương
đương, vì nó chỉ làm đúng một việc.

## 3. Đối chiếu: cái gì **lẽ ra** là điều khiển nếu làm theo cách khác

Điểm này đáng giảng, vì nó cho thấy "có hay không có điều khiển" là **hệ quả của lựa chọn
kiến trúc**, không phải thuộc tính cố hữu của bài toán:

| Cách hiện thực popcount | Có điều khiển? | Nội dung điều khiển |
|---|---|---|
| **Cây cộng tổ hợp** (A08 đã chọn) | ❌ Không | — |
| Vòng lặp tuần tự: dịch 1 bit / chu kỳ, cộng dồn | ✅ Có | Bộ đếm 3 bit đếm 8 bước, tín hiệu `done`, thanh ghi dịch, thanh ghi tích luỹ — tức một **FSM đếm bước** |
| Tra bảng ROM 256 × 4 bit | ❌ Không | — (nhưng là bộ nhớ, không còn là logic tổ hợp thuần) |

Nếu Charter chọn phương án vòng lặp tuần tự, hồ sơ sẽ phải có `fsm.md` thật với 8 trạng
thái. Charter chọn cây cộng tổ hợp, nên `fsm.md` của A08 là một tài liệu **giải thích sự
vắng mặt**. Xem `fsm.md`.

## 4. Điều khiển nằm ở đâu trong hệ thống

Điều khiển **tồn tại**, nhưng ở tầng trên A08:

```
 ┌──────────────────────────────────────────────────────────────────┐
 │  MIỀN CÓ ĐIỀU KHIỂN (có clock, có trạng thái)                     │
 │                                                                  │
 │   ┌────────────────┐      ┌──────────────────────────────────┐   │
 │   │ Đồng bộ hoá    │      │ Logic quyết định / MCU           │   │
 │   │ 2 FF           │      │ · ngưỡng báo động theo `ones`    │   │
 │   │ (clk hệ thống) │      │ · chống rung, trễ xác nhận       │   │
 │   └───────┬────────┘      │ · chọn thời điểm lấy mẫu         │   │
 │           │               └───────────────▲──────────────────┘   │
 │           │                               │                      │
 │           │      ┌────────────────────────┴───────┐              │
 │           │      │ Thanh ghi chốt 4-bit (clk)     │              │
 │           │      └────────────────▲───────────────┘              │
 └───────────┼───────────────────────┼──────────────────────────────┘
             │                       │
 ┌───────────▼───────────────────────┴──────────────────────────────┐
 │  MIỀN KHÔNG ĐIỀU KHIỂN — A08                                     │
 │      a[7:0] ──▶ cây cộng 3 tầng ──▶ ones[3:0]                    │
 │      hàm thuần tuý, không trạng thái, không nhịp                 │
 └──────────────────────────────────────────────────────────────────┘
```

**Trách nhiệm phân chia rõ:**

| Trách nhiệm | Thuộc về |
|---|---|
| Bảo đảm `a[7:0]` ổn định và không siêu ổn định | Tầng trên (bộ đồng bộ hoá) |
| Tính đúng `ones` từ `a` | **A08** |
| Chọn **khi nào** đọc `ones` (sau khi đã ổn định ≥ 1,31 ns) | Tầng trên (thanh ghi chốt) |
| Diễn giải `ones` thành quyết định báo động | Tầng trên (MCU / logic quyết định) |
| Chống rung, trễ xác nhận, lọc nhiễu theo thời gian | Tầng trên |

Ranh giới này là **điều kiện để A08 dùng lại được**: cùng một lõi phục vụ được hệ 8 cảm
biến báo cháy, hệ 8 công tắc hành trình, hay bộ đếm trọng số Hamming trong một khối ECC —
vì nó không mang theo giả định nào về nhịp, ngưỡng hay chính sách.

## 5. Bằng chứng "không có điều khiển"

| Bằng chứng | Nguồn | Kết quả |
|---|---|---|
| Không có cổng `clk` / `rst` / `en` trong RTL | `04_IMPLEMENTATION/rtl/a08_popcount8.sv` | Danh sách cổng chỉ có `a`, `ones` |
| Không có cell tuần tự trong netlist | Yosys `stat -liberty` | 22 cell: `and2_0`, `maj3_1`, `xor2_1`, `xor3_1` — **0 FF, 0 latch** |
| Không có công suất nhóm Sequential / Clock | OpenSTA `report_power` | Sequential 0,0 % · Clock 0,0 % · **Combinational 100 %** |
| Không phụ thuộc lịch sử đầu vào | Testbench mục `[6]` | `a = 0xAA` sau chuỗi `0x00, 0xFF` vẫn cho `ones = 4`, khớp lần đầu |
| Không có đường phản hồi | Đồ thị phụ thuộc ở `datapath.md` §3 | Đồ thị là DAG một chiều |

Bốn bằng chứng đầu đến từ **bốn công cụ / cơ chế khác nhau**, nên chúng không cùng sai theo
một kiểu.

---

*Phiên bản: v2.0 · Ngày: 2026-09-24.*
