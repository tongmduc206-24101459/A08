# A08 · Máy trạng thái hữu hạn (FSM)

---

## 1. A08 **không có** FSM

Không có trạng thái, không có chuyển trạng thái, không có sơ đồ trạng thái để vẽ.
Tài liệu này giải thích **vì sao** và trình bày **bằng chứng**.

## 2. Vì sao không có

Một FSM tồn tại khi đầu ra phụ thuộc **không chỉ** vào đầu vào hiện tại mà còn vào **lịch
sử** đầu vào. Hàm của A08 là:

```
ones = Σ (i = 0..7) a[i]
```

Vế phải chỉ chứa `a` **ở thời điểm hiện tại**. Không có số hạng nào tham chiếu tới quá khứ,
nên không có gì để nhớ, nên không có trạng thái, nên không có FSM.

Diễn đạt theo kiểu bảng chân lý: A08 là một hàm tổ hợp 8 vào → 4 ra, xác định đầy đủ bởi
**256 dòng**. Một FSM ngược lại cần thêm cột "trạng thái hiện tại" và cột "trạng thái kế
tiếp" — A08 không có hai cột đó.

## 3. Bằng chứng — năm nguồn độc lập

| # | Bằng chứng | Nguồn | Kết quả đo được |
|---|---|---|---|
| 1 | RTL không có cấu trúc tuần tự | `04_IMPLEMENTATION/rtl/*.sv` | Không có `always_ff`, không có `<=`, không có cổng `clk`/`rst` |
| 2 | Netlist không có cell nhớ | Yosys 0.33 `stat -liberty` | 22 cell, toàn bộ là `and2_0` / `maj3_1` / `xor2_1` / `xor3_1` — **0 flip-flop, 0 latch** |
| 3 | Công suất không có nhóm tuần tự | OpenSTA `report_power` | Sequential **0,0 %** · Clock **0,0 %** · Combinational **100 %** |
| 4 | Không phụ thuộc lịch sử, kiểm bằng thực nghiệm | Testbench `a08_tb.sv` mục `[6]` | Đặt `a = 0xAA` sau chuỗi `0x00 → 0xFF` vẫn cho `ones = 4`, y hệt lần đầu |
| 5 | STA không tìm thấy đường register-to-register | OpenSTA `report_checks` | Mọi đường đều là `input port → output port`, clock chỉ là mốc ảo `vclk` |

Bằng chứng #2 và #3 đặc biệt đáng nói vì chúng đến từ **hai công cụ khác nhau đọc hai thứ
khác nhau** (bảng cell so với mô hình công suất), mà vẫn cho cùng kết luận.

Bằng chứng #4 là loại mạnh nhất về mặt logic: nó **chủ động đi tìm** sự phụ thuộc lịch sử
bằng cách cố tình cho DUT đi qua toàn bộ không gian đầu vào rồi quay lại một giá trị cũ.

## 4. Đây chính là dấu hiệu làm đúng của Charter mục 10

Charter mục 10 ghi: *"Dấu hiệu làm đúng: 0 ô nhớ, nhỏ."*

| Chỉ số | Charter mong đợi | Đo được | Đạt? |
|---|---|---:|:-:|
| Flip-flop | 0 ô nhớ | **0** | ✅ |
| Quy mô | ~90–140 cell (Charter metadata) | **22 cell** | ✅ còn nhỏ hơn nhiều |
| Diện tích | 1×1 tile | **240,2304 µm²** | ✅ |

⚠️ **Đây đúng là chỗ bản nộp ban đầu sai.** Gói nguồn chứa `a08_register` — một thanh ghi
8-bit — và tổng hợp ra **8 flip-flop** (`dfxtp_1 × 8`), tức **8 ô nhớ** thay vì 0. Nếu chỉ
nhìn "mô phỏng PASS" thì không phát hiện ra; chính con số flip-flop trong bảng cell mới là
thứ tố cáo. Xem `05_VERIFICATION/known_issues.md`.

Bài học: **đếm flip-flop là phép kiểm loại mạch rẻ nhất và nhanh nhất.** Với một đề Charter
phân loại là Tổ hợp, bất kỳ con số nào khác 0 đều là lỗi thiết kế, không phải lựa chọn tối ưu.

## 5. FSM sẽ xuất hiện ở đâu nếu đổi kiến trúc

Để thấy sự vắng mặt này là **hệ quả của lựa chọn**, hãy xét phương án tuần tự:

```
   Nếu hiện thực popcount bằng "dịch 1 bit mỗi chu kỳ rồi cộng dồn":

   ┌──────┐  start  ┌──────────┐  cnt==7  ┌──────┐
   │ IDLE │────────▶│  SHIFT   │─────────▶│ DONE │
   └──────┘         │  + ACC   │          └──┬───┘
        ▲           └────┬─────┘             │
        │                │ cnt<7             │ ack
        │                └───────┐           │
        └────────────────────────┴───────────┘

   Chi phí (ƯỚC LƯỢNG trên giấy, CHƯA tổng hợp — không phải số đo):
            3 bit đếm bước + 8 bit thanh ghi dịch + 4 bit tích luỹ ≈ 15 FF
            + logic điều khiển + 8 chu kỳ độ trễ
   Đổi lại: chỉ cần 1 bộ cộng 4-bit thay vì 11 bộ cộng 1-bit (7 HA + 4 FA)
```

Phương án này **không** được dùng cho A08 vì nó vi phạm phân loại Tổ hợp của Charter và phá
vỡ dấu hiệu "0 ô nhớ". Nó được ghi ở đây để trả lời câu hỏi khi bảo vệ, và được so sánh
bằng số liệu ở `tradeoff.md` §3.

Lưu ý phân biệt: phương án trên **khác** với "cộng tuần tự từng bit" ở `tradeoff.md` §4 —
phương án ở `tradeoff.md` vẫn là **tổ hợp** (trải 7 bộ cộng thành một chuỗi không gian),
còn phương án ở đây **tuần tự theo thời gian** (dùng lại 1 bộ cộng qua 8 chu kỳ). Hai chữ
"tuần tự" chỉ hai thứ hoàn toàn khác nhau, và đây là một trong những chỗ sinh viên hay nhầm
nhất.

---

*Phiên bản: v2.0 · Ngày: 2026-09-24.*
