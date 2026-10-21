// =====================================================================
//  A08 — Bo dem so bit 1 (population count) 8-bit
//  File: a08_adders.sv — thu vien bo cong so hoc dung cho cay cong
// ---------------------------------------------------------------------
//  De         : A08 · Nhom A — So hoc to hop
//  Loai mach  : TO HOP THUAN (khong clock, khong reset, 0 flip-flop)
//  Nguon      : Project Charter A08, muc 4 (giao dien), muc 9 (phan tich),
//               muc 10 (dau hieu lam dung: cay cong 3 tang)
//
//  KIEN TRUC BAT BUOC
//  ------------------
//  Charter muc 10 chot ro hinh dang cay cong:
//      4 bo cong 1-bit -> 2 bo cong 2-bit -> 1 bo cong 3-bit
//  File nay dinh nghia dung nhung vien gach do, o muc CONG LOGIC tuong minh.
//
//  KHONG DUOC THAY BANG TOAN TU TAT.
//  Cam viet `$countones(a)`, cam viet `a[0]+a[1]+...` gop mot dong, cam
//  viet `p + q` o muc toan tu trong cac module duoi day. Toan tu tat cho
//  phep cong cu tu chon kien truc, lam mat dung thu Charter muc 2 va muc 9
//  yeu cau quan sat (so tang cay cong, do sau logic thuc te).
//  Toan tu tat CHI duoc dung trong 05_VERIFICATION/golden_model/.
// =====================================================================

// ---------------------------------------------------------------------
// Bo cong 1-bit KHONG co carry vao — half adder.
// Day chinh la "bo cong 1-bit" cua tang 1 trong Charter muc 10:
// no cong hai bit du lieu va tra ve mot so 2-bit {c, s} trong dai 0..2.
// ---------------------------------------------------------------------
module a08_half_adder (
    input  logic x,   // bit vao thu nhat
    input  logic y,   // bit vao thu hai
    output logic s,   // bit tong  (trong so 1)
    output logic c    // bit nho   (trong so 2)
);
    assign s = x ^ y;   // 1 tang XOR
    assign c = x & y;   // 1 tang AND — song song voi XOR, khong noi tiep
endmodule


// ---------------------------------------------------------------------
// Bo cong 1-bit CO carry vao — full adder.
// Vien gach cua cac bo cong nhieu bit o tang 2 va tang 3.
// cout la ham da so (majority) cua ba bit vao.
// ---------------------------------------------------------------------
module a08_full_adder (
    input  logic x,     // bit vao thu nhat
    input  logic y,     // bit vao thu hai
    input  logic cin,   // bit nho tu vi tri thap hon
    output logic s,     // bit tong
    output logic cout   // bit nho ra
);
    assign s    = x ^ y ^ cin;
    assign cout = (x & y) | (x & cin) | (y & cin);
endmodule


// ---------------------------------------------------------------------
// Bo cong 2-bit: p[1:0] + q[1:0] -> s[2:0].  Tang 2 cua cay cong.
// Dung 1 half adder (vi tri 0, khong co carry vao) + 1 full adder
// (vi tri 1), noi tiep carry. Khong mo rong dau: hai toan hang la so
// khong dau trong dai 0..2 nen tong nam trong dai 0..4, vua 3 bit.
// ---------------------------------------------------------------------
module a08_add2 (
    input  logic [1:0] p,
    input  logic [1:0] q,
    output logic [2:0] s
);
    logic c0;   // carry tu vi tri 0 sang vi tri 1
    logic c1;   // carry ra cua vi tri 1 — chinh la bit trong so 4

    a08_half_adder u_ha0 (.x(p[0]), .y(q[0]), .s(s[0]), .c(c0));
    a08_full_adder u_fa1 (.x(p[1]), .y(q[1]), .cin(c0), .s(s[1]), .cout(c1));

    assign s[2] = c1;   // chi la day noi, khong ton cong nao
endmodule


// ---------------------------------------------------------------------
// Bo cong 3-bit: p[2:0] + q[2:0] -> s[3:0].  Tang 3 cua cay cong.
// Dung 1 half adder + 2 full adder, noi tiep carry.
// Hai toan hang nam trong dai 0..4 nen tong nam trong dai 0..8, vua 4 bit.
// ---------------------------------------------------------------------
module a08_add3 (
    input  logic [2:0] p,
    input  logic [2:0] q,
    output logic [3:0] s
);
    logic c0;   // carry vi tri 0 -> 1
    logic c1;   // carry vi tri 1 -> 2
    logic c2;   // carry ra cua vi tri 2 — chinh la bit trong so 8

    a08_half_adder u_ha0 (.x(p[0]), .y(q[0]), .s(s[0]), .c(c0));
    a08_full_adder u_fa1 (.x(p[1]), .y(q[1]), .cin(c0), .s(s[1]), .cout(c1));
    a08_full_adder u_fa2 (.x(p[2]), .y(q[2]), .cin(c1), .s(s[2]), .cout(c2));

    assign s[3] = c2;   // chi la day noi, khong ton cong nao
endmodule
