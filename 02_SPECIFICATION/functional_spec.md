# A08 · Đặc tả chức năng (Functional Specification)

Tài liệu này định nghĩa **hành vi đúng** của khối A08, và — khác với một đặc tả thông thường —
còn ràng buộc cả **cấu trúc** phải dùng, vì tên đề và Charter mục 10 chỉ định kiến trúc.

---

## 0. ⚠️ Ghi chú truy vết — gói nguồn ban đầu thuộc một đề khác

Gói nguồn giao cho đề này tên là `A08_Register_Implementation_Validation` và chứa RTL của
**`a08_register` — một thanh ghi 8-bit có clock, reset, enable**. Đó **không** phải đề A08
của Charter hiện hành, và còn sai cả **loại mạch**: Charter phân loại A08 là **Tổ hợp**,
trong khi thanh ghi là mạch **Tuần tự** (tổng hợp ra 8 flip-flop).

Sự cố đã được xử lý: RTL, mô hình chuẩn và testbench được **thiết kế lại từ đầu** đúng đề
population count. Bản gốc đóng băng nguyên vẹn ở `08_ORIGINAL_SOURCE/`.

| | Trước | Sau |
|---|---|---|
| Top module | `a08_register` | `a08_popcount8` |
| Loại mạch | Tuần tự (sai đề) | **Tổ hợp** (đúng Charter) |
| Flip-flop sau tổng hợp | 8 | **0** |

Chi tiết sự cố: `05_VERIFICATION/known_issues.md`. Nhật ký thay thế: `08_ORIGINAL_SOURCE/PATCHLOG.md`.

---

## 1. Phương trình hành vi

Gọi `A ∈ [0, 255]` là từ dữ liệu 8-bit, `A[i]` là bit thứ `i`. Khi đó:

```
ones = Σ (i = 0..7) A[i]
```

| Đầu ra | Định nghĩa | Dải |
|---|---|---|
| `ones[3:0]` | số bit bằng 1 trong `A[7:0]` | `0 … 8` |

Dạng SystemVerilog tương đương (chỉ dùng trong golden model):

```systemverilog
ones = 4'($countones(a));
```

### Vì sao kết quả cần 4 bit chứ không phải 3 — Charter mục 2 câu 2

Đầu vào có 8 bit, nên số bit 1 nhận **9** giá trị khác nhau: `0, 1, …, 8`.
Ba bit chỉ biểu diễn được `2³ = 8` giá trị (`0 … 7`), thiếu đúng **một** giá trị là `8`.

```
 ones = 8  →  4'b1000   ← cần bit trọng số 8, ba bit không chứa nổi
 ones = 7  →  3'b111    ← giá trị lớn nhất mà ba bit biểu diễn được
```

Tổng quát: đếm bit 1 trên `N` bit cần `⌈log₂(N+1)⌉` bit ra. Với `N = 8` là `⌈log₂ 9⌉ = 4`.
Chi tiết "chỗ bẫy" `N+1` chứ không phải `N`: chỉ **một** giá trị duy nhất trong 256 giá trị
đầu vào (`0xFF`) làm `ones = 8`, nên lỗi cắt còn 3 bit sẽ chỉ lộ ra ở đúng một vector —
đây là lý do TC-002 (`0xFF`) là ca bắt buộc của Charter mục 8.

## 2. Đặc tả cấu trúc bắt buộc — cây cộng 3 tầng

Charter mục 10 chốt hình dạng: **4 bộ cộng 1-bit → 2 bộ cộng 2-bit → 1 bộ cộng 3-bit**.
Vì vậy hành vi ở §1 **chưa đủ**: cách hiện thực cũng bị ràng buộc.

```
 Tầng 1 (4 bộ cộng 1-bit, half adder) — kết quả 2 bit, dải 0..2
   l1_0 = A[0] + A[1]        l1_1 = A[2] + A[3]
   l1_2 = A[4] + A[5]        l1_3 = A[6] + A[7]

 Tầng 2 (2 bộ cộng 2-bit) — kết quả 3 bit, dải 0..4
   l2_0 = l1_0 + l1_1        (đếm nửa thấp A[3:0])
   l2_1 = l1_2 + l1_3        (đếm nửa cao  A[7:4])

 Tầng 3 (1 bộ cộng 3-bit) — kết quả 4 bit, dải 0..8
   ones = l2_0 + l2_1
```

Mỗi bộ cộng lại phải được dựng từ **cổng logic tường minh**, không được dùng toán tử `+`:

```
 half adder :  s = x ⊕ y                              c = x ∧ y
 full adder :  s = x ⊕ y ⊕ cᵢₙ                        cₒᵤₜ = (x∧y) ∨ (x∧cᵢₙ) ∨ (y∧cᵢₙ)
 bộ cộng 2-bit : 1 half adder (vị trí 0) + 1 full adder (vị trí 1)
 bộ cộng 3-bit : 1 half adder (vị trí 0) + 2 full adder (vị trí 1, 2)
```

> ❗ **Không** được viết trong RTL nộp bài:
> ```systemverilog
> assign ones = $countones(a);                              // ❌ CẤM
> assign ones = a[0]+a[1]+a[2]+a[3]+a[4]+a[5]+a[6]+a[7];    // ❌ CẤM
> always_comb begin ones = 0; for (i=0;i<8;i++) ones += a[i]; end  // ❌ CẤM
> ```
> Dòng thứ ba chính là chỗ Charter mục 10 gọi đích danh: *"Viết vòng `for` ở mức hành vi —
> đề yêu cầu dựng cây cộng để netlist đọc được."*
>
> Lý do: Charter mục 2 hỏi cây cộng có mấy tầng và mỗi tầng làm gì; Charter mục 9 bắt đối
> chiếu độ sâu lý thuyết 3 tầng với **độ sâu logic thực tế**. Viết tắt bằng toán tử sẽ
> giao việc chọn kiến trúc cho công cụ và **xoá mất đúng thứ cần quan sát**. Các toán tử
> tắt **chỉ** được dùng trong `05_VERIFICATION/golden_model/`, nơi chúng đóng vai trò chuẩn
> so sánh **độc lập**.

Bằng chứng ràng buộc này đã được tôn trọng: bảng phân cấp của Yosys in ra đúng cấu trúc đã
đặc tả (xem `06_GDSII/synthesis/` sau khi chạy lại, và §7 dưới đây).

## 3. Bảng hành vi — 5 ca bắt buộc của Charter mục 8

| # | `A` (hex) | `A` (nhị phân) | `ones` | Ý nghĩa trong bối cảnh 8 cảm biến |
|---|---:|---|---:|---|
| 1 | `0x00` | `00000000` | **0** | Không kênh nào báo động — hệ yên tĩnh |
| 2 | `0xFF` | `11111111` | **8** | Cả 8 kênh cùng báo — giá trị duy nhất cần bit thứ 4 |
| 3 | `0x0F` | `00001111` | **4** | Bốn kênh liền nhau ở nửa thấp |
| 4 | `0xAA` | `10101010` | **4** | Bốn kênh xen kẽ — cùng kết quả với ca 3, khác vị trí |
| 5 | `0x80` | `10000000` | **1** | Đúng một kênh, ở vị trí cao nhất |

Cặp ca 3 / ca 4 là **cặp phản chứng** cho một hiểu nhầm phổ biến: kết quả chỉ phụ thuộc
**số lượng** bit 1, **không** phụ thuộc **vị trí** của chúng.

## 4. Tính chất bất biến (invariants)

| ID | Bất biến | Kiểm ở đâu |
|---|---|---|
| INV-1 | Cấu trúc đúng hình dạng Charter mục 10: `l1_k` = tổng đúng cặp bit; `l2_j` = tổng đúng cặp `l1`; `ones` = `l2_0 + l2_1` | testbench đọc thẳng net nội bộ của DUT |
| INV-2 | `0 ≤ ones ≤ 8`, và không tín hiệu ra nào ở trạng thái `X`/`Z` | testbench, mọi vector |
| INV-3 | `ones(A) + ones(~A) = 8` (đối xứng bù bit) | testbench sau khi quét vét cạn |
| INV-4 | `ones(A) = ones(A[3:0]) + ones(A[7:4])` — chính là điều tầng 2 bảo đảm | testbench, mọi vector |
| INV-5 | Phân bố kết quả trên 256 giá trị khớp hệ số nhị thức `C(8,k)`: `1, 8, 28, 56, 70, 56, 28, 8, 1` | testbench + `reference_model.py` |
| INV-6 | `ones = 0` ⟺ `A = 0x00`;  `ones = 8` ⟺ `A = 0xFF` | testbench, mọi vector |
| INV-7 | Không phụ thuộc lịch sử đầu vào (mạch tổ hợp thuần) | testbench §[6] + **0 FF** sau tổng hợp |

INV-1 là bất biến **quan trọng nhất và đặc thù của đề này**: mô phỏng hành vi thuần chỉ kiểm
được `ones`, mà một hiện thực viết bằng `$countones` cũng cho `ones` đúng y hệt. Chỉ bằng
cách đọc thẳng các net `l1_*`, `l2_*` trong DUT mới chứng minh được **cây cộng có đúng hình
dạng Charter đòi**. Xem `05_VERIFICATION/testbench/a08_tb.sv`.

## 5. Điều kiện biên và hành vi không xác định

| Tình huống | Hành vi quy định |
|---|---|
| `A` có bit `X`/`Z` | **Không** đặc tả. A08 là lõi tổ hợp; tầng ngoài phải bảo đảm đầu vào hợp lệ. |
| Không có clock | Đúng như thiết kế. Không được thêm. |
| Không có reset | Đúng như thiết kế. Mạch tổ hợp không có trạng thái để reset. |
| Đầu vào đổi giá trị | `ones` có thể **glitch** trong thời gian lan truyền qua 3 tầng trước khi ổn định. Đây là hành vi bình thường của mạch tổ hợp; tầng ngoài phải lấy mẫu sau khi đã ổn định. Xem `03_ARCHITECTURE/timing_diagram.md` §4. |
| Đầu vào giữ nguyên | `ones` giữ nguyên. Không có khái niệm "chu kỳ" trong khối này. |
| Cả 8 kênh cùng báo | Hợp lệ, `ones = 8`. **Không** phải lỗi tràn — 4 bit đủ chứa. |

Khối này **không có** trạng thái không hợp lệ: mọi tổ hợp trong 256 giá trị đầu vào đều
hợp lệ và có kết quả xác định.

## 6. Bảng ánh xạ cổng ↔ Charter mục 4

Charter dùng tên chân chung của Tiny Tapeout; RTL dùng tên gợi nhớ. Ánh xạ:

| Chân Charter mục 4 | Cổng RTL | Hướng | Rộng | Ghi chú |
|---|---|---|---:|---|
| `ui_in[7:0]` | `a[7:0]` | vào | 8 | Trạng thái 8 kênh cảm biến, bit `i` = kênh `i` đang tích cực |
| `uo_out[3:0]` | `ones[3:0]` | ra | 4 | Số kênh đang tích cực, giá trị `0…8` |
| `uo_out[7:4]` | — | — | 4 | **Không dùng** — để tầng vỏ nối `0` |
| `uio[7:0]` | — | — | 8 | **Không dùng** |
| `clk`, `rst_n`, `ena` | — | — | — | **Không tồn tại trong RTL.** Mạch tổ hợp. Nếu tầng vỏ Tiny Tapeout bắt buộc có, chúng chỉ đi qua vỏ và **không** được nối vào lõi A08. |

**Ngân sách chân:** 8 bit vào + 4 bit ra = **12 / 24 chân**. Charter mục 4 ghi rõ *"Ánh xạ
chân đã khả thi, không phải đổi gì"* — A08 **không** có điểm mở về ngân sách chân
(khác A01, vốn cần 28 bit trên 24 chân).

## 7. Không gian đầu vào và mức độ đầy đủ của kiểm chứng

Không gian đầu vào là `2⁸ = 256` tổ hợp — nhỏ đến mức **quét vét cạn là chuyện hiển nhiên
phải làm**, không phải một lựa chọn kiểm thử.

Kết quả thật đã đo: **266 vector chạy (10 ca có tên + 256 vét cạn), 0 lỗi** — DUT khớp
**cả hai** mô hình chuẩn SystemVerilog độc lập và khớp `reference_model.py`.

Hệ quả logic và giới hạn của nó:

> 256/256 khớp ⟹ DUT **tương đương hàm** với mô hình chuẩn. Không còn ca hành vi nào để tìm.
>
> Nhưng điều đó **không** chứng minh kiến trúc là cây cộng — một dòng `$countones` cũng
> khớp 256/256. Bằng chứng kiến trúc đến từ **INV-1** (đọc net nội bộ), từ **bảng phân cấp
> Yosys**, và từ **đường tới hạn trong STA**.

---

*Phiên bản: v2.0 · Ngày: 2026-09-24 · Truy vết: REQ-A08-001…007.*
*v2.0 = thiết kế lại đúng đề Charter sau sự cố lệch nguồn (§0).*
