# A08 · Giản đồ thời gian (Timing Diagram)

⚠️ **Đọc trước:** A08 **không có clock**. Mọi giản đồ dưới đây là giản đồ **lan truyền tổ
hợp**, không phải giản đồ chu kỳ. Trục ngang là thời gian lan truyền thực, đo bằng ns từ
báo cáo OpenSTA (góc `tt_025C_1v80`, sau tổng hợp, **chưa** có RC dây).

---

## 1. Ca xấu nhất — đường tới hạn `a[6] → ones[3]`, 1,31 ns

Kích thích: `a[6]` đổi trạng thái, các bit còn lại giữ nguyên ở mức làm mọi carry đều phải
lan (ví dụ chuyển `0xBF → 0xFF`).

```
 t (ns)   0.00      0.17      0.36      0.62      0.98      1.31
          │         │         │         │         │         │
 a[6]  ───┼─╱‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
          │
          │ xor2_1 (u_l1_3)  0.17 ns
          ▼
 l1_3[0] ─────────╱‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
                  │
                  │ and2_0 (u_l2_1/u_ha0)  0.19 ns
                  ▼
 c0 (add2) ─────────────────╱‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
                            │
                            │ xor3_1 (u_l2_1/u_fa1)  0.26 ns
                            ▼
 l2_1[1] ────────────────────────────╲______________________
                                     │
                                     │ maj3_1 (u_l3_0/u_fa1)  0.37 ns
                                     ▼
 c1 (add3) ─────────────────────────────────────╲___________
                                                 │
                                                 │ maj3_1 (u_l3_0/u_fa2)  0.33 ns
                                                 ▼
 ones[3] ───────────────────────────────────────────────────╲__
                                                             │
                                          ỔN ĐỊNH TỪ ĐÂY ────┘  1.31 ns
```

**Phân rã độ trễ theo tầng của cây:**

| Tầng cây | Cell trên đường | Độ trễ (ns) | Tỷ lệ |
|---|---|---:|---:|
| Tầng 1 (bộ cộng 1-bit) | `xor2_1` | 0,17 | 13,0 % |
| Tầng 2 (bộ cộng 2-bit) | `and2_0` + `xor3_1` | 0,45 | 34,4 % |
| Tầng 3 (bộ cộng 3-bit) | `maj3_1` + `maj3_1` | 0,70 | **53,4 %** |
| **TỔNG** | **5 cell** | **1,31** | 100 % |

> 🔎 **Hơn một nửa độ trễ nằm ở tầng cuối.** Cây cộng cân về **số toán hạng** (8 → 4 → 2 → 1)
> nhưng **không** cân về **độ trễ**: tầng càng sâu thì toán hạng càng rộng, mà toán hạng càng
> rộng thì chuỗi carry bên trong càng dài. Tầng 1 đóng góp 1 cell, tầng 2 đóng góp 2 cell,
> tầng 3 đóng góp 2 cell. Đây là lý do định lượng cho việc "3 tầng" không có nghĩa "3 cổng".

## 2. Ca tốt nhất — đường nhanh nhất `a[7] → ones[0]`, 0,29 ns

```
 t (ns)   0.00   0.06        0.23      0.29
          │      │           │         │
 a[7]  ───┼─╱‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
          │ xor2_1 (u_l1_3)  0.06 ns
          ▼
 l1_3[0] ──────╲_________________________
               │ xor2_1 (u_l2_1/u_ha0)  0.17 ns
               ▼
 l2_1[0] ──────────────────╱‾‾‾‾‾‾‾‾‾‾‾‾‾
                           │ xor2_1 (u_l3_0/u_ha0)  0.06 ns
                           ▼
 ones[0] ─────────────────────────╲______
                                   │
                            ỔN ĐỊNH ┘  0.29 ns
```

Đường này đi qua đúng **3** cell, **cả ba đều là `xor2_1`** — nó là "xương sống bit thấp"
của cây: chỉ gồm các bit tổng, không chạm vào một mắt xích carry nào.

**Chênh lệch giữa hai đường: 1,31 ns so với 0,29 ns ≈ 4,5×**, trên cùng một netlist, cùng
thư viện, cùng góc PVT. Khác biệt duy nhất là **có đi qua chuỗi carry hay không**.

## 3. Thời điểm ổn định của từng bit đầu ra

Bốn bit của `ones` **không** ổn định cùng lúc. Số liệu từ `report_checks -path_delay max
-group_path_count 10`:

| Bit | Startpoint tới hạn | Arrival (ns) | Số cell | Nội dung đường |
|---|---|---:|---:|---|
| `ones[0]` | `a[6]` | 0,49 | 3 | chỉ các bit tổng |
| `ones[1]` | `a[2]` | 0,94 | 4 | + 1 mắt xích carry |
| `ones[2]` | `a[6]` | 1,15 | 5 | + 2 mắt xích carry |
| `ones[3]` | `a[6]` | **1,31** | 5 | + 2 mắt xích carry, cell cuối chậm hơn |

```
         0.0        0.5        1.0       1.31
          │──────────│──────────│─────────│
 ones[0]  ├──────────┤ 0.49 ns
 ones[1]  ├──────────────────┤   0.94 ns
 ones[2]  ├─────────────────────────┤     1.15 ns
 ones[3]  ├────────────────────────────┤  1.31 ns  ◀── mốc lấy mẫu phải sau đây
```

**Hệ quả cho tầng trên:** thanh ghi chốt 4-bit ở `system_diagram.md` §1 phải lấy mẫu **sau
mốc 1,31 ns** kể từ khi `a` ổn định. Lấy mẫu sớm hơn có thể bắt được `ones[0]` đúng nhưng
`ones[3]` sai — tức đọc ra một giá trị **chưa bao giờ đúng**.

## 4. Vùng glitch — vì sao `ones` đi qua giá trị sai trước khi đúng

Đây là hành vi bình thường của mạch tổ hợp, và với A08 nó rất dễ quan sát.

Ví dụ: `a` chuyển từ `0x0F` (`ones = 4`) sang `0xFF` (`ones = 8`). Bốn bit cao cùng bật.

```
 a       ╳ 0x0F ╳═══════════════ 0xFF ═══════════════════════
          │
          │  các bit của `ones` ổn định vào 4 thời điểm KHÁC NHAU
          ▼
 ones    ╳ 4 ╳ ? ╳ ? ╳ ? ╳══════════ 8 ═══════════════════════
          0  0.49 0.94 1.15 1.31
             └──── VÙNG GLITCH ────┘
             giá trị trung gian KHÔNG có ý nghĩa vật lý
```

Trong vùng này `ones` có thể mang những giá trị mà **không** tổ hợp đầu vào nào (cũ hay
mới) tạo ra. Ba điều cần nhấn mạnh:

1. **Không phải lỗi.** Không có tiêu chuẩn nào đòi các bit ra ổn định đồng thời.
2. **Không sửa được bằng RTL.** Nó là hệ quả của độ trễ cổng khác nhau trên các đường khác
   nhau. Chỉ cách ly được bằng cách lấy mẫu đúng lúc — việc của tầng trên.
3. **Mô phỏng hành vi KHÔNG thấy được.** Icarus chạy zero-delay: trong VCD `a08_waves.vcd`
   mọi tín hiệu đổi tức thời tại `#1`, vùng glitch rộng đúng 0. Muốn thấy phải mô phỏng
   gate-level có SDF — **chưa chạy**.

Với ứng dụng giám sát cảm biến, glitch còn có một hệ quả riêng: nó tạo xung nhiễu trên
`ones` có thể vượt ngưỡng báo động trong vài trăm ps. Đó là lý do chuỗi xử lý luôn có
thanh ghi chốt **và** logic chống rung ở tầng trên.

## 5. Giản đồ mô phỏng hành vi — đọc thế nào cho đúng

`05_VERIFICATION/testbench/a08_tb.sv` ghi VCD cho **10 ca có tên**, rồi `$dumpoff` trước
vòng quét 256 giá trị (nếu không, file phình to mà không đọc được bằng mắt).

```
 #1    #2    #3    #4    #5    #6    #7    #8    #9   #10
 ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
a│ 00  │ FF  │ 0F  │ AA  │ 80  │ 01  │ F0  │ 55  │ 7F  │ FE  │
 ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
o│  0  │  8  │  4  │  4  │  1  │  1  │  4  │  4  │  7  │  7  │
 └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
   TC-001 … TC-010     (`o` = ones[3:0])
```

> ⚠️ **Giản đồ này KHÔNG phải bằng chứng về thời gian.** Mọi cạnh trong đó trùng nhau tuyệt
> đối vì mô phỏng hành vi là zero-delay. Bằng chứng thời gian duy nhất của hồ sơ là **báo
> cáo OpenSTA** (§1–§3). Dùng waveform hành vi để nói về độ trễ là một trong những lỗi
> Charter cảnh báo — xem `implementation-notes_A08.md` §9.

## 6. Giới hạn của các con số thời gian ở đây

| Con số | Là gì | **Không** là gì |
|---|---|---|
| 1,31 ns | Độ trễ tới hạn **sau tổng hợp**, góc `tt_025C_1v80` | Độ trễ sau routing (sẽ **lớn hơn**, chưa có RC dây) |
| 0,29 ns | Đường nhanh nhất trên cùng netlist | Không dùng để suy ra tần số |
| slack 8,69 ns | Slack so với **clock ảo** `vclk` chu kỳ 10 ns | **Không** có nghĩa "chạy được ở 100 MHz". `vclk` chỉ là mốc quy chiếu để STA tính được số; A08 không có clock. |
| WNS 0,00 / TNS 0,00 | Không đường nào vi phạm mốc quy chiếu | Không phải kết quả sign-off |

---

*Phiên bản: v2.0 · Ngày: 2026-09-24.*
