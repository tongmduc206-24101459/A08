# A08 · Đánh đổi kiến trúc (Trade-off)

Tài liệu này so kiến trúc đã chọn — **cây cộng 3 tầng** — với các kiến trúc thay thế, **bằng
số liệu thật đo trên cùng một chuỗi công cụ**, không phải bằng nhận định chung chung.

---

## 1. Bốn kiến trúc hiện thực popcount 8-bit

| # | Kiến trúc | Ý tưởng | Trạng thái trong hồ sơ này |
|---|---|---|---|
| **A** | **Cây cộng 3 tầng** | Gộp đôi: 8 → 4 → 2 → 1 | ✅ **ĐÃ CHỌN, đã tổng hợp, đã STA** |
| B | Cộng tuần tự từng bit (chuỗi thẳng) | Cộng dồn từng bit vào một bộ tích luỹ, trải thành 7 bộ cộng nối tiếp trong không gian | ✅ **đã dựng và đo** (biến thể chỉ để so sánh) |
| C | Tra bảng ROM 256 × 4 bit | Nhớ sẵn kết quả cho cả 256 giá trị | ⬜ chỉ phân tích trên giấy |
| D | Máy trạng thái tuần tự theo thời gian | Dùng lại 1 bộ cộng qua 8 chu kỳ | ⬜ chỉ phân tích trên giấy — **ngoài phạm vi** (đổi loại mạch) |

Charter mục 10 **chỉ định** kiến trúc A. Ba kiến trúc còn lại có mặt ở đây để trả lời câu
hỏi "vì sao A" bằng bằng chứng chứ không bằng lời.

## 2. Điều kiện đo — để mọi con số so sánh được với nhau

| Mục | Giá trị |
|---|---|
| Tổng hợp | Yosys 0.33 (git sha1 2584903a) |
| Thư viện | `sky130_fd_sc_hd`, góc `tt_025C_1v80` |
| Script | `proc; opt; fsm; opt; memory; opt; techmap; opt; dfflibmap; abc -liberty; setundef -zero; splitnets; opt_clean -purge` |
| STA | OpenSTA, clock ảo `vclk` chu kỳ 10 ns, input/output delay 0 ns |
| Công suất | `report_power` với activity mặc định (**không** lấy từ VCD) |

Kiến trúc A và B chạy **cùng một script, cùng một thư viện, cùng một góc**. Khác biệt duy
nhất là mã RTL.

## 3. Kết quả so sánh A ↔ B — số liệu thật

### 3.1 Flow nộp bài (giữ phân cấp module)

| Chỉ số | **A · Cây cộng** | **B · Cộng tuần tự từng bit** | Chênh |
|---|---:|---:|---|
| Số cell | **22** | 30 | B nhiều hơn **+36,4 %** |
| Diện tích | 240,2304 µm² | **201,4432 µm²** | B nhỏ hơn **−16,1 %** ⚠️ |
| Flip-flop | **0** | **0** | bằng nhau |
| Đường tới hạn | **1,31 ns** | 1,75 ns | B chậm hơn **+33,6 %** |
| Số cell trên đường tới hạn | **5** | 12 | B dài hơn **2,4×** |
| Công suất | **17,5 µW** | 23,2 µW | B tốn hơn **+32,6 %** |

### 3.2 Cùng flow, thêm một bước `flatten`

| Chỉ số | **A · Cây cộng** | **B · Cộng tuần tự từng bit** | Chênh |
|---|---:|---:|---|
| Số cell | **20** | 26 | B nhiều hơn **+30,0 %** |
| Diện tích | **163,9072 µm²** | 226,4672 µm² | B lớn hơn **+38,2 %** |
| Đường tới hạn | **0,76 ns** | 1,52 ns | B chậm hơn **2,0×** |

### 3.3 Trả lời Charter mục 2 câu 3 — "chênh bao nhiêu?"

> ❗ **Câu trả lời trung thực là: dấu của chênh lệch diện tích PHỤ THUỘC VÀO FLOW.**
>
> - Giữ phân cấp: cây cộng **lớn hơn 19,3 %** về diện tích (240,23 so với 201,44 µm²).
> - Có `flatten`: cây cộng **nhỏ hơn 27,6 %** về diện tích (163,91 so với 226,47 µm²).
>
> **Về tốc độ thì không đổi dấu:** cây cộng nhanh hơn trong **cả hai** flow (nhanh hơn
> 25,1 % khi giữ phân cấp, nhanh hơn 50,0 % khi flatten).

Đây là kết quả đáng giá nhất của phép đo này, và nó phản trực giác. Nguyên nhân ở §5.

Nếu phải đưa **một** con số cho câu hỏi của Charter, con số nên dùng là của flow nộp bài
(giữ phân cấp, tức chính netlist trong hồ sơ): **cây cộng nhanh hơn 25,1 % và tốn thêm
19,3 % diện tích so với cộng tuần tự từng bit** — tức đây là một phép đánh đổi diện tích
lấy tốc độ, không phải một chiến thắng toàn diện.

### 3.4 Mã RTL của biến thể B — để tái lập phép đo

Biến thể B **không** nằm trong `04_IMPLEMENTATION/rtl/` vì nó không phải bài nộp. Chép
đoạn dưới vào một file `.sv` rồi chạy đúng script ở §2 là tái lập được toàn bộ số liệu:

```systemverilog
// Bien the CHI DE DO — khong nop bai.
// "Cong tuan tu tung bit": acc <- acc + a[k], lap 7 lan, moi lan mot chuoi half-adder.
module a08x_addbit #(parameter int IN_W = 2, parameter int OUT_W = 3) (
    input  logic [IN_W-1:0]  acc,
    input  logic             bit_in,
    output logic [OUT_W-1:0] sum
);
    logic [IN_W:0]   c;
    logic [IN_W-1:0] s;
    assign c[0] = bit_in;
    genvar i;
    generate
        for (i = 0; i < IN_W; i = i + 1) begin : G_HA
            assign s[i]   = acc[i] ^ c[i];
            assign c[i+1] = acc[i] & c[i];
        end
        if (OUT_W == IN_W + 1) assign sum = {c[IN_W], s};
        else                   assign sum = s;
    endgenerate
endmodule

module a08x_popcount8_serial (input logic [7:0] a, output logic [3:0] ones);
    logic [1:0] acc1, acc2;
    logic [2:0] acc3, acc4, acc5, acc6;
    a08x_addbit #(1,2) u1 (.acc(a[0]), .bit_in(a[1]), .sum(acc1));
    a08x_addbit #(2,2) u2 (.acc(acc1), .bit_in(a[2]), .sum(acc2));
    a08x_addbit #(2,3) u3 (.acc(acc2), .bit_in(a[3]), .sum(acc3));
    a08x_addbit #(3,3) u4 (.acc(acc3), .bit_in(a[4]), .sum(acc4));
    a08x_addbit #(3,3) u5 (.acc(acc4), .bit_in(a[5]), .sum(acc5));
    a08x_addbit #(3,3) u6 (.acc(acc5), .bit_in(a[6]), .sum(acc6));
    a08x_addbit #(3,4) u7 (.acc(acc6), .bit_in(a[7]), .sum(ones));
endmodule
```

Mỗi tầng được **cắt độ rộng tối thiểu** theo giá trị lớn nhất có thể (`acc2` chỉ cần 2 bit
vì tối đa là 3), nên đây là một hiện thực chuỗi thẳng đã được tối ưu bằng tay — nói cách
khác, so sánh ở §3 **không** thiên vị kiến trúc A.

## 4. Vì sao cây cộng vẫn là lựa chọn đúng cho đề này

Ba lý do, xếp theo sức nặng:

1. **Charter chốt.** Mục 10 ghi thẳng hình dạng: *"Cây cộng 3 tầng: 4 bộ cộng 1-bit → 2 bộ
   cộng 2-bit → 1 bộ cộng 3-bit."* Mục 2 và mục 9 đều đặt câu hỏi **về cây cộng**. Làm khác
   là trả lời một đề khác.
2. **Tốc độ hơn ở mọi flow.** Đây là chỉ số duy nhất không đổi dấu: 1,31 ns so với 1,75 ns
   (giữ phân cấp), 0,76 ns so với 1,52 ns (flatten). Độ sâu logic `O(log N)` so với `O(N)` là
   tính chất **cấu trúc**, không phụ thuộc công cụ.
3. **Mở rộng tốt hơn.** Với `N` bit: cây cộng có độ sâu `O(log N)`, chuỗi thẳng có `O(N)`.
   Ở `N = 8` chênh lệch còn nhỏ (3 so với 7 tầng khái niệm); ở `N = 32` thì là 5 so với 31.
   *(Charter mục 3 xếp popcount trên dữ liệu rộng hơn 8 bit vào **ngoài phạm vi**, nên đây
   chỉ là lập luận, không có số đo kèm theo.)*

Và một điểm **không** nên dùng làm lý do: "cây cộng nhỏ hơn". Số liệu §3.1 nói ngược lại
trong flow nộp bài.

## 5. Vì sao diện tích đổi dấu khi flatten — phân tích nguyên nhân

Đây là phát hiện kỹ thuật trung tâm của đề này.

**Bước 1 — netlist giữ phân cấp ánh xạ 1 : 1 với RTL.**
Thiết kế có 7 half adder và 4 full adder. Netlist có đúng 7 `xor2_1` + 7 `and2_0` +
4 `xor3_1` + 4 `maj3_1` = 22 cell. Không một cổng nào bị gộp. Lý do: `abc` tối ưu **từng
module một**, và mỗi module chỉ có 2 cổng — không còn gì để tối ưu.

**Bước 2 — thủ phạm diện tích là cell `xor3_1`.**

| Cell | Số lượng | Đơn giá (µm²) | Thành tiền (µm²) | Tỷ lệ diện tích |
|---|---:|---:|---:|---:|
| `xor3_1` | 4 | **23,7728** | **95,0912** | **39,6 %** |
| `xor2_1` | 7 | 8,7584 | 61,3088 | 25,5 % |
| `and2_0` | 7 | 6,2560 | 43,7920 | 18,2 % |
| `maj3_1` | 4 | 10,0096 | 40,0384 | 16,7 % |
| **TỔNG** | **22** | | **240,2304** | 100 % |

Một `xor3_1` đắt hơn **2,7×** một `xor2_1`, và gần bằng cả `xor2_1 + and2_0 + maj3_1` cộng
lại (23,77 so với 25,02 µm²) — tức **một** cổng XOR ba ngõ tốn xấp xỉ bằng **ba** cổng khác
gộp lại. Bốn cell `xor3_1` — chỉ 18 % số cell — chiếm gần **40 %** diện tích.

**Bước 3 — flatten cho `abc` quyền phá vỡ biên module.**
Khi phẳng, `abc` nhìn thấy cả 22 cổng cùng lúc, tái cấu trúc qua biên module và thay phần
lớn `xor3_1` bằng tổ hợp cổng rẻ hơn. Kết quả: **20 cell, 163,9072 µm² — giảm 31,8 % diện
tích và giảm 42,0 % độ trễ** (1,31 → 0,76 ns) so với chính nó khi giữ phân cấp.

Netlist phẳng dùng bảng cell hoàn toàn khác: `a21oi_1`, `a22o_1`, `a22oi_1`, `a31oi_1`,
`nand2_1`, `nand4_1 ×2`, `nor2_1`, `o21ai_0`, `o2bb2ai_1`, `xnor2_1 ×2`, `xor2_1 ×6`,
`xor3_1 ×1` — chỉ còn **một** `xor3_1` thay vì bốn.

**Bước 4 — vì sao biến thể B **không** hưởng lợi tương tự.**
Module `a08x_addbit` của B đã to sẵn (3–6 cổng), nên `abc` đã tối ưu được ngay cả khi giữ
phân cấp; flatten không còn dư địa và thậm chí làm B **to ra** (201,44 → 226,47 µm²).

> 🔎 **Kết luận rút ra.** Với những khối rất nhỏ, **cách chia module ảnh hưởng tới diện tích
> mạnh hơn cả việc chọn kiến trúc.** Chia nhỏ để netlist đọc được (yêu cầu của Charter mục
> 10) phải **trả giá bằng diện tích** — ở đây là 31,8 %. Đây là một đánh đổi có thật giữa
> *khả năng giải thích* và *hiệu quả*, và hồ sơ này chọn phía **giải thích được**, đúng như
> đề bài yêu cầu.
>
> ⚠️ Một caveat phải nêu: biến thể B dùng **5 cell `lpflow_isobufsrc_1`**, vốn nằm trong
> danh sách `dont_use` của cấu hình LibreLane/OpenLane sky130 mặc định. Nếu cấm nhóm cell
> đó, lợi thế diện tích của B ở §3.1 sẽ giảm hoặc biến mất. Chưa đo lại được vì Yosys 0.33
> không có tuỳ chọn `dont_use` cho `abc`. **Con số §3.1 phải đọc kèm caveat này.**

## 6. Kiến trúc C — tra bảng ROM 256 × 4 bit

| Tiêu chí | Đánh giá |
|---|---|
| Độ trễ | Rất thấp — một lần truy cập bảng |
| Diện tích | 1 024 bit nhớ. Nếu tổng hợp thành logic thì `abc` sẽ tối thiểu hoá về... đúng một mạng cổng tương đương cây cộng. Nếu dùng macro nhớ thật thì đắt hơn 22 cell rất nhiều. |
| Mở rộng | **Rất tệ** — `N` bit cần `2^N` mục. `N = 16` đã là 65 536 mục. |
| Phù hợp Charter? | ❌ Xoá mất toàn bộ câu hỏi mục 2 và mục 9 (không còn "tầng" nào để đếm) |

**Không đo.** Lý do không đo được ghi rõ ở đây thay vì bịa số: một hiện thực ROM trung thực
cần macro nhớ của PDK, mà việc dùng macro nằm ngoài chuỗi công cụ của hồ sơ này.

## 7. Kiến trúc D — máy trạng thái tuần tự theo thời gian

| Tiêu chí | Đánh giá |
|---|---|
| Ô nhớ | ≈ 15 FF (ước lượng trên giấy: 3 đếm bước + 8 thanh ghi dịch + 4 tích luỹ) |
| Độ trễ | 8 chu kỳ clock thay vì 1,31 ns |
| Diện tích logic cộng | Chỉ 1 bộ cộng 4-bit — rẻ hơn 11 bộ cộng 1-bit của A |
| Phù hợp Charter? | ❌ **Ngoài phạm vi.** Đổi loại mạch từ Tổ hợp sang Tuần tự, phá vỡ dấu hiệu "0 ô nhớ" của mục 10 |

**Không đo**, và đây chính là kiến trúc mà gói nguồn ban đầu vô tình lạc vào (một thanh ghi
8-bit, 8 FF, 270,2592 µm²). Xem `05_VERIFICATION/known_issues.md`.

Lưu ý phân biệt thuật ngữ: kiến trúc **B** ("cộng tuần tự từng bit") vẫn là mạch **tổ hợp** —
"tuần tự" ở đó chỉ sự nối tiếp trong **không gian**. Kiến trúc **D** mới là tuần tự theo
**thời gian**. Nhầm hai khái niệm này là lỗi thường gặp; xem `fsm.md` §5.

## 8. Bảng tổng kết đánh đổi

| | A · Cây cộng | B · Chuỗi thẳng | C · ROM | D · FSM tuần tự |
|---|---|---|---|---|
| Độ sâu logic | `O(log N)` — **đo: 5 tầng cell** | `O(N)` — **đo: 12 tầng cell** | `O(1)` | `O(N)` chu kỳ |
| Diện tích (giữ phân cấp) | **đo: 240,23 µm²** | **đo: 201,44 µm²** | lớn (macro nhớ) | nhỏ + 15 FF |
| Diện tích (flatten) | **đo: 163,91 µm²** | **đo: 226,47 µm²** | — | — |
| Flip-flop | **đo: 0** ✅ | **đo: 0** | 0 | ≈ 15 ❌ |
| Mở rộng theo `N` | tốt | kém | **rất kém** | tốt về diện tích |
| Charter cho phép? | ✅ **bắt buộc** | ⚠️ khác đề | ⚠️ khác đề | ❌ sai loại mạch |

---

*Phiên bản: v2.0 · Ngày: 2026-09-24.*
