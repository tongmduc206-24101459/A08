# A08 · PATCHLOG — Nhật ký thay thế mã nguồn

**Ngày:** 2026-09-24 · **Phiên bản:** v2.0 · **Phê duyệt:** giảng viên đã duyệt việc viết
lại RTL đúng đề Charter cho nhóm đề A04–A09.

---

## 1. Vì sao phải thay

Gói nguồn `A08_Register_Implementation_Validation` chứa thiết kế của **một đề khác**:
`a08_register` — thanh ghi 8-bit, mạch **tuần tự**, trong khi Charter A08 là **Bộ đếm số
bit 1 (population count) 8-bit**, phân loại **Tổ hợp**.

Bằng chứng quyết định: mã cũ tổng hợp ra **8 flip-flop**, trong khi Charter mục 10 ghi
*"Dấu hiệu làm đúng: 0 ô nhớ."* Phân tích đầy đủ: `05_VERIFICATION/known_issues.md`
ISSUE-A08-001.

Vì bản gốc đã được đóng băng nguyên vẹn trong thư mục này, việc thay thế là **an toàn và
quay lui được**.

---

## 2. File nào bị thay, bằng gì

### 2.1 RTL — `04_IMPLEMENTATION/rtl/`

| Hành động | File | Nội dung |
|---|---|---|
| ❌ **XOÁ** | `a08_register.sv` | Thanh ghi 8-bit có `clk`/`rst`/`en` — sai đề, sai loại mạch |
| ✅ **TẠO** | `a08_popcount8.sv` | Module đỉnh: cây cộng 3 tầng, instantiate 4 half adder + 2 `add2` + 1 `add3` |
| ✅ **TẠO** | `a08_adders.sv` | Thư viện viên gạch: `a08_half_adder`, `a08_full_adder`, `a08_add2`, `a08_add3` — tất cả mô tả bằng cổng logic tường minh |

Bản gốc còn nguyên tại `08_ORIGINAL_SOURCE/rtl/a08_register.sv`.

### 2.2 Mô hình chuẩn — `05_VERIFICATION/golden_model/`

| Hành động | File | Nội dung |
|---|---|---|
| ❌ **XOÁ** | `a08_reference.sv` (bản cũ) | Mô hình thanh ghi |
| ❌ **XOÁ** | `reference_model.py` (bản cũ) | Mô hình thanh ghi |
| ✅ **TẠO** | `a08_reference.sv` | **Hai** module độc lập: `a08_reference` (dùng `$countones`) và `a08_reference_sum` (cộng dồn từng bit). Hai cách nghĩ khác nhau, cùng làm chuẩn. |
| ✅ **TẠO** | `reference_model.py` | Python thuần, **hai** hàm độc lập: `popcount()` (đếm trực tiếp) và `popcount_tree()` (mô phỏng đúng sơ đồ cây 4→2→1). Kiểm 10 ca + 6 bất biến trên toàn bộ 256 giá trị. In `PASS`/`FAIL`, thoát mã 0 khi đạt. |

### 2.3 Testbench — `05_VERIFICATION/testbench/`

| Hành động | File | Nội dung |
|---|---|---|
| ❌ **XOÁ** | `a08_tb.sv` (bản cũ) | Testbench thanh ghi: kiểm reset, enable, giữ giá trị qua chu kỳ |
| ✅ **TẠO** | `a08_tb.sv` | Instance DUT tên **`dut`**, cạnh đó là hai golden reference. Chạy 5 ca bắt buộc Charter mục 8 + 5 ca tự xây dựng (có ca biên) + **quét vét cạn 256 giá trị** + kiểm INV-1…INV-6. Mọi sai lệch `$fatal(1, ...)`. Ghi VCD cho 10 ca có tên rồi `$dumpoff` trước vòng quét. |

### 2.4 Tài liệu viết lại theo thiết kế mới

| File | Hành động |
|---|---|
| `02_SPECIFICATION/functional_spec.md` | ✏️ viết lại (thêm §0 ghi chú truy vết) |
| `02_SPECIFICATION/corner_cases.md` | ✏️ viết lại |
| `03_ARCHITECTURE/system_diagram.md` | ✏️ viết lại |
| `03_ARCHITECTURE/block_diagram.md` | ✏️ viết lại |
| `03_ARCHITECTURE/datapath.md` | ✏️ viết lại |
| `03_ARCHITECTURE/control.md` | ✏️ viết lại |
| `03_ARCHITECTURE/fsm.md` | ✏️ viết lại |
| `03_ARCHITECTURE/timing_diagram.md` | ✏️ viết lại |
| `03_ARCHITECTURE/tradeoff.md` | ✏️ viết lại |
| `implementation-notes_A08.md` | ✏️ viết lại |
| `05_VERIFICATION/known_issues.md` | ➕ tạo mới |
| `08_ORIGINAL_SOURCE/PATCHLOG.md` | ➕ tạo mới (file này) |

### 2.5 File **không** động tới

`08_ORIGINAL_SOURCE/{rtl,golden_model,testbench}/` · `01_REQUIREMENT/` · `06_GDSII/` ·
`07_TRACEABILITY/` · `README.md` · `implementation-notes_A08.html` ·
`04_IMPLEMENTATION/{scripts,constraints}` · `02_SPECIFICATION/{interface,timing,parameters}.md` ·
`05_VERIFICATION/{simulation.log,iverilog_compile.log,python_reference_run.log,test_matrix.csv,testplan.md,verification_report.md}`

⚠️ Các file ở nhóm cuối **vẫn chứa số liệu của thiết kế cũ** cho tới khi được sinh lại
tự động. Xem ISSUE-A08-002.

---

## 3. Lệnh xác minh đã chạy

```bash
D=<đường dẫn tuyệt đối tới out/A08_Bo_dem_so_bit_1_population_count_8bit>
T=$(mktemp -d)
LIB=<đường dẫn>/sky130hd.lib

# 1. Mô hình chuẩn Python
python3 $D/05_VERIFICATION/golden_model/reference_model.py

# 2. Mô phỏng
iverilog -g2012 -o $T/sim.vvp $D/04_IMPLEMENTATION/rtl/*.sv \
    $D/05_VERIFICATION/golden_model/*.sv $D/05_VERIFICATION/testbench/*.sv
cd $T && vvp sim.vvp

# 3. Tổng hợp
yosys -Q -p "read_verilog -sv $D/04_IMPLEMENTATION/rtl/*.sv; \
  hierarchy -check -top a08_popcount8; proc; opt; fsm; opt; memory; opt; techmap; opt; \
  dfflibmap -liberty $LIB; abc -liberty $LIB; setundef -zero; splitnets; opt_clean -purge; \
  stat -liberty $LIB"

# 4. (bổ sung) STA với clock ảo — mạch tổ hợp, không có clock thật
#    create_clock -name vclk -period 10.0
#    set_input_delay 0.0 -clock vclk [all_inputs]
#    set_output_delay 0.0 -clock vclk [all_outputs]
sta -no_splash -exit sta.tcl
```

---

## 4. Kết quả xác minh — TRƯỚC và SAU

| Mục | TRƯỚC (`a08_register`) | SAU (`a08_popcount8`) |
|---|---|---|
| Mô hình chuẩn Python | PASS | **PASS** (thoát mã 0) |
| Biên dịch Icarus | không lỗi | **không lỗi, không cảnh báo** |
| Mô phỏng RTL | PASS | **PASS — 266 vector / 0 lỗi** |
| Quét vét cạn | — | **256/256 giá trị** |
| Bất biến INV-1…INV-6 | — | **0 vi phạm** |
| Tổng hợp | PASS | **PASS** |
| Số cell | 24 | **22** |
| **Flip-flop** | **8** ❌ | **0** ✅ |
| Diện tích | 270,2592 µm² | **240,2304 µm²** |
| Phân bố cell | `dfxtp_1`×8, `mux2i_1`×8, `nor2_1`×8 | `xor2_1`×7, `and2_0`×7, `xor3_1`×4, `maj3_1`×4 |
| STA | PASS (`real_clock`) | **PASS** (`virtual_clock`) |
| Đường tới hạn | `en → _32_` | **`a[6] → ones[3]`** |
| Độ trễ tới hạn | 1,19 ns | **1,31 ns** |
| Đường nhanh nhất | — | `a[7] → ones[0]`, **0,29 ns** |
| Slack | 8,7 ns | **8,69 ns** |
| WNS / TNS | 0,00 / 0,00 | **0,00 / 0,00** |
| Công suất | 3,75e-05 W (tuần tự 92,8 %) | **1,75e-05 W (tổ hợp 100 %, tuần tự 0 %)** |
| Đúng đề Charter? | ❌ **KHÔNG** | ✅ **CÓ** |

### Bảng phân cấp sau tổng hợp — bằng chứng kiến trúc

```
   a08_popcount8                     1
     a08_add2                        2       ← TẦNG 2: 2 bộ cộng 2-bit
       a08_full_adder                1
       a08_half_adder                1
     a08_add3                        1       ← TẦNG 3: 1 bộ cộng 3-bit
       a08_full_adder                2
       a08_half_adder                1
     a08_half_adder                  4       ← TẦNG 1: 4 bộ cộng 1-bit

   Number of cells:                 22
   Chip area for top module '\a08_popcount8': 240.230400
```

Bảng này khớp **từng chữ** với Charter mục 10: *"4 bộ cộng 1-bit → 2 bộ cộng 2-bit → 1 bộ
cộng 3-bit."*

### Số đo bổ sung (cùng chuỗi công cụ, chỉ để phân tích)

| Phép đo | Kết quả | Dùng để trả lời |
|---|---|---|
| `ltp -noff` trên netlist giữ phân cấp | độ sâu **3** bước module | Charter mục 9 |
| `ltp -noff` sau `flatten` netlist đã ánh xạ | độ sâu **5** tầng cell | Charter mục 9 |
| Tổng hợp có thêm `flatten` | 20 cell · **163,9072 µm²** · 0,76 ns | `tradeoff.md` §5 |
| Biến thể "cộng tuần tự từng bit", giữ phân cấp | 30 cell · **201,4432 µm²** · 1,75 ns · 23,2 µW | Charter mục 2 câu 3 |
| Biến thể "cộng tuần tự từng bit", có `flatten` | 26 cell · **226,4672 µm²** · 1,52 ns | Charter mục 2 câu 3 |

Biến thể so sánh **không** nằm trong `04_IMPLEMENTATION/rtl/` vì nó không phải bài nộp; mã
nguồn đầy đủ để tái lập nằm trong `03_ARCHITECTURE/tradeoff.md` §3.4.

---

## 5. Cách quay lui

```bash
D=out/A08_Bo_dem_so_bit_1_population_count_8bit
rm -f  $D/04_IMPLEMENTATION/rtl/*.sv
rm -f  $D/05_VERIFICATION/golden_model/*
rm -f  $D/05_VERIFICATION/testbench/*.sv
cp $D/08_ORIGINAL_SOURCE/rtl/*.sv          $D/04_IMPLEMENTATION/rtl/
cp $D/08_ORIGINAL_SOURCE/golden_model/*    $D/05_VERIFICATION/golden_model/
cp $D/08_ORIGINAL_SOURCE/testbench/*.sv    $D/05_VERIFICATION/testbench/
```

Sau khi quay lui, top module trở lại `a08_register`; mọi script tổng hợp / STA phải đổi
`-top` và `link_design` tương ứng, và SDC phải quay về chế độ `real_clock`
(`create_clock ... [get_ports clk]`).

Đối chiếu trước / sau từng file:

```bash
diff -u $D/08_ORIGINAL_SOURCE/rtl/a08_register.sv $D/04_IMPLEMENTATION/rtl/a08_popcount8.sv
```

*(diff sẽ khác hoàn toàn — hai file không có quan hệ gì với nhau. Đây là kết quả đúng như
kỳ vọng, không phải lỗi thao tác.)*

---

## 6. Nguyên tắc đã tuân thủ

1. **Không bịa số liệu.** Mọi con số trong tài liệu này là con số công cụ vừa in ra.
2. **Không phát biểu vượt mức.** Không dùng "sign-off", "tape-out", "chế tạo", "chạy được
   ở XXX MHz".
3. **Nêu rõ những gì chưa chứng minh được:** chưa mô phỏng gate-level, chưa P&R, chưa DRC/
   LVS/GDS, chưa chạy nhiều góc PVT. Danh sách đầy đủ: `implementation-notes_A08.md` §11.
4. **Ngân sách chân không phải điểm mở.** Charter mục 4 ghi rõ *"Ánh xạ chân đã khả thi,
   không phải đổi gì"* — 12/24 chân.

---

## 7. Dựng lại mô hình chuẩn và testbench (2026-09-24)

> 📌 **Đánh số.** Yêu cầu công việc gọi mục này là “§6”, nhưng §6 của tài liệu đã có sẵn
> (*Nguyên tắc đã tuân thủ*). Để không tạo hai mục trùng số, mục mới lấy số kế tiếp là **§7**;
> nội dung giữ nguyên như yêu cầu.

### 7.1 Vì sao phải dựng lại

Sau khi bản thiết kế lại ở §1–§6 đã xác minh xong, một bước sinh tài liệu tự động
(`generate2.py`) có lỗi: nó **chép mã nguồn cũ từ `runs/A08/work/` đè lên**
`04_IMPLEMENTATION/rtl/`, `05_VERIFICATION/golden_model/` và `05_VERIFICATION/testbench/`.
Các file bị ghi đè sau đó được dọn đi cùng với file cũ.

Hậu quả **không đồng đều**:

| Thư mục | Trạng thái sau sự cố |
|---|---|
| `04_IMPLEMENTATION/rtl/` | ✅ **Còn nguyên** — `a08_popcount8.sv`, `a08_adders.sv` không mất |
| `05_VERIFICATION/golden_model/` | ❌ **Mất trắng** |
| `05_VERIFICATION/testbench/` | ❌ **Mất trắng** |

Lỗi của bộ sinh **đã được sửa**. Vì RTL còn nguyên, công việc lần này **không phải thiết kế
lại**, mà là **dựng lại mô hình chuẩn và testbench cho khớp RTL hiện có**, dựa trên
`02_SPECIFICATION/functional_spec.md`, `02_SPECIFICATION/corner_cases.md` và chính tài
liệu này.

### 7.2 File đã dựng lại

| Đường dẫn | Nội dung |
|---|---|
| `05_VERIFICATION/golden_model/a08_reference.sv` | **Hai** module chuẩn độc lập: `a08_reference` (dùng `$countones`) và `a08_reference_sum` (cộng dồn từng bit trong vòng lặp) |
| `05_VERIFICATION/golden_model/reference_model.py` | Python thuần: `popcount()` (đếm trực tiếp) + `popcount_tree()` (mô phỏng đúng sơ đồ cây 4→2→1). 10 ca có tên + INV-1…INV-6 trên toàn bộ 256 giá trị. In `PASS`, thoát mã 0 |
| `05_VERIFICATION/testbench/a08_tb.sv` | Instance DUT tên **`dut`**, cạnh đó là **hai** golden reference. 5 ca Charter mục 8 + 5 ca tự xây (có ca biên) + **quét vét cạn 256 giá trị** + INV-1…INV-7. Mọi sai lệch `$fatal(1, …)`. `$dumpoff` ngay trước vòng vét cạn |

**INV-1 được dựng lại đúng vai trò cũ**: testbench đọc **thẳng** các net nội bộ
`dut.l1_0…dut.l1_3`, `dut.l2_0`, `dut.l2_1` và so từng tầng với tổng cặp bit tương ứng. Đây
là bất biến duy nhất chứng minh **hình dạng cây cộng**, chứ không chỉ chứng minh kết quả —
một hiện thực viết bằng `$countones` cũng cho `ones` đúng y hệt.

**Không** sửa bất kỳ file nào khác. `04_IMPLEMENTATION/rtl/`, `08_ORIGINAL_SOURCE/{rtl,
golden_model,testbench}/`, `01_`, `02_`, `03_`, `06_`, `07_`, `README.md`,
`implementation-notes_A08.*` giữ nguyên.

### 7.3 Kết quả xác minh lần này

Cùng công cụ, cùng thư viện, cùng script với §3–§4: Icarus Verilog 12.0 · Yosys 0.33 ·
`sky130_fd_sc_hd` (`sky130hd.lib`).

| Hạng mục | Ghi ở §4 | **Đo lại 2026-09-24** | Khớp? |
|---|---|---|:--:|
| Mô hình chuẩn Python | PASS (thoát 0) | **PASS (thoát 0)** — 17/17 phép kiểm | ✅ |
| Biên dịch Icarus | không lỗi, không cảnh báo | **không lỗi, không cảnh báo** | ✅ |
| Mô phỏng RTL | PASS — 266 vector / 0 lỗi | **PASS — 266 vector / 0 lỗi** | ✅ |
| Quét vét cạn | 256/256 giá trị | **256/256 giá trị** | ✅ |
| Bất biến INV-1…INV-6 | 0 vi phạm | **1 322 lần kiểm, 0 vi phạm** | ✅ |
| Tổng hợp | PASS | **PASS** | ✅ |
| **Số cell** | 22 | **22** | ✅ |
| **Flip-flop** | 0 | **0** | ✅ |
| **Diện tích** | 240,2304 µm² | **240,2304 µm²** | ✅ |
| Phân bố cell | `xor2_1`×7, `and2_0`×7, `xor3_1`×4, `maj3_1`×4 | **y hệt** | ✅ |

Bảng phân cấp đo lại cũng trùng từng dòng với §4 — vẫn là bằng chứng “4 bộ cộng 1-bit →
2 bộ cộng 2-bit → 1 bộ cộng 3-bit”:

```
a08_popcount8       1
  a08_add2          2      <- TANG 2
    a08_full_adder  1
    a08_half_adder  1
  a08_add3          1      <- TANG 3
    a08_full_adder  2
    a08_half_adder  1
  a08_half_adder    4      <- TANG 1
```

Không có cell họ `df*`/`sdf*`/`dl*`/`sedf*` ⟹ **0 flip-flop, 0 latch**.

Ngoài ra INV-5 được kiểm lại sau vòng vét cạn: phân bố kết quả đo được là
`1 8 28 56 70 56 28 8 1`, **khớp đúng** hệ số nhị thức `C(8,k)` — tổng 256 giá trị.

> ✅ **Kết luận.** RTL không đổi nên số liệu tổng hợp phải y nguyên — và đúng là y nguyên.
> Con số 266 vector (10 ca có tên + 256 vét cạn) cũng khớp tuyệt đối với §4.

### 7.4 Không dựng lại được cái gì

Bản mô hình chuẩn và testbench cũ **không còn tồn tại** để so từng dòng. Những gì bảo đảm
được là **hành vi quan sát được** trùng khít (số vector, độ phủ vét cạn, phân bố nhị thức).
Cách viết bên trong có thể khác bản cũ; điều đó **không** ảnh hưởng tới kết luận vì cả hai
đều so DUT với cùng một đặc tả.

### 7.5 Cách quay lui

Mục này chỉ **thêm file** vào hai thư mục đang rỗng, không sửa gì sẵn có:

```bash
D=out/A08_Bo_dem_so_bit_1_population_count_8bit
rm -f $D/05_VERIFICATION/golden_model/* $D/05_VERIFICATION/testbench/*
```

---

*Phiên bản: v1.1 · Ngày: 2026-09-24 (v1.0: thiết kế lại · v1.1: dựng lại mô hình chuẩn và
testbench sau sự cố bộ sinh ghi đè).*
