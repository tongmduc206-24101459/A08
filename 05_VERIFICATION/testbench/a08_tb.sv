// =====================================================================
//  A08 - TESTBENCH TU KIEM cho bo dem so bit 1 (population count) 8-bit
//  File: 05_VERIFICATION/testbench/a08_tb.sv
// ---------------------------------------------------------------------
//  DUT   : a08_popcount8   (instance ten 'dut')
//  Chuan : a08_reference      - dung $countones
//          a08_reference_sum  - cong don tung bit trong vong lap
//
//  CAC LOP KIEM
//  ------------
//    [1a] 5 ca bat buoc cua Charter muc 8   (TC-001 .. TC-005)
//    [1b] 5 ca tu xay dung, co ca bien      (TC-006 .. TC-010)
//    [2]  QUET VET CAN toan bo 256 gia tri
//    [3]  bat bien INV-1 .. INV-6 tren tung vector / sau khi quet
//    [4]  INV-7 - khong phu thuoc lich su dau vao (bang chung hanh vi
//         cho "0 o nho", bo tro cho bang chung cau truc 0 flip-flop)
//
//  Tong so vector = 10 (co ten) + 256 (vet can) = 266.
//
//  INV-1 la bat bien DAC THU cua de nay: testbench doc THANG cac net noi
//  bo l1_*, l2_* cua DUT de chung minh cay cong co DUNG hinh dang ma
//  Charter muc 10 doi (4 bo cong 1-bit -> 2 bo cong 2-bit -> 1 bo cong
//  3-bit). Mo phong hanh vi thuan khong lam duoc dieu nay: mot hien thuc
//  viet bang $countones cung cho 'ones' dung y het.
//
//  Cu phap: tranh nhung thu Icarus Verilog 12.0 chua ho tro - khong dung
//  'bind', 'string.getc()', 'assert property', nhan sau 'always @(...)
//  begin : ten', khai bao bien sau cau lenh trong 'initial', gan enum
//  qua toan tu '? :'. Moi bien deu khai bao o pham vi module.
// =====================================================================

`timescale 1ns / 1ps

module a08_tb;

    // -----------------------------------------------------------------
    // Tin hieu kich thich va quan sat
    // -----------------------------------------------------------------
    logic [7:0] a;
    logic [3:0] ones;        // tu DUT
    logic [3:0] ref_cnt;     // tu mo hinh chuan $countones
    logic [3:0] ref_sum;     // tu mo hinh chuan cong don vong lap

    // -----------------------------------------------------------------
    // Bo dem
    // -----------------------------------------------------------------
    integer n_vec;
    integer n_named;
    integer n_exh;
    integer n_err;
    integer n_inv;
    integer n_inv_bad;

    // Phan bo ket qua tren 256 gia tri - dung cho INV-5
    integer hist [0:8];
    integer binom [0:8];

    // -----------------------------------------------------------------
    // Bien vong lap / tam
    // -----------------------------------------------------------------
    integer i, k;
    integer sum_low, sum_high;
    integer cnt_a, cnt_na;
    reg [3:0] hold;

    // =================================================================
    // DUT - ten instance BAT BUOC la 'dut'
    // =================================================================
    a08_popcount8 dut (
        .a    (a),
        .ones (ones)
    );

    // =================================================================
    // Hai mo hinh chuan, dat NGAY CANH DUT, cung dau vao
    // =================================================================
    a08_reference     u_ref_cnt (.a(a), .ones(ref_cnt));
    a08_reference_sum u_ref_sum (.a(a), .ones(ref_sum));

    // =================================================================
    // LOP 3 - kiem bat bien tren vector hien hanh
    // -----------------------------------------------------------------
    //  INV-1  cay cong dung hinh dang Charter muc 10 (doc net noi bo DUT)
    //  INV-2  0 <= ones <= 8 va khong tin hieu ra nao o trang thai X/Z
    //  INV-4  ones(A) = ones(A[3:0]) + ones(A[7:4]) - dieu tang 2 bao dam
    //  INV-6  ones = 0 <=> A = 0x00 ; ones = 8 <=> A = 0xFF
    //
    //  INV-3 va INV-5 chi kiem duoc SAU khi da quet het 256 gia tri nen
    //  chung nam o phan [3b] duoi chuong trinh chinh.
    // =================================================================
    task check_invariants;
        begin
            // ---------- INV-2 : dai gia tri + khong co X/Z ----------
            n_inv = n_inv + 1;
            if ((^ones) === 1'bx) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-2 vi pham: 'ones' co bit X/Z");
                $fatal(1, "INV-2: a=%b ones=%b", a, ones);
            end
            if (ones > 4'd8) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-2 vi pham: ones=%0d vuot dai 0..8", ones);
                $fatal(1, "INV-2: a=%b (%02h) ones=%0d", a, a, ones);
            end

            // ---------- INV-1 : hinh dang cay cong, doc net noi bo ----------
            // Day la bat bien quan trong nhat cua de: no kiem CAU TRUC,
            // khong phai chi kiem ket qua.
            n_inv = n_inv + 1;

            // tang 1 - moi bo cong 1-bit phai bang tong dung cap bit cua no
            if (dut.l1_0 !== (a[0] + a[1]) ||
                dut.l1_1 !== (a[2] + a[3]) ||
                dut.l1_2 !== (a[4] + a[5]) ||
                dut.l1_3 !== (a[6] + a[7])) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-1 vi pham o TANG 1");
                $display("        a=%b  l1_3=%0d l1_2=%0d l1_1=%0d l1_0=%0d",
                         a, dut.l1_3, dut.l1_2, dut.l1_1, dut.l1_0);
                $fatal(1, "INV-1 tang 1: cay cong sai hinh dang");
            end

            // tang 2 - moi bo cong 2-bit phai bang tong dung cap l1
            if (dut.l2_0 !== (dut.l1_0 + dut.l1_1) ||
                dut.l2_1 !== (dut.l1_2 + dut.l1_3)) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-1 vi pham o TANG 2");
                $display("        a=%b  l2_1=%0d l2_0=%0d", a, dut.l2_1, dut.l2_0);
                $fatal(1, "INV-1 tang 2: cay cong sai hinh dang");
            end

            // tang 3 - ket qua phai bang tong hai nua
            if (ones !== (dut.l2_0 + dut.l2_1)) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-1 vi pham o TANG 3");
                $display("        a=%b  l2_1=%0d l2_0=%0d ones=%0d",
                         a, dut.l2_1, dut.l2_0, ones);
                $fatal(1, "INV-1 tang 3: cay cong sai hinh dang");
            end

            // ---------- INV-4 : tong hai nua ----------
            n_inv = n_inv + 1;
            sum_low  = a[0] + a[1] + a[2] + a[3];
            sum_high = a[4] + a[5] + a[6] + a[7];
            if (ones !== (sum_low + sum_high)) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-4 vi pham: nua thap=%0d nua cao=%0d ones=%0d",
                         sum_low, sum_high, ones);
                $fatal(1, "INV-4: a=%b (%02h)", a, a);
            end

            // ---------- INV-6 : hai diem bat dong ----------
            n_inv = n_inv + 1;
            if ((ones == 4'd0) !== (a == 8'h00)) begin
                n_inv_bad = n_inv_bad + 1;
                $fatal(1, "INV-6: ones=0 khong tuong duong a=0x00 (a=%02h ones=%0d)",
                       a, ones);
            end
            if ((ones == 4'd8) !== (a == 8'hFF)) begin
                n_inv_bad = n_inv_bad + 1;
                $fatal(1, "INV-6: ones=8 khong tuong duong a=0xFF (a=%02h ones=%0d)",
                       a, ones);
            end
        end
    endtask

    // =================================================================
    // Ap mot vector va so voi CA HAI mo hinh chuan
    // =================================================================
    task apply;
        input [7:0] v;
        begin
            a = v;
            #1;                     // cho mach to hop on dinh

            n_vec = n_vec + 1;

            if (ones !== ref_cnt) begin
                n_err = n_err + 1;
                $display("[FATAL] Lech so voi mo hinh chuan ($countones)");
                $display("        a=%b (%02h)", v, v);
                $display("        trung gian: l1=%0d%0d%0d%0d  l2=%0d%0d",
                         dut.l1_3, dut.l1_2, dut.l1_1, dut.l1_0,
                         dut.l2_1, dut.l2_0);
                $display("        DUT=%0d  REF=%0d", ones, ref_cnt);
                $fatal(1, "A08: DUT khac mo hinh chuan $countones");
            end

            if (ones !== ref_sum) begin
                n_err = n_err + 1;
                $display("[FATAL] Lech so voi mo hinh chuan (cong don vong lap)");
                $display("        a=%b (%02h)  DUT=%0d  REF=%0d", v, v, ones, ref_sum);
                $fatal(1, "A08: DUT khac mo hinh chuan cong don");
            end

            check_invariants;
        end
    endtask

    // =================================================================
    // Ap mot vector CO TEN: kiem them gia tri ky vong viet tay, in ca
    // gia tri trung gian cua tung tang de doc duoc tung mat xich.
    // =================================================================
    task named_case;
        input [8*33-1:0] tag;
        input [7:0] v;
        input [3:0] exp;
        begin
            apply(v);
            n_named = n_named + 1;

            if (ones !== exp) begin
                n_err = n_err + 1;
                $display("[FATAL] %0s: ky vong %0d, thuc te %0d", tag, exp, ones);
                $fatal(1, "A08: ca co ten sai ky vong");
            end

            $display("  %0s A=%b | l1=%0d%0d%0d%0d l2=%0d%0d | ones=%0d  [PASS]",
                     tag, v,
                     dut.l1_3, dut.l1_2, dut.l1_1, dut.l1_0,
                     dut.l2_1, dut.l2_0, ones);
        end
    endtask

    // =================================================================
    // CHUONG TRINH CHINH
    // =================================================================
    initial begin
        n_vec     = 0;
        n_named   = 0;
        n_exh     = 0;
        n_err     = 0;
        n_inv     = 0;
        n_inv_bad = 0;
        a         = 8'h00;
        hold      = 4'd0;

        for (k = 0; k <= 8; k = k + 1) hist[k] = 0;
        binom[0] = 1; binom[1] = 8; binom[2] = 28; binom[3] = 56;
        binom[4] = 70;
        binom[5] = 56; binom[6] = 28; binom[7] = 8; binom[8] = 1;

        $dumpfile("a08_waves.vcd");
        $dumpvars(0, a08_tb);

        $display("======================================================================");
        $display("  A08 . TESTBENCH - Bo dem so bit 1 (population count) 8-bit");
        $display("  DUT: a08_popcount8   Chuan: a08_reference + a08_reference_sum");
        $display("======================================================================");

        // -------------------------------------------------------------
        // [1a] NAM CA BAT BUOC CUA CHARTER MUC 8
        // -------------------------------------------------------------
        $display("");
        $display("[1a] Ca bat buoc cua Charter muc 8");
        $display("----------------------------------------------------------------------");

        // TC-001 . bien duoi tuyet doi - toan bo cay nghi
        named_case("TC-001 bien duoi tuyet doi      ", 8'h00, 4'd0);
        // TC-002 . bien tren tuyet doi - ca DUY NHAT trong 256 lam ones[3]=1
        named_case("TC-002 bien tren tuyet doi      ", 8'hFF, 4'd8);
        // TC-003 . nua thap day: l2_0 = 4, l2_1 = 0
        named_case("TC-003 nua thap day             ", 8'h0F, 4'd4);
        // TC-004 . xen ke: bon bit 1 ma KHONG half adder nao sinh carry
        named_case("TC-004 mau xen ke               ", 8'hAA, 4'd4);
        // TC-005 . mot bit o vi tri xa nhat, phai di het chieu dai cay
        named_case("TC-005 mot bit o vi tri cao nhat", 8'h80, 4'd1);

        // -------------------------------------------------------------
        // [1b] NAM CA TU XAY DUNG (co ca bien)
        // -------------------------------------------------------------
        $display("");
        $display("[1b] Ca tu xay dung - co ca bien");
        $display("----------------------------------------------------------------------");

        // TC-006 . BIEN doi xung voi TC-005 o dau kia cua tu
        named_case("TC-006 BIEN mot bit o vi tri 0  ", 8'h01, 4'd1);
        // TC-007 . doi ngau TC-003: l2_0 = 0, l2_1 = 4 - bat loi hoan vi
        //          toan hang o tang 3 va loi dao nua cao / nua thap
        named_case("TC-007 nua cao day              ", 8'hF0, 4'd4);
        // TC-008 . doi ngau TC-004 - cung TC-004 la kiem truc tiep INV-3
        named_case("TC-008 mau xen ke nghich        ", 8'h55, 4'd4);
        // TC-009 . BIEN: ones = 7 - gia tri lon nhat VAN vua 3 bit.
        //          Cap TC-009/TC-002 la cap phan chung cho cau hoi
        //          "3 bit hay 4 bit" cua Charter muc 2.
        named_case("TC-009 BIEN 7 bit 1, tat bit 0  ", 8'h7F, 4'd7);
        // TC-010 . BIEN: cung ones = 7 nhung tat bit 7 thay vi bit 0
        named_case("TC-010 BIEN 7 bit 1, tat bit 7  ", 8'hFE, 4'd7);

        $display("");
        $display("  Vector co ten da chay: %0d", n_named);

        // -------------------------------------------------------------
        // [2] QUET VET CAN
        // -------------------------------------------------------------
        // Tat ghi VCD TRUOC vong quet: 256 vector se lam file waveform
        // phinh to ma khong them thong tin nao doc duoc bang mat.
        // -------------------------------------------------------------
        $dumpoff;

        $display("");
        $display("[2] Quet vet can toan bo khong gian dau vao (2^8 = 256 gia tri)");
        $display("----------------------------------------------------------------------");

        for (i = 0; i < 256; i = i + 1) begin
            apply(i[7:0]);
            n_exh = n_exh + 1;
            hist[ones] = hist[ones] + 1;
        end

        $display("  Da quet: %0d/256 gia tri, sai lech: %0d", n_exh, n_err);

        // -------------------------------------------------------------
        // [3b] BAT BIEN CHI KIEM DUOC SAU KHI QUET HET
        // -------------------------------------------------------------
        $display("");
        $display("[3b] Bat bien tren toan bo khong gian");
        $display("----------------------------------------------------------------------");

        // ---- INV-5 : phan bo ket qua khop he so nhi thuc C(8,k) ----
        n_inv = n_inv + 1;
        for (k = 0; k <= 8; k = k + 1) begin
            if (hist[k] !== binom[k]) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-5 vi pham tai ones=%0d: do duoc %0d, C(8,%0d)=%0d",
                         k, hist[k], k, binom[k]);
                $fatal(1, "INV-5: phan bo ket qua khong khop he so nhi thuc");
            end
        end
        $display("  INV-5 phan bo do duoc : %0d %0d %0d %0d %0d %0d %0d %0d %0d",
                 hist[0], hist[1], hist[2], hist[3], hist[4],
                 hist[5], hist[6], hist[7], hist[8]);
        $display("        he so C(8,k)    : %0d %0d %0d %0d %0d %0d %0d %0d %0d",
                 binom[0], binom[1], binom[2], binom[3], binom[4],
                 binom[5], binom[6], binom[7], binom[8]);
        $display("        ==> KHOP");

        // ---- INV-3 : ones(A) + ones(~A) = 8 tren ca 256 gia tri ----
        // Kiem lai bang cach ap A roi ap ~A, KHONG dem vao so vector cua
        // bao cao vi day la phep kiem doi chieu, khong phai vector moi.
        for (i = 0; i < 256; i = i + 1) begin
            a = i[7:0];   #1;  cnt_a  = ones;
            a = ~i[7:0];  #1;  cnt_na = ones;
            n_inv = n_inv + 1;
            if ((cnt_a + cnt_na) !== 8) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-3 vi pham: A=%02h -> %0d, ~A=%02h -> %0d, tong=%0d",
                         i[7:0], cnt_a, (~i[7:0]), cnt_na, cnt_a + cnt_na);
                $fatal(1, "INV-3: doi xung bu bit bi pha vo");
            end
        end
        $display("  INV-3 ones(A) + ones(~A) = 8 : dung tren ca 256 gia tri");

        // -------------------------------------------------------------
        // [4] INV-7 - KHONG PHU THUOC LICH SU DAU VAO
        // -------------------------------------------------------------
        // Bang chung HANH VI cho "0 o nho": ap cung mot gia tri sau HAI
        // lich su khac nhau, ket qua phai trung khit. Bang chung CAU TRUC
        // la 0 flip-flop trong synth_stat.txt.
        // -------------------------------------------------------------
        $display("");
        $display("[4] INV-7 - khong phu thuoc lich su dau vao");
        $display("----------------------------------------------------------------------");

        a = 8'h00; #1;
        a = 8'hAA; #1;  hold = ones;      // lich su 1: 0x00 -> 0xAA

        a = 8'hFF; #1;
        a = 8'hAA; #1;                    // lich su 2: 0xFF -> 0xAA

        n_inv = n_inv + 1;
        if (ones !== hold) begin
            n_inv_bad = n_inv_bad + 1;
            $display("[FATAL] INV-7 vi pham: cung A=0xAA cho hai ket qua khac nhau");
            $fatal(1, "INV-7: sau 0x00 -> %0d, sau 0xFF -> %0d", hold, ones);
        end
        $display("  A=0xAA sau lich su 0x00 -> ones=%0d", hold);
        $display("  A=0xAA sau lich su 0xFF -> ones=%0d", ones);
        $display("  ==> khong phu thuoc lich su : DUNG (mach to hop thuan)");

        // -------------------------------------------------------------
        // TONG KET
        // -------------------------------------------------------------
        $display("");
        $display("======================================================================");
        $display("  TONG KET A08");
        $display("======================================================================");
        $display("  Vector co ten            : %0d", n_named);
        $display("  Vector quet vet can      : %0d/256", n_exh);
        $display("  TONG SO VECTOR           : %0d", n_vec);
        $display("  Sai lech so voi chuan    : %0d", n_err);
        $display("  Lan kiem bat bien        : %0d", n_inv);
        $display("  Vi pham bat bien         : %0d", n_inv_bad);
        $display("  Flip-flop trong RTL      : 0 (khong co always_ff, khong co clk/rst)");

        if (n_err != 0 || n_inv_bad != 0 || n_exh != 256) begin
            $display("");
            $display("  KET QUA A08: FAIL");
            $fatal(1, "A08: testbench that bai");
        end

        $display("");
        $display("  KET QUA A08: PASS - %0d vector, 0 sai lech, %0d lan kiem bat bien, 0 vi pham",
                 n_vec, n_inv);
        $finish;
    end

endmodule
