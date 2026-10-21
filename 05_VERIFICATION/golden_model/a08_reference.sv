// =====================================================================
//  A08 - MO HINH CHUAN (golden model) cho bo dem so bit 1 8-bit
//  File: a08_reference.sv
// ---------------------------------------------------------------------
//  De        : A08 . Nhom A - So hoc to hop
//  Vai tro   : CHUAN SO SANH DOC LAP voi RTL o 04_IMPLEMENTATION/rtl/.
//  Loai mach : TO HOP THUAN (khong clock, khong reset)
//
//  VI SAO FILE NAY DUOC PHEP DUNG TOAN TU TAT
//  ------------------------------------------
//  RTL nop bai BI CAM viet `$countones(a)` va cam cong gop mot dong, vi
//  Charter muc 2 hoi "cay cong co may tang, moi tang lam gi" va muc 9
//  bat doi chieu do sau ly thuyet 3 tang voi do sau logic THUC TE. Neu
//  viet tat thi cong cu tong hop tu chon kien truc va thu can dem bien mat.
//
//  Nhung mot CHUAN SO SANH thi nguoc lai: no chi co gia tri khi duoc NGHI
//  THEO CACH KHAC voi RTL. Vi vay o day khong co tang nao, khong co half
//  adder nao, khong co carry nao.
//
//  KHONG duoc chep bat ky dong nao tu RTL sang day, va nguoc lai.
//
//  HAI MO HINH, HAI CACH NGHI
//  --------------------------
//    a08_reference      - dung ham he thong $countones cua ngon ngu
//    a08_reference_sum  - cong don tung bit trong mot vong lap
//  Hai cach nay doc lap nhau; neu ca hai cung sai thi phai sai theo cung
//  mot cach, dieu rat kho xay ra.
// =====================================================================

// ---------------------------------------------------------------------
//  a08_reference - dung $countones
// ---------------------------------------------------------------------
//  Day la cach nghi cua nguoi viet DAC TA: "dem xem co bao nhieu bit 1",
//  khong quan tam dem BANG CACH NAO. Khong he co khai niem tang, cap bit,
//  hay carry o day.
// ---------------------------------------------------------------------
module a08_reference (
    input  logic [7:0] a,
    output logic [3:0] ones
);

    // Ket qua nam trong dai 0..8 nen can DU 4 bit: gia tri 8 = 4'b1000
    // khong bieu dien duoc bang 3 bit (chi toi 7).
    assign ones = $countones(a);

endmodule


// ---------------------------------------------------------------------
//  a08_reference_sum - cong don tung bit
// ---------------------------------------------------------------------
//  Cach nghi thu hai: duyet tuan tu tu bit 0 den bit 7 va cong don. Day
//  la mo hinh "phan mem" cua phep dem - hoan toan NOI TIEP ve mat khai
//  niem, tuc doi cuc voi cay cong SONG SONG cua RTL.
//
//  Viet duoi dang HAM roi noi bang 'assign' lien tuc: ham khong phai qua
//  trinh always_* nen Icarus suy dien du do nhay va bien dich sach.
// ---------------------------------------------------------------------
module a08_reference_sum (
    input  logic [7:0] a,
    output logic [3:0] ones
);

    function [3:0] count_by_loop;
        input [7:0] v;
        integer i;
        integer acc;
        begin
            acc = 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (v[i] === 1'b1) acc = acc + 1;
            end
            count_by_loop = acc[3:0];
        end
    endfunction

    assign ones = count_by_loop(a);

endmodule
