# A08 · Assertion

Gói nguồn không có file assertion riêng.

Kiểm chứng hiện dựa trên assertion **tức thời** viết thẳng trong testbench (`assert(...) else $fatal(...)`), đã chạy được với Icarus Verilog.

## Bất biến nên bổ sung khi mở rộng kiểm chứng

| Bất biến | Nội dung |
|---|---|
| INV-1 | Kết quả của DUT luôn bằng kết quả của mô hình chuẩn trên mọi vector hợp lệ |
| INV-2 | Không có tín hiệu ra nào ở trạng thái `X`/`Z` sau khi reset xong |
| INV-3 | Không tồn tại phụ thuộc vào lịch sử đầu vào (mạch tổ hợp) |

*Phiên bản: v1.0 · Ngày: 2026-09-24*
