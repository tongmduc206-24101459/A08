// =====================================================================
//  A08 — Bo dem so bit 1 (population count) 8-bit
//  File: a08_popcount8.sv — module dinh (top)
// ---------------------------------------------------------------------
//  De         : A08 · Nhom A — So hoc to hop
//  Loai mach  : TO HOP THUAN (khong clock, khong reset, 0 flip-flop)
//  Nguon      : Project Charter A08
//               muc 1  — dem so cam bien dang bao dong trong he 8 cam bien
//               muc 4  — ui_in[7:0] = du lieu, uo_out[3:0] = so bit 1
//               muc 8  — 0x00->0, 0xFF->8, 0x0F->4, 0xAA->4, 0x80->1
//               muc 9  — cay cong co do sau ly thuyet log2(8) = 3 tang
//               muc 10 — dau hieu lam dung: 0 o nho, nho;
//                        4 bo cong 1-bit -> 2 bo cong 2-bit -> 1 bo cong 3-bit
//  Truy vet   : REQ-A08-001 … REQ-A08-007
//
//  KIEN TRUC BAT BUOC — CAY CONG 3 TANG
//  ------------------------------------
//     tang 1: 4 bo cong 1-bit   (half adder)  : 8 bit  -> 4 so 2-bit
//     tang 2: 2 bo cong 2-bit                 : 4 so   -> 2 so 3-bit
//     tang 3: 1 bo cong 3-bit                 : 2 so   -> 1 so 4-bit
//
//  KHONG DUOC THAY BANG TOAN TU TAT.
//  Cam tuyet doi trong file nay:
//      assign ones = $countones(a);                       // <-- CAM
//      assign ones = a[0]+a[1]+a[2]+...+a[7];             // <-- CAM
//      always_comb begin ones=0; for(...) ones+=a[i]; end // <-- CAM (Charter
//                                                         //     muc 10 goi
//                                                         //     dich danh)
//  Ly do: Charter muc 2 hoi "cay cong co may tang, moi tang lam gi", muc 9
//  bat doi chieu do sau ly thuyet 3 tang voi do sau logic THUC TE. Viet tat
//  bang toan tu se xoa chinh cau truc can dem. Toan tu tat CHI duoc dung
//  trong 05_VERIFICATION/golden_model/, noi chung dong vai tro chuan so sanh
//  doc lap.
// =====================================================================

module a08_popcount8 (
    input  logic [7:0] a,     // Charter muc 4: ui_in[7:0] — 8 kenh cam bien
    output logic [3:0] ones   // Charter muc 4: uo_out[3:0] — so kenh dang bao
);

    // =================================================================
    // TANG 1 — 4 bo cong 1-bit (half adder)
    // -----------------------------------------------------------------
    // Ghep 8 bit vao thanh 4 cap roi cong tung cap. Moi bo tra ve mot so
    // KHONG DAU 2-bit trong dai 0..2:  l1_k = {carry, sum}.
    // Bon bo nay HOAN TOAN SONG SONG — khong bo nao cho bo nao.
    // =================================================================
    logic [1:0] l1_0;   // = a[0] + a[1]
    logic [1:0] l1_1;   // = a[2] + a[3]
    logic [1:0] l1_2;   // = a[4] + a[5]
    logic [1:0] l1_3;   // = a[6] + a[7]

    a08_half_adder u_l1_0 (.x(a[0]), .y(a[1]), .s(l1_0[0]), .c(l1_0[1]));
    a08_half_adder u_l1_1 (.x(a[2]), .y(a[3]), .s(l1_1[0]), .c(l1_1[1]));
    a08_half_adder u_l1_2 (.x(a[4]), .y(a[5]), .s(l1_2[0]), .c(l1_2[1]));
    a08_half_adder u_l1_3 (.x(a[6]), .y(a[7]), .s(l1_3[0]), .c(l1_3[1]));

    // =================================================================
    // TANG 2 — 2 bo cong 2-bit
    // -----------------------------------------------------------------
    // Gop doi ket qua tang 1. Moi bo cong hai so 0..2 nen ket qua nam
    // trong dai 0..4, can 3 bit. Hai bo nay cung SONG SONG voi nhau.
    // =================================================================
    logic [2:0] l2_0;   // = a[0]+a[1]+a[2]+a[3]   (nua thap)
    logic [2:0] l2_1;   // = a[4]+a[5]+a[6]+a[7]   (nua cao)

    a08_add2 u_l2_0 (.p(l1_0), .q(l1_1), .s(l2_0));
    a08_add2 u_l2_1 (.p(l1_2), .q(l1_3), .s(l2_1));

    // =================================================================
    // TANG 3 — 1 bo cong 3-bit
    // -----------------------------------------------------------------
    // Gop hai nua. Hai toan hang nam trong dai 0..4 nen tong nam trong
    // dai 0..8 — day la ly do ket qua can 4 bit chu khong phai 3 bit:
    // gia tri 8 = 4'b1000 khong bieu dien duoc bang 3 bit (chi toi 7).
    // =================================================================
    a08_add3 u_l3_0 (.p(l2_0), .q(l2_1), .s(ones));

endmodule
