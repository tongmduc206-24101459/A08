# A08 · Sự cố đã biết và cách xử lý (Known Issues)

---

## ISSUE-A08-001 · Gói mã nguồn ban đầu hiện thực **một đề hoàn toàn khác**

**Mức độ:** Nghiêm trọng (chặn toàn bộ hồ sơ) · **Trạng thái:** ✅ **ĐÃ XỬ LÝ**

### 1. Hiện tượng

Gói nguồn giao cho đề A08 tên là `A08_Register_Implementation_Validation`. Nội dung của nó:

| Mục | Charter A08 yêu cầu | Gói nguồn thực tế chứa |
|---|---|---|
| Tên đề | Bộ đếm số bit 1 (population count) 8-bit | **Thanh ghi 8-bit** |
| Top module | — | `a08_register` |
| **Loại mạch** | **Tổ hợp** | **Tuần tự** |
| Cổng | `ui_in[7:0]` → `uo_out[3:0]` | `clk`, `rst`, `en`, `d[7:0]` → `q[7:0]` |
| Chức năng | `ones = Σ a[i]` | `q ← d` khi `en`, giữ giá trị khi không |

Hai thiết kế **không có quan hệ gì với nhau**: khác chức năng, khác giao diện, khác cả loại
mạch. Đây không phải một bản hiện thực chưa hoàn chỉnh của đề A08 — nó là bản hiện thực
**hoàn chỉnh của một đề khác**.

### 2. Phát hiện bằng cách nào

Sự cố lộ ra qua **ba dấu hiệu độc lập**, xếp theo thứ tự phát hiện:

**① Tên gói zip không khớp tên đề.** Gói tên `A08_Register_Implementation_Validation` —
chữ "Register" không xuất hiện ở bất kỳ đâu trong Charter A08. Điều này gợi ý gói được cấp
phát theo **một danh mục đề cũ**, trong đó mã A08 ứng với một đề khác.

**② Danh sách cổng không khớp Charter mục 4.** Charter chốt `ui_in[7:0]` → `uo_out[3:0]`,
tức 8 bit vào và 4 bit ra. RTL có `clk`, `rst`, `en`, `d[7:0]` → `q[7:0]` — 11 bit vào,
8 bit ra. Không có phép ánh xạ hợp lý nào giữa hai bộ cổng này.

**③ Số flip-flop khác 0 — bằng chứng quyết định.** Charter mục 10 ghi *"Dấu hiệu làm đúng:
0 ô nhớ, nhỏ."* Kết quả tổng hợp của mã cũ:

```
   sky130_fd_sc_hd__dfxtp_1        8      ← 8 FLIP-FLOP
   sky130_fd_sc_hd__mux2i_1        8
   sky130_fd_sc_hd__nor2_1         8
   Number of cells:               24
   Chip area:             270.259200 µm²
   report_power: Sequential 92,8 % · Combinational 7,2 %
```

**8 flip-flop thay vì 0.** Đây là dấu hiệu mạnh nhất vì nó là một con số khách quan do công
cụ in ra, không phụ thuộc cách đọc tài liệu.

> 🔎 **Bài học phương pháp.** Mô phỏng của mã cũ **PASS** (`A08 register validation PASS`),
> tổng hợp **PASS**, STA **PASS**. Ba dấu tick xanh — mà thiết kế vẫn sai đề hoàn toàn.
> Kiểm chứng chỉ trả lời "mã có khớp testbench của chính nó không", **không** trả lời "mã có
> đúng đề không". Phép kiểm rẻ nhất cho câu hỏi thứ hai là **đếm flip-flop và đối chiếu với
> phân loại loại mạch trong Charter** — mất vài giây và bắt được đúng lớp lỗi này.

### 3. Đã xử lý ra sao

Giảng viên đã **duyệt** phương án viết lại RTL đúng đề Charter. Ba bước:

| Bước | Việc | Kết quả |
|---|---|---|
| 1 | **Đóng băng bản gốc** vào `08_ORIGINAL_SOURCE/` (rtl, golden_model, testbench) | Nguyên vẹn, không sửa một ký tự |
| 2 | **Thiết kế lại** RTL, mô hình chuẩn và testbench đúng đề population count | `a08_popcount8` + thư viện bộ cộng |
| 3 | **Xác minh lại** bằng chính chuỗi công cụ cũ | Python PASS · Sim PASS · Synth PASS · **0 FF** |

Đối chiếu trước / sau:

| Chỉ số | Trước (`a08_register`) | Sau (`a08_popcount8`) |
|---|---:|---:|
| Loại mạch | Tuần tự ❌ | **Tổ hợp** ✅ |
| **Flip-flop** | **8** ❌ | **0** ✅ |
| Số cell | 24 | 22 |
| Diện tích | 270,2592 µm² | 240,2304 µm² |
| Công suất tuần tự | 92,8 % ❌ | **0,0 %** ✅ |
| Đúng đề Charter? | ❌ Không | ✅ Có |

Nhật ký thay thế chi tiết từng file: `08_ORIGINAL_SOURCE/PATCHLOG.md`.

### 4. Cách quay lui

```bash
D=out/A08_Bo_dem_so_bit_1_population_count_8bit
rm -f  $D/04_IMPLEMENTATION/rtl/*.sv
rm -f  $D/05_VERIFICATION/golden_model/*
rm -f  $D/05_VERIFICATION/testbench/*.sv
cp $D/08_ORIGINAL_SOURCE/rtl/*.sv          $D/04_IMPLEMENTATION/rtl/
cp $D/08_ORIGINAL_SOURCE/golden_model/*    $D/05_VERIFICATION/golden_model/
cp $D/08_ORIGINAL_SOURCE/testbench/*.sv    $D/05_VERIFICATION/testbench/
```

Sau khi quay lui, top module trở lại `a08_register` và mọi script phải đổi `-top` tương ứng.

---

## ISSUE-A08-002 · Báo cáo trong `06_GDSII/` vẫn là của thiết kế cũ

**Mức độ:** Trung bình · **Trạng thái:** 🟡 **CHỜ SINH LẠI**

Thư mục `06_GDSII/` (synthesis, sta, power) nằm ngoài phạm vi được phép sửa của đợt thiết
kế lại, nên **các báo cáo ở đó vẫn mô tả `a08_register`**: 24 cell, **8 FF**, 270,2592 µm²,
đường tới hạn `en → _32_`. Những con số này **không** áp dụng cho thiết kế mới.

**Số liệu đúng của thiết kế mới** nằm ở:

| Nội dung | Ở đâu |
|---|---|
| Cell / FF / diện tích | `08_ORIGINAL_SOURCE/PATCHLOG.md` §4 và `implementation-notes_A08.md` §6 |
| Đường tới hạn, độ trễ, slack | `03_ARCHITECTURE/datapath.md` §4, `03_ARCHITECTURE/timing_diagram.md` |
| So sánh kiến trúc | `03_ARCHITECTURE/tradeoff.md` §3 |

**Cách xử lý:** chạy lại chuỗi công cụ với `-top a08_popcount8`. Lệnh đầy đủ ở PATCHLOG §3.

Lưu ý khi sinh lại: netlist mới **giữ phân cấp module** (khác thiết kế cũ vốn chỉ có một
module). Vì vậy `stat -liberty` in ra **nhiều** dòng `Chip area for module ...` cho các
module con, và dòng đúng của khối là dòng **`Chip area for top module '\a08_popcount8'`**
trong phần `=== design hierarchy ===`. Lấy nhầm dòng đầu tiên sẽ ra diện tích của một module
con (ví dụ `a08_full_adder`: 33,7824 µm²) thay vì 240,2304 µm².

---

## ISSUE-A08-003 · `$countones` trong `always_comb` gây cảnh báo Icarus

**Mức độ:** Thấp (chỉ gây nhiễu log) · **Trạng thái:** ✅ **ĐÃ XỬ LÝ**

**Hiện tượng.** Khi viết mô hình chuẩn thứ hai bằng `always_comb` với các bit-select hằng
(`{3'b000, a[0]} + …`), Icarus Verilog 12.0 in ra 8 dòng:

```
sorry: constant selects in always_* processes are not currently supported
       (all bits will be included).
```

**Ảnh hưởng.** Vô hại về chức năng — Icarus chỉ mở rộng danh sách nhạy cảm để gồm mọi bit
của `a`, mà trong trường hợp này kết quả không đổi. Nhưng nó làm bẩn `iverilog_compile.log`
và dễ bị đọc nhầm thành lỗi thật.

**Đã xử lý.** Đổi `always_comb` thành `assign` trong `a08_reference_sum`. Biên dịch sạch,
không còn dòng cảnh báo nào.

**Ghi nhận để dùng lại:** đây là một hạn chế đã biết của Icarus 12.0, không phải lỗi mã.
Với mô hình chuẩn thuần tổ hợp, `assign` luôn an toàn hơn `always_comb`.

---

## 5. Bất biến kiểm chứng hiện có

Kiểm chứng của thiết kế mới dựa trên assertion **tức thời** viết thẳng trong testbench
(`if (...) $fatal(1, ...)`), đã chạy được với Icarus Verilog 12.0.

| Bất biến | Nội dung | Kết quả |
|---|---|---|
| INV-1 | Cây cộng đúng hình dạng Charter mục 10 — kiểm từng tầng bằng cách đọc net nội bộ `dut.l1_*`, `dut.l2_*` | ✅ 0 vi phạm |
| INV-2 | `0 ≤ ones ≤ 8`, không bit `X`/`Z` | ✅ 0 vi phạm |
| INV-3 | `ones(a) + ones(~a) = 8` | ✅ 0 vi phạm |
| INV-4 | `ones(a) = ones(a[3:0]) + ones(a[7:4])` | ✅ 0 vi phạm |
| INV-5 | Phân bố kết quả khớp hệ số nhị thức `C(8,k)` | ✅ 0 vi phạm |
| INV-6 | `ones=0 ⟺ a=0x00`;  `ones=8 ⟺ a=0xFF` | ✅ 0 vi phạm |
| INV-7 | Không phụ thuộc lịch sử đầu vào | ✅ kiểm ở mục `[6]` của testbench |

INV-1 là bất biến đặc thù và quan trọng nhất của đề này: nó là **bằng chứng kiến trúc duy
nhất có được từ mô phỏng**. Không có nó, một hiện thực `$countones` cũng sẽ PASS hết.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
