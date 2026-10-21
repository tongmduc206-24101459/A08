# A08 — Bộ đếm số bit 1 (population count) 8-bit · Ghi chú thực hiện

---

## 1. Bài toán này thực chất là gì

Bề mặt: "đếm xem trong 8 bit có bao nhiêu bit bằng 1". Một dòng Python.

Thực chất, Charter chọn A08 vì nó là ví dụ sạch nhất cho một điều rất khó dạy:
**có những phép tính mà cách viết ra nó quan trọng hơn kết quả của nó.**

Với cộng hay nhân, viết `a + b` rồi để công cụ chọn kiến trúc thường là lựa chọn đúng trong
công việc thật. Với A08, Charter mục 10 gọi thẳng chỗ hay tắc:

> *"Viết vòng `for` ở mức hành vi — đề yêu cầu dựng cây cộng để netlist đọc được."*

Cụm **"để netlist đọc được"** là toàn bộ nội dung đề bài. Một dòng `$countones(a)` cho kết
quả đúng 256/256, tổng hợp được, chạy được — và **vô dụng về mặt giảng dạy**, vì không còn
gì để đếm tầng, không còn gì để đối chiếu với STA, không trả lời được mục 2 lẫn mục 9.

Bối cảnh ứng dụng — hệ 8 cảm biến báo động — không phải trang trí. Nó giải thích vì sao đầu
ra là **một con số** chứ không phải 8 đường riêng: logic quyết định cần biết "bao nhiêu
kênh đang báo" (sự kiện vật lý lớn làm nhiều kênh cùng báo; nhiễu chỉ làm một kênh báo).

## 2. Bản chất kỹ thuật — cơ chế hoạt động

### Ý tưởng gốc: đếm = cộng

Đếm số bit 1 chính là **cộng cả 8 bit lại với nhau**, vì mỗi bit đúng bằng 0 hoặc 1:

```
ones = a[0] + a[1] + a[2] + a[3] + a[4] + a[5] + a[6] + a[7]
```

Câu hỏi thiết kế không phải "cộng cái gì" mà **"cộng theo thứ tự nào"**. Hai cách xếp thứ
tự cho cùng kết quả nhưng khác hẳn về phần cứng:

```
 Chuỗi thẳng:  ((((((( a0+a1 )+a2 )+a3 )+a4 )+a5 )+a6 )+a7 )     độ sâu O(N) = 7 bước
 Cây cộng:     ((a0+a1)+(a2+a3)) + ((a4+a5)+(a6+a7))             độ sâu O(log N) = 3 bước
```

Phép cộng có tính **kết hợp**, nên đổi cách đặt ngoặc không đổi kết quả — nhưng đổi hẳn
hình dạng mạch. Cây cộng khai thác đúng tính chất đó.

### Ba tầng, mỗi tầng làm gì

```
 TẦNG 1 — 4 bộ cộng 1-bit (half adder), CHẠY SONG SONG
   Việc: gộp 8 bit đơn thành 4 số 2-bit.    Dải kết quả: 0..2
   l1_0 = a[0]+a[1]   l1_1 = a[2]+a[3]   l1_2 = a[4]+a[5]   l1_3 = a[6]+a[7]

 TẦNG 2 — 2 bộ cộng 2-bit, CHẠY SONG SONG
   Việc: gộp 4 số thành 2 số 3-bit.         Dải kết quả: 0..4
   l2_0 = l1_0+l1_1  ← số kênh báo ở NỬA THẤP a[3:0]
   l2_1 = l1_2+l1_3  ← số kênh báo ở NỬA CAO  a[7:4]

 TẦNG 3 — 1 bộ cộng 3-bit
   Việc: gộp 2 số thành 1 số 4-bit.         Dải kết quả: 0..8
   ones = l2_0 + l2_1
```

Quy luật bất biến qua các tầng: **số toán hạng giảm một nửa, độ rộng tăng đúng 1 bit.**
Sau `log₂ 8 = 3` tầng còn 1 toán hạng, rộng `1 + 3 = 4` bit.

Điểm tinh tế: các giá trị trung gian **có ý nghĩa vật lý đọc được**. `l2_0` đúng bằng số
cảm biến đang báo ở nửa thấp. Đây không phải sản phẩm phụ — đó là điều làm netlist "đọc
được", và là cách testbench kiểm được **cấu trúc** chứ không chỉ kiểm **kết quả**.

### Vì sao mỗi bộ cộng lại không cân về độ trễ

Mỗi "tầng" từ số 2 trở đi **tự nó là một bộ cộng ripple**:

```
 bộ cộng 2-bit : HA(vị trí 0) ─ c0 ─▶ FA(vị trí 1)            chuỗi carry dài 2
 bộ cộng 3-bit : HA(vị trí 0) ─ c0 ─▶ FA(vị trí 1) ─ c1 ─▶ FA(vị trí 2)   chuỗi carry dài 3
```

Nên "cây cộng 3 tầng" **không** có nghĩa "3 tầng cổng". Đây là hạt nhân của câu hỏi Charter
mục 9, trả lời đầy đủ ở §8.

## 3. Đọc mã nguồn: RTL làm gì

Toàn bộ kiến trúc nằm trong 7 dòng instantiate:

```systemverilog
// TANG 1 — 4 bo cong 1-bit (half adder), hoan toan song song
a08_half_adder u_l1_0 (.x(a[0]), .y(a[1]), .s(l1_0[0]), .c(l1_0[1]));
a08_half_adder u_l1_1 (.x(a[2]), .y(a[3]), .s(l1_1[0]), .c(l1_1[1]));
a08_half_adder u_l1_2 (.x(a[4]), .y(a[5]), .s(l1_2[0]), .c(l1_2[1]));
a08_half_adder u_l1_3 (.x(a[6]), .y(a[7]), .s(l1_3[0]), .c(l1_3[1]));

// TANG 2 — 2 bo cong 2-bit
a08_add2 u_l2_0 (.p(l1_0), .q(l1_1), .s(l2_0));
a08_add2 u_l2_1 (.p(l1_2), .q(l1_3), .s(l2_1));

// TANG 3 — 1 bo cong 3-bit
a08_add3 u_l3_0 (.p(l2_0), .q(l2_1), .s(ones));
```

Bốn điểm cần giảng kỹ:

1. **`{c, s}` của half adder LÀ một số 2 bit.** Sinh viên quen nghĩ `s` là "tổng" và `c` là
   "bit nhớ" — hai thứ riêng. Ở đây phải đọc chúng là **một số nhị phân hai bit**:
   `{c,s} = 00, 01, 10` tương ứng `0, 1, 2`. Giá trị `11 = 3` **không bao giờ** xảy ra.
   Không nhìn ra điều này thì không hiểu vì sao tầng 2 nhận toán hạng 2-bit.

2. **Vị trí 0 dùng half adder, không dùng full adder.** Vì không có carry vào. Mỗi lần thay
   được FA bằng HA là tiết kiệm `33,7824 − 15,0144 = 18,768 µm²` — và thiết kế làm việc đó
   ở **3** chỗ (trong hai `add2` và một `add3`).

3. **`s[2] = c1` và `s[3] = c2` chỉ là dây nối, 0 cổng.** Bit cao nhất của mỗi bộ cộng chính
   là carry ra của mắt xích cuối. Netlist xác nhận: không có cell nào sinh ra hai bit đó.

4. **Độ rộng bit không đồng nhất giữa các tầng (2 → 3 → 4).** Đây là điểm khác hẳn một bộ
   cộng thông thường, nơi mọi tầng đều rộng bằng nhau. Cắt độ rộng tối thiểu ở từng tầng là
   một phần của thiết kế, không phải chi tiết vụn.

### Bên trong các viên gạch

```systemverilog
// half adder: hai cong SONG SONG, c khong cho s
assign s = x ^ y;
assign c = x & y;

// full adder: cout la ham DA SO (majority) cua ba bit vao
assign s    = x ^ y ^ cin;
assign cout = (x & y) | (x & cin) | (y & cin);
```

Nhận ra `cout` là hàm majority giải thích vì sao `abc` ánh xạ nó thành đúng **một** cell
`sky130_fd_sc_hd__maj3_1` — thư viện có sẵn cổng đó.

### Điều tuyệt đối không được viết

```systemverilog
assign ones = $countones(a);                              // ❌ CẤM
assign ones = a[0]+a[1]+a[2]+a[3]+a[4]+a[5]+a[6]+a[7];    // ❌ CẤM
always_comb begin ones = 0; for (i=0;i<8;i++) ones += a[i]; end  // ❌ CẤM
```

Dòng thứ ba là chỗ Charter mục 10 gọi đích danh. Cả ba đều cho kết quả đúng, đều tổng hợp
được — và đều **xoá mất chính thứ đề bài yêu cầu quan sát**. Các toán tử tắt chỉ được dùng
trong `05_VERIFICATION/golden_model/`, nơi chúng là chuẩn so sánh **độc lập**.

## 4. Vì sao chọn kiến trúc này

Không phải vì cây cộng "tốt hơn mọi mặt" — số liệu ở §6 cho thấy nó **không** nhỏ hơn trong
flow nộp bài. Ba lý do thật, xếp theo sức nặng:

| Lý do | Nội dung |
|---|---|
| 1. Charter chốt | Mục 10 ghi thẳng hình dạng "4 bộ cộng 1-bit → 2 bộ cộng 2-bit → 1 bộ cộng 3-bit". Mục 2 và mục 9 đều hỏi **về cây cộng**. Làm khác là trả lời một đề khác. |
| 2. Nhanh hơn ở mọi flow | 1,31 ns so với 1,75 ns (giữ phân cấp); 0,76 ns so với 1,52 ns (flatten). Đây là chỉ số duy nhất **không đổi dấu** giữa hai flow. |
| 3. Mở rộng tốt hơn | Độ sâu `O(log N)` so với `O(N)`. Ở `N=8` chênh 3 so với 7; ở `N=32` chênh 5 so với 31. |

Và với **ứng dụng** cụ thể (giám sát 8 cảm biến, tốc độ lấy mẫu cỡ kHz), cả hai kiến trúc
đều thừa sức nhanh. Ở đây kiến trúc được chọn vì **yêu cầu đề bài về khả năng giải thích**,
không phải vì ràng buộc thời gian của ứng dụng. Nói thẳng điều đó trung thực hơn là dựng
một lý do kỹ thuật không có thật. So sánh đầy đủ bốn kiến trúc: `03_ARCHITECTURE/tradeoff.md`.

## 5. Cách thực hiện — lộ trình 8 bước

| # | Bước | Công cụ | Bằng chứng sinh ra | Trạng thái |
|---|---|---|---|---|
| 0 | **Phát hiện gói nguồn thuộc đề khác**, đóng băng bản gốc | đọc mã + đối chiếu Charter | `08_ORIGINAL_SOURCE/`, `05_VERIFICATION/known_issues.md` | ✅ |
| 1 | Suy bảng hành vi + **ràng buộc cấu trúc** từ Charter mục 8 và mục 10 | — | `02_SPECIFICATION/functional_spec.md` | ✅ |
| 2 | Viết mô hình chuẩn Python độc lập (2 cách nghĩ: đếm trực tiếp + mô phỏng cây) | CPython 3 | `golden_model/reference_model.py` | ✅ PASS, thoát 0 |
| 3 | Viết RTL với cây cộng **tường minh**, giữ phân cấp module | — | `04_IMPLEMENTATION/rtl/` (2 file) | ✅ |
| 4 | Viết testbench tự kiểm: 2 golden SV + kiểm **net nội bộ** (INV-1) + quét vét cạn | Icarus Verilog 12.0 | `simulation.log` | ✅ 266 vector / 0 lỗi |
| 5 | Tổng hợp lên sky130, **kiểm 0 flip-flop** | Yosys 0.33 | `synth_stat.txt` | ✅ 22 cell, **0 FF** |
| 6 | Đo độ sâu logic thật (`ltp`) và đối chiếu với lý thuyết 3 tầng | Yosys 0.33 | §8 tài liệu này | ✅ 3 module / **5 cell** |
| 7 | STA với clock ảo, **đếm cell trên đường tới hạn** | OpenSTA | `03_ARCHITECTURE/datapath.md` §4 | ✅ 1,31 ns, 5 cell |
| 8 | Physical design RTL→GDSII | LibreLane + sky130A | `06_GDSII/` | ⬜ chưa chạy |

Bước 0 là bước không có trong lộ trình chuẩn — nó tồn tại vì sự cố lệch nguồn. Xem
`05_VERIFICATION/known_issues.md` và `08_ORIGINAL_SOURCE/PATCHLOG.md`.

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | Công cụ |
|---|---:|---|
| Mô hình chuẩn Python | **PASS**, thoát mã 0 | CPython 3 |
| Vector kiểm chứng | **266 chạy / 0 lỗi** (10 ca có tên + 256 vét cạn) | Icarus Verilog 12.0 |
| Vi phạm bất biến INV-1…INV-6 | **0** | như trên |
| Số cell | **22** | Yosys 0.33 + `sky130_fd_sc_hd` |
| **Flip-flop** | **0** | như trên |
| Diện tích | **240,2304 µm²** | như trên |
| Phân bố cell | `xor2_1`×7 · `and2_0`×7 · `xor3_1`×4 · `maj3_1`×4 | như trên |
| Độ sâu — bước module | **3** | Yosys `ltp -noff` |
| Độ sâu — tầng cell thật | **5** | Yosys `ltp -noff` sau `flatten` |
| Đường tới hạn | `a[6] → ones[3]` | OpenSTA |
| **Độ trễ tổ hợp** | **1,31 ns**, qua 5 cell | OpenSTA |
| Đường nhanh nhất | `a[7] → ones[0]`, **0,29 ns**, 3 cell | OpenSTA |
| Slack / WNS / TNS | 8,69 ns · 0,00 · 0,00 (clock ảo 10 ns) | OpenSTA |
| Công suất | **17,5 µW** — tổ hợp **100 %**, tuần tự **0 %** | OpenSTA |

### Từng con số chứng minh gì — và KHÔNG chứng minh gì

| Con số | **Chứng minh** | **KHÔNG chứng minh** |
|---|---|---|
| 256/256 khớp | Hàm của DUT **tương đương** golden model. Không còn ca hành vi nào chưa kiểm. | Kiến trúc là cây cộng. Một dòng `$countones` cũng PASS hết. |
| INV-1 · 0 vi phạm | Cây cộng có **đúng hình dạng** Charter mục 10 — testbench đọc thẳng `l1_*`, `l2_*` và kiểm từng tầng | Netlist sau ánh xạ cell vẫn giữ hình dạng đó (cần mô phỏng gate-level) |
| **0 flip-flop** | Đúng phân loại Tổ hợp, xác nhận bởi **hai nguồn độc lập** (bảng cell Yosys + `report_power` Sequential = 0 %) | Netlist tương đương RTL về chức năng |
| 22 cell · 240,23 µm² | Thiết kế **nhỏ** — dưới ước lượng 90–140 cell của Charter tới ~4× | Diện tích sau P&R (sẽ khác vì có dây và cell bị `dont_use`) |
| 1,31 ns | Độ trễ **sau tổng hợp**, góc `tt_025C_1v80` | Độ trễ thật sau routing (sẽ **lớn hơn**, chưa có RC dây) |
| 5 tầng cell | Độ sâu logic thật của netlist nộp bài | Rằng đây là độ sâu tối thiểu có thể đạt (bản flatten chỉ còn 4) |
| 17,5 µW | Thứ tự độ lớn công suất | Công suất thật của ứng dụng — dùng activity mặc định, không lấy từ VCD |

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

### Câu 1 — Cây cộng để đếm bit 1 có mấy tầng, và mỗi tầng làm gì?

**Ba tầng.** Bằng chứng cấu trúc: bảng phân cấp Yosys in ra đúng `4 × a08_half_adder`
(mức đỉnh) + `2 × a08_add2` + `1 × a08_add3`.

| Tầng | Thành phần | Vào | Ra | Việc |
|---|---|---|---|---|
| 1 | 4 bộ cộng 1-bit (half adder) | 8 bit đơn | 4 số 2-bit, dải 0…2 | Gộp từng cặp bit kề nhau |
| 2 | 2 bộ cộng 2-bit | 4 số 2-bit | 2 số 3-bit, dải 0…4 | Đếm riêng nửa thấp `a[3:0]` và nửa cao `a[7:4]` |
| 3 | 1 bộ cộng 3-bit | 2 số 3-bit | 1 số 4-bit, dải 0…8 | Cộng hai nửa lại |

Quy luật chung: **mỗi tầng giảm một nửa số toán hạng và tăng đúng 1 bit độ rộng.**

### Câu 2 — Vì sao kết quả cần 4 bit chứ không phải 3?

Vì số bit 1 trong 8 bit nhận **9** giá trị (`0…8`), mà 3 bit chỉ biểu diễn được 8 giá trị
(`0…7`). Thiếu đúng **một** giá trị: `8 = 4'b1000`.

Công thức tổng quát: đếm bit 1 trên `N` bit cần `⌈log₂(N+1)⌉` bit — chú ý là `N+1`, không
phải `N`. Với `N = 8`: `⌈log₂ 9⌉ = 4`.

Bằng chứng thực nghiệm từ chính bộ dữ liệu đã chạy: trong 256 giá trị đầu vào, **đúng một**
giá trị (`0xFF`) làm `ones = 8`. Phân bố đầy đủ, khớp hệ số nhị thức `C(8,k)`:

| `ones` | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Số giá trị | 1 | 8 | 28 | 56 | **70** | 56 | 28 | 8 | **1** |

Hệ quả thực tiễn: lỗi cắt kết quả còn 3 bit chỉ lộ ra ở **1/256 = 0,39 %** số vector. Kiểm
thử ngẫu nhiên hoàn toàn có thể bỏ sót; quét vét cạn thì không. Đó là lý do `0xFF` nằm
trong nhóm ca **bắt buộc** của Charter mục 8.

### Câu 3 — So diện tích cây cộng với cách cộng tuần tự từng bit — chênh bao nhiêu?

Đã dựng biến thể "cộng tuần tự từng bit" (chuỗi 7 bộ cộng nối tiếp, độ rộng cắt tối thiểu
từng tầng) và chạy **cùng script, cùng thư viện, cùng góc**. Mã nguồn đầy đủ để tái lập:
`03_ARCHITECTURE/tradeoff.md` §3.4.

| Chỉ số | Cây cộng (nộp bài) | Cộng tuần tự từng bit | Chênh |
|---|---:|---:|---|
| Số cell | **22** | 30 | +36,4 % |
| Diện tích | 240,2304 µm² | **201,4432 µm²** | cây cộng **lớn hơn 19,3 %** |
| Đường tới hạn | **1,31 ns** | 1,75 ns | cây cộng **nhanh hơn 25,1 %** |
| Cell trên đường tới hạn | **5** | 12 | 2,4× |
| Công suất | **17,5 µW** | 23,2 µW | +32,6 % |

**Câu trả lời trung thực: trong flow nộp bài, cây cộng KHÔNG nhỏ hơn — nó lớn hơn 19,3 %
về diện tích, đổi lại nhanh hơn 25,1 % và tốn ít công suất hơn 24,6 %.**

Nhưng dấu của chênh lệch diện tích **đảo ngược** nếu thêm một bước `flatten` vào flow:

| Flow | Cây cộng | Chuỗi thẳng | Ai nhỏ hơn? |
|---|---:|---:|---|
| Giữ phân cấp (nộp bài) | 240,2304 µm² | 201,4432 µm² | chuỗi thẳng, −16,1 % |
| Thêm `flatten` | **163,9072 µm²** | 226,4672 µm² | **cây cộng, −27,6 %** |

Nguyên nhân và cách đọc: §8 dưới đây và `tradeoff.md` §5. Một caveat bắt buộc nêu kèm: biến
thể chuỗi thẳng dùng 5 cell `lpflow_isobufsrc_1`, vốn nằm trong `dont_use` của cấu hình
LibreLane sky130 mặc định; chưa đo lại được khi cấm nhóm cell đó vì Yosys 0.33 không có
tuỳ chọn tương ứng cho `abc`.

## 8. Trả lời câu phân tích riêng (Charter mục 9)

> *"Cây cộng có độ sâu log₂(8) = 3 tầng. Đối chiếu với số tầng logic thực tế trong báo cáo
> STA và giải thích vì sao con số thực tế thường lớn hơn con số lý thuyết."*

### Số liệu đối chiếu

| Cách đếm | Con số | Nguồn |
|---|---:|---|
| Lý thuyết | **3** | `log₂ 8` |
| Bước module trên netlist giữ phân cấp | **3** | Yosys `ltp -noff`: `a[7] → u_l1_3 → u_l2_1 → u_l3_0` |
| Tầng cell thật (netlist nộp bài) | **5** | Yosys `ltp -noff` sau `flatten` |
| Cell trên đường tới hạn trong **báo cáo STA** | **5** | OpenSTA `report_checks -path_delay max` |
| Tầng cell thật (netlist đã flatten trước khi ánh xạ) | **4** | Yosys `ltp -noff` |

**Thực tế 5, lý thuyết 3 — lớn hơn 67 %.** Hai phép đo độc lập (Yosys `ltp` và OpenSTA)
cho cùng con số 5, nên đây không phải tạo tác của một công cụ.

Đường tới hạn thật, chép từ OpenSTA:

| # | Cell | Instance | Delay (ns) | Cộng dồn (ns) |
|---:|---|---|---:|---:|
| 1 | `xor2_1` | `u_l1_3/_1_` | 0,17 | 0,17 |
| 2 | `and2_0` | `u_l2_1/u_ha0/_0_` | 0,19 | 0,36 |
| 3 | `xor3_1` | `u_l2_1/u_fa1/_1_` | 0,26 | 0,62 |
| 4 | `maj3_1` | `u_l3_0/u_fa1/_0_` | 0,37 | 0,98 |
| 5 | `maj3_1` | `u_l3_0/u_fa2/_0_` | 0,33 | **1,31** |

### Ba nguyên nhân, xếp theo mức đóng góp

**① Nguyên nhân chính — "một tầng cây" không phải "một tầng cổng".**
Con số 3 đếm **tầng của cây**. Nhưng tầng 2 và tầng 3 **tự chúng là bộ cộng ripple** có
chuỗi carry bên trong: `add2` sâu 2 mắt xích, `add3` sâu 3 mắt xích. Đọc theo cấu trúc:

```
 tầng 1 đóng góp 1 tầng cổng  (half adder: 1 cổng)
 tầng 2 đóng góp 2 tầng cổng  (HA → FA qua c0)
 tầng 3 đóng góp 3 tầng cổng  (HA → FA → FA qua c0, c1)
 ───────────────────────────
 cộng thẳng                   = 6 tầng cổng
```

**② Nguyên nhân làm con số nhỏ hơn 6 — bit thấp ra sớm.**
Đo được là **5**, ít hơn ước lượng 6 đúng một tầng, vì chuỗi carry của `add3` **không khởi
động muộn nhất**: `u_ha0` chỉ cần `l2_0[0]` và `l2_1[0]` — hai bit **thấp nhất**, sẵn sàng
ở tầng cổng thứ 2, sớm hơn `l2_*[2]` (tầng 3) một nhịp. Tầng sau đã "chạy đà" trong lúc bit
cao còn đang tính. Đây là hiệu ứng **chỉ thấy khi phân tích thời điểm đến (arrival time)**,
không thấy khi đếm sơ đồ khối — và chính là lý do phải tin STA thay vì tin phép tính tay.

**③ Nguyên nhân thứ ba — thư viện quyết định "một tầng" rộng bao nhiêu.**
Thư viện `sky130_fd_sc_hd` có sẵn `xor3_1` và `maj3_1`, nên **mỗi full adder gói gọn trong
1 tầng cell** thay vì 2–3 tầng cổng cơ bản. Nếu thư viện không có hai cell đó, con số thực
tế sẽ **lớn hơn 5**. Nói cách khác: "số tầng logic thực tế" không phải thuộc tính của thuật
toán — nó là thuộc tính của **cặp (thuật toán, thư viện)**.

### Kết luận cho Charter mục 9

> Con số thực tế lớn hơn lý thuyết vì **lý thuyết đếm tầng của cây, còn STA đếm tầng của
> cổng**, mà mỗi tầng cây từ số 2 trở đi lại chứa một chuỗi carry riêng bên trong. Ở A08,
> chênh lệch là **3 → 5 tầng**, tức **+67 %**.
>
> Chênh lệch **không** phải hằng số: ước lượng từ cấu trúc cho 6, đo thật cho 5, và bản
> flatten cho 4. Ba con số khác nhau cho cùng một thuật toán — con số duy nhất được phép
> trích dẫn là con số của **chính netlist nộp bài**, tức **5**.

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| # | Sai lầm | Hậu quả | Phát hiện bằng bằng chứng nào |
|---|---|---|---|
| 1 | Viết `assign ones = $countones(a);` cho gọn | Mất kiến trúc; không đếm được tầng; mục 2 và mục 9 không trả lời được | Đọc RTL; bảng phân cấp Yosys không còn `a08_add2`/`a08_add3` |
| 2 | Viết vòng `for` ở mức hành vi (`ones += a[i]`) | **Chỗ Charter mục 10 gọi đích danh.** Công cụ tự chọn kiến trúc, netlist không đọc được | Đọc RTL; netlist không có cấu trúc 4→2→1 |
| 3 | Cho kết quả 3 bit vì "8 bit thì 3 bit đủ" | Sai đúng 1 trong 256 vector (`0xFF` → ra 0) | TC-002; và quét vét cạn bắt ngay |
| 4 | Nhầm `{c,s}` của half adder là hai thứ riêng, không phải một số 2-bit | Nối sai độ rộng vào tầng 2 | INV-1 trong testbench: `dut.l1_0 !== a[0]+a[1]` |
| 5 | Dùng full adder ở vị trí 0 rồi nối `cin = 0` | Lãng phí 18,768 µm² mỗi chỗ, × 3 chỗ | So bảng cell: sẽ thấy dư `xor3_1`/`maj3_1` |
| 6 | Tưởng "3 tầng" nghĩa là "3 cổng" | Kết luận sai về độ trễ | STA: 5 cell trên đường tới hạn, không phải 3 |
| 7 | Nghĩ `0xFF` là ca chậm nhất vì "nhiều bit 1 nhất" | Chọn sai vector đo timing | STA chỉ đường tới hạn xuất phát từ `a[6]`; số bit 1 **không** quyết định độ trễ trong mạch tổ hợp — mọi vector đều đi qua cùng một mạng cổng |
| 8 | Kết luận "mô phỏng PASS ⟹ kiến trúc đúng" | Kiểm chứng chức năng mù về cấu trúc | Một dòng `$countones` cũng PASS 256/256. Bằng chứng cấu trúc là INV-1 + bảng phân cấp |
| 9 | Đặt thanh ghi chốt kết quả **vào trong** A08 | Đổi loại mạch sang Tuần tự, vi phạm mục 10 | `synth_stat.txt` có cell `dfxtp`; `report_power` có nhóm Sequential ≠ 0 % — **đây đúng là lỗi của gói nguồn ban đầu** |
| 10 | Dùng waveform hành vi để nói về độ trễ | Waveform hành vi là zero-delay | Mở `a08_waves.vcd`: mọi tín hiệu đổi tức thời tại `#1` |
| 11 | Diễn giải "slack 8,69 ns / period 10 ns" thành "chạy được ở 100 MHz" | Khẳng định vượt mức | `vclk` là **clock ảo**, chỉ là mốc quy chiếu; A08 không có clock |
| 12 | So số cell của A08 với đề khác để kết luận "đề này khó hơn" | Hai đề có thể chạy môi trường/flow khác | `tradeoff.md` §2 — điều kiện tạo bằng chứng |
| 13 | Tin rằng cây cộng luôn nhỏ hơn chuỗi thẳng | Ngược với số đo trong flow nộp bài | §7 câu 3: 240,23 so với 201,44 µm² — cây cộng **lớn hơn** |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|---|---|---|
| 1 | Vì sao khối này có đúng 0 flip-flop? | Vì là mạch tổ hợp: `ones` chỉ là hàm của `a` hiện tại. Thanh ghi chốt nằm **ngoài** A08. Xác nhận hai nguồn: bảng cell Yosys và `report_power` (Sequential 0 %). |
| 2 | Cây cộng có mấy tầng, mỗi tầng làm gì? | 3 tầng: 4 bộ cộng 1-bit (8 bit → 4 số 0…2), 2 bộ cộng 2-bit (→ 2 số 0…4, chính là popcount nửa thấp và nửa cao), 1 bộ cộng 3-bit (→ 1 số 0…8). |
| 3 | Vì sao kết quả 4 bit chứ không 3? | Vì có 9 giá trị khả dĩ (`0…8`), 3 bit chỉ chứa 8. Công thức `⌈log₂(N+1)⌉`. Lỗi này chỉ lộ ở **1/256** vector — đó là `0xFF`. |
| 4 | Bạn nói cây sâu 3 tầng, nhưng STA cho 5 cell. Mâu thuẫn ở đâu? | Không mâu thuẫn: 3 đếm tầng **cây**, 5 đếm tầng **cổng**. Tầng 2 và 3 tự chúng là bộ cộng ripple có chuỗi carry bên trong. |
| 5 | Sao không phải 6 (= 1+2+3) mà là 5? | Vì bit thấp của mỗi tổng riêng phần ra sớm hơn bit cao một tầng, nên chuỗi carry của `add3` khởi động sớm. Chỉ thấy được khi phân tích arrival time. |
| 6 | `{c, s}` của half adder là gì? | **Một số nhị phân 2 bit** trong dải 0…2, không phải hai tín hiệu rời. Giá trị `11 = 3` không bao giờ xảy ra. |
| 7 | 256/256 PASS — điều này chứng minh mạch là cây cộng chưa? | Chưa. Kiểm chứng chức năng mù về cấu trúc. Bằng chứng cấu trúc là INV-1 (testbench đọc thẳng `l1_*`, `l2_*`) và bảng phân cấp Yosys. |
| 8 | Vector nào là ca chậm nhất? | **Câu hỏi này sai tiền đề** với mạch tổ hợp: mọi vector đi qua cùng một mạng cổng. Cái tồn tại là **đường** tới hạn (`a[6] → ones[3]`), không phải **vector** tới hạn. |
| 9 | Cây cộng nhỏ hơn chuỗi thẳng bao nhiêu? | Trong flow nộp bài nó **lớn hơn 19,3 %** (240,23 so với 201,44 µm²). Nó **nhanh hơn 25,1 %**. Nếu flatten thì đảo dấu: nhỏ hơn 27,6 %. |
| 10 | Vì sao netlist giữ phân cấp lại to hơn netlist phẳng tới 31,8 %? | Vì `abc` tối ưu từng module một; mỗi half/full adder chỉ có 2 cổng nên không còn gì để tối ưu, và nó buộc phải dùng `xor3_1` đắt (23,77 µm², chiếm 39,6 % diện tích). Flatten cho phép tái cấu trúc qua biên module. |
| 11 | Con số 1,31 ns có phải độ trễ thật của chip không? | Không. Độ trễ **sau tổng hợp**, một góc PVT, chưa có RC dây. Sau routing sẽ lớn hơn. |
| 12 | Vì sao 4 bit ra không ổn định cùng lúc? | Vì chúng ở độ sâu khác nhau: `ones[0]` @0,49 ns, `ones[3]` @1,31 ns. Giữa hai mốc đó `ones` mang giá trị không có ý nghĩa — vùng glitch. Tầng trên phải lấy mẫu sau 1,31 ns. |
| 13 | Gói nguồn ban đầu sai thế nào, và bạn phát hiện ra sao? | Nó là `a08_register` — một thanh ghi 8-bit, mạch **tuần tự**, 8 FF. Phát hiện bằng đối chiếu tên top module với Charter, và bằng con số flip-flop ≠ 0 trong bảng cell. Bản gốc đóng băng ở `08_ORIGINAL_SOURCE/`. |
| 14 | Nếu cho phép thêm ô nhớ, bạn pipeline ở đâu? | Giữa tầng 2 và tầng 3 (cắt cân nhất: 3 tầng cell mỗi chặng, +6 FF). Nhưng làm vậy là đổi loại mạch, vi phạm Charter mục 10. |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

### Đã chứng minh

1. Hàm của A08 đúng trên **toàn bộ** không gian đầu vào (256/256, 0 lỗi).
2. Ba hiện thực độc lập (Python, 2 golden model SV, RTL) đồng ý với nhau.
3. Sáu bất biến INV-1…INV-6 luôn giữ (0 vi phạm / 266 vector).
4. **Cấu trúc** đúng hình dạng Charter mục 10 — kiểm bằng INV-1 đọc thẳng net nội bộ, và
   xác nhận độc lập bằng bảng phân cấp Yosys (`4 × half_adder`, `2 × add2`, `1 × add3`).
5. **0 ô nhớ** — xác nhận bởi hai bằng chứng độc lập (bảng cell + báo cáo công suất).
6. Thiết kế **nhỏ**: 22 cell · 240,2304 µm², thấp hơn ước lượng 90–140 cell của Charter.
7. Độ sâu logic thực tế là **5 tầng cell** so với **3 tầng lý thuyết** — hai công cụ độc
   lập (Yosys `ltp`, OpenSTA) cho cùng con số.
8. Độ trễ tổ hợp **1,31 ns** so với đường nhanh nhất **0,29 ns** trên cùng netlist.
9. Cây cộng **nhanh hơn** chuỗi thẳng trong cả hai flow đã thử (25,1 % và 50,0 %).

### Chưa chứng minh

1. Netlist tương đương RTL về chức năng — cần mô phỏng gate-level.
2. Cấu trúc cây cộng còn giữ được sau khi ánh xạ cell — INV-1 mới kiểm ở mức RTL.
3. Độ trễ **thật sau routing** — 1,31 ns chưa tính ký sinh dây.
4. Biên an toàn qua các góc PVT — mới chạy `tt_025C_1v80`.
5. Công suất thật của ứng dụng — 17,5 µW dùng activity mặc định, không lấy từ VCD.
6. Lợi thế diện tích của biến thể chuỗi thẳng có còn không khi cấm nhóm cell `lpflow_*`
   (nằm trong `dont_use` của LibreLane) — chưa đo lại được.
7. Layout tuân thủ quy tắc chế tạo (DRC), khớp netlist (LVS), và có file GDSII.
8. Các báo cáo trong `06_GDSII/` hiện **vẫn là của thiết kế cũ** và phải được sinh lại.

### Ngoài phạm vi — không được khẳng định

"Đã sign-off", "đã tape-out", "đã chế tạo", "đã kiểm tra sau chế tạo", "chạy được ở XXX MHz".
Charter mục 3 loại tất cả khỏi phạm vi, cùng với đếm bit 1 trên dữ liệu rộng hơn 8 bit và
đếm bit 0 liên tiếp (CLZ).

---

*Phiên bản: v2.0 · Ngày: 2026-09-24*
*v2.0 = thiết kế lại đúng đề Charter sau sự cố lệch nguồn — xem `05_VERIFICATION/known_issues.md`.*
