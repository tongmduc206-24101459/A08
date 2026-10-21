# A08 · Ca biên và ca góc (Corner Cases)

Tài liệu này giải thích **vì sao** từng ca được chọn. Danh sách thực thi nằm ở
`05_VERIFICATION/test_matrix.csv`; kết quả nằm ở `05_VERIFICATION/verification_report.md`.

Đặc thù của A08: không gian đầu vào chỉ có **256** giá trị, nên quét vét cạn bao phủ **toàn
bộ**. Vì vậy vai trò của các ca có tên **không phải** để tăng độ phủ hành vi — vét cạn đã
phủ hết — mà để:

1. **chứng minh từng cơ chế riêng** của cây cộng (tầng nào làm gì), và
2. **để lại vết đọc được** trong log và waveform khi bảo vệ.

---

## 1. Năm ca bắt buộc theo Charter mục 8

| TC | `A` | nhị phân | `ones` | Vì sao là ca biên / ca góc |
|---|---:|---|---:|---|
| TC-001 | `0x00` | `00000000` | 0 | **Biên dưới tuyệt đối.** Mọi half adder ở tầng 1 đều ra `00`, mọi carry đều `0`. Bắt lỗi carry bị kẹt ở mức 1 hoặc bit ra bị nối lên `VDD`. |
| TC-002 | `0xFF` | `11111111` | 8 | **Biên trên tuyệt đối, và là ca duy nhất trong 256 giá trị làm `ones[3] = 1`.** Nếu ai đó cắt kết quả còn 3 bit, **chỉ** ca này lộ ra — xem `functional_spec.md` §1. Cũng là ca duy nhất mà cả 4 half adder tầng 1 đều sinh carry. |
| TC-003 | `0x0F` | `00001111` | 4 | **Ca tách nửa.** Nửa thấp đầy, nửa cao rỗng ⟹ `l2_0 = 4`, `l2_1 = 0`. Kiểm tầng 3 cộng đúng khi một toán hạng đạt giá trị lớn nhất `4 = 3'b100`, tức bit trọng số 4 của toán hạng đang bật. |
| TC-004 | `0xAA` | `10101010` | 4 | **Ca xen kẽ.** Bốn bit 1 rải đều, mỗi half adder tầng 1 nhận đúng một bit 1 ⟹ **không** half adder nào sinh carry, cả 4 đều ra `01`. Đường đi qua cây hoàn toàn khác TC-003 nhưng kết quả y hệt. |
| TC-005 | `0x80` | `10000000` | 1 | **Ca một bit, ở vị trí xa nhất.** Bit 7 phải đi hết chiều dài cây (tầng 1 → 2 → 3) mới tới được `ones[0]`. Bắt lỗi nối lệch chỉ số giữa các tầng. |

## 2. Năm ca tự xây dựng

| TC | `A` | nhị phân | `ones` | Loại | Vì sao thêm ca này |
|---|---:|---|---:|---|---|
| TC-006 | `0x01` | `00000001` | 1 | **Ca biên** | Đối xứng với TC-005 ở đầu kia. Cặp TC-005/TC-006 chứng minh kết quả **không** phụ thuộc vị trí bit: cùng `ones = 1` cho bit ở hai đầu. |
| TC-007 | `0xF0` | `11110000` | 4 | Đối ngẫu TC-003 | Nửa cao đầy, nửa thấp rỗng ⟹ `l2_0 = 0`, `l2_1 = 4`. Bắt lỗi **hoán vị toán hạng** ở tầng 3 và lỗi đảo nửa cao / nửa thấp ở tầng 2. |
| TC-008 | `0x55` | `01010101` | 4 | Đối ngẫu TC-004 | Bù bit của `0xAA`. Cặp TC-004/TC-008 là kiểm trực tiếp INV-3 (`ones(A) + ones(~A) = 8`) trên một cặp cụ thể. |
| TC-009 | `0x7F` | `01111111` | 7 | **Ca biên** | `ones = 7 = 4'b0111` — giá trị lớn nhất **vẫn vừa 3 bit**. Đặt ngay sát TC-002 (`ones = 8`, cần 4 bit). Cặp TC-009/TC-002 là **cặp phản chứng cho câu hỏi "3 bit hay 4 bit"**: nếu cắt còn 3 bit thì TC-009 vẫn đúng còn TC-002 sai. |
| TC-010 | `0xFE` | `11111110` | 7 | **Ca biên** | Cũng `ones = 7` nhưng bit 0 bị tắt thay vì bit 7. Bắt lỗi mượn giá trị của một tầng cụ thể để "sửa" kết quả cho khớp TC-009. |

## 3. Phân loại theo tiêu chí kỹ thuật của đề

### 3.1 Theo hoạt động của tầng 1 — số half adder **sinh carry**

Một half adder tầng 1 sinh carry khi **cả hai** bit vào cùng bằng 1. Đại lượng này quyết
định giá trị các `l1_k` và do đó quyết định cây cộng phải làm việc nặng đến đâu.

| TC | `A` | `l1_3 l1_2 l1_1 l1_0` (mỗi ô 0..2) | Số HA sinh carry | Ghi chú |
|---|---:|---|---:|---|
| TC-001 | `0x00` | `0 0 0 0` | **0** | Toàn bộ cây nghỉ |
| TC-005 | `0x80` | `1 0 0 0` | **0** | Một bit đơn độc |
| TC-006 | `0x01` | `0 0 0 1` | **0** | Một bit đơn độc, đầu kia |
| TC-004 | `0xAA` | `1 1 1 1` | **0** | ⚠️ Bốn bit 1 mà **không** carry nào sinh ra |
| TC-008 | `0x55` | `1 1 1 1` | **0** | Như trên, mẫu bù |
| TC-003 | `0x0F` | `0 0 2 2` | **2** | Hai HA nửa thấp cùng sinh carry |
| TC-007 | `0xF0` | `2 2 0 0` | **2** | Hai HA nửa cao cùng sinh carry |
| TC-009 | `0x7F` | `1 2 2 2` | **3** | |
| TC-010 | `0xFE` | `2 2 2 1` | **3** | |
| **TC-002** | `0xFF` | `2 2 2 2` | **4** | **Cả 4 HA cùng sinh carry — ca nặng nhất của tầng 1** |

> 🔎 **Bài học từ TC-004 so với TC-003.** Hai ca cho cùng `ones = 4`, nhưng bên trong cây
> chúng khác hẳn: `0xAA` không sinh carry nào ở tầng 1 (bốn `l1_k` đều bằng 1), còn `0x0F`
> sinh hai carry và đẩy hai `l1_k` lên giá trị 2. "Cùng kết quả" **không** có nghĩa "cùng
> đường đi trong mạch". Đây chính là lý do Charter đưa cả hai vào nhóm bắt buộc.

### 3.2 Theo độ phủ giá trị đầu ra

| `ones` | Có ca có tên? | TC |
|---:|---|---|
| 0 | ✅ | TC-001 |
| 1 | ✅ | TC-005, TC-006 |
| 2 | — | phủ bởi quét vét cạn (28 giá trị) |
| 3 | — | phủ bởi quét vét cạn (56 giá trị) |
| 4 | ✅ | TC-003, TC-004, TC-007, TC-008 |
| 5 | — | phủ bởi quét vét cạn (56 giá trị) |
| 6 | — | phủ bởi quét vét cạn (28 giá trị) |
| 7 | ✅ | TC-009, TC-010 |
| 8 | ✅ | TC-002 |

Phân bố `1, 8, 28, 56, 70, 56, 28, 8, 1` đã được testbench kiểm là khớp hệ số nhị thức
`C(8,k)` — đó là INV-5, và nó **chỉ kiểm được sau khi quét hết** 256 giá trị.

### 3.3 Ca **không** áp dụng cho A08

| Loại ca | Lý do không áp dụng |
|---|---|
| Reset assert / deassert | A08 không có reset |
| Clock gating, clock domain crossing | A08 không có clock |
| Giá trị khởi tạo của ô nhớ, X-propagation lúc power-up | A08 có **0 ô nhớ** |
| Back-to-back transaction, giao thức handshake | A08 không có giao thức |
| Tràn / bão hoà kết quả | **Không tồn tại**: 4 bit đủ chứa mọi giá trị `0…8` |
| Đầu vào không hợp lệ | **Không tồn tại**: cả 256 giá trị đều hợp lệ |

Bảng này quan trọng vì gói nguồn ban đầu là một **thanh ghi**, và bộ ca kiểm thử cũ tập
trung đúng vào những mục vừa bị gạch đi (reset, enable, giữ giá trị qua chu kỳ). Xem
`05_VERIFICATION/known_issues.md`.

## 4. Quét vét cạn — vì sao đây là ca mạnh nhất

Không gian đầu vào là `2⁸ = 256` tổ hợp. Testbench so khớp DUT với **hai** mô hình chuẩn
SystemVerilog trên **toàn bộ** không gian này, đồng thời kiểm INV-1…INV-6 trên từng vector.

Kết quả thật: **266 vector, 0 lỗi** (10 ca có tên + 256 vét cạn).

Hệ quả:

> Nếu 256/256 giá trị đều khớp, DUT **tương đương hàm** với mô hình chuẩn.
> Không còn ca nào khác để tìm ở mức hành vi.

Điều này **vẫn không** chứng minh:

- kiến trúc bên trong là cây cộng 3 tầng — bằng chứng đó đến từ **INV-1** (testbench đọc
  thẳng các net `l1_*`, `l2_*` của DUT) và từ bảng phân cấp Yosys;
- thời gian lan truyền đạt yêu cầu — cần STA;
- netlist sau tổng hợp tương đương RTL — cần mô phỏng gate-level;
- mạch còn đúng sau place & route — cần mô phỏng có back-annotate SDF.

## 5. Ca cần bổ sung khi chuyển sang gate-level / post-layout

| Ca | Vì sao cần cho **riêng** đề này | Trạng thái |
|---|---|---|
| Mô phỏng gate-level trên netlist sau tổng hợp | Netlist giữ phân cấp nên còn đọc được `l1_*`, `l2_*`; mô phỏng gate-level là cách kiểm INV-1 **sau** khi công cụ đã ánh xạ cell | ⬜ chưa chạy |
| Vector kích hoạt đường tới hạn: `a[6]` đổi trạng thái khi các bit còn lại giữ nguyên | STA chỉ ra đường tới hạn xuất phát từ `a[6]` (xem `03_ARCHITECTURE/datapath.md` §4) — cần vector thật để đo bằng mô phỏng | ⬜ chưa chạy |
| Đếm glitch trên `ones[3:0]` khi đầu vào đổi từ `0x00` sang `0xFF` | Đây là chuyển tiếp làm **mọi** tầng cùng đổi trạng thái; dùng cho phân tích công suất động dựa trên VCD thật thay vì activity mặc định | ⬜ chưa chạy |
| Mô phỏng có back-annotate SDF sau P&R | Độ trễ thật có RC dây | ⬜ chưa chạy |

---

*Phiên bản: v2.0 · Ngày: 2026-09-24 · Truy vết: REQ-A08-020, REQ-A08-021.*
