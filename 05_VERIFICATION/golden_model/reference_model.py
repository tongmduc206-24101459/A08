#!/usr/bin/env python3
# =====================================================================
#  A08 - Mo hinh chuan Python cho bo dem so bit 1 (population count)
#  File: 05_VERIFICATION/golden_model/reference_model.py
# ---------------------------------------------------------------------
#  De        : A08 . Nhom A - So hoc to hop
#  Loai mach : TO HOP THUAN (khong clock, khong trang thai)
#
#  VAI TRO
#  -------
#  CHUAN SO SANH DOC LAP, viet truoc va kiem truoc khi dong toi Verilog.
#
#  HAI MO HINH NGHI KHAC NHAU
#  --------------------------
#    popcount()      - dem truc tiep, khong co khai niem tang nao
#    popcount_tree() - mo phong DUNG so do cay cong 4 -> 2 -> 1 cua
#                      Charter muc 10
#  Hai mo hinh phai trung khit tren ca 256 gia tri. Day la cach bien cau
#  khang dinh "cay cong 3 tang tinh dung population count" tu mot loi noi
#  thanh mot bang chung chay duoc.
#
#  Chay:  python3 reference_model.py   -> in PASS/FAIL, thoat 0 khi dat
# =====================================================================

import sys

MASK8 = 0xFF


# =====================================================================
#  1. HAI MO HINH DOC LAP
# =====================================================================

def popcount(a):
    """Mo hinh 1 - dem truc tiep.

    Cach nghi cua nguoi viet dac ta: "co bao nhieu bit 1", khong quan tam
    dem bang cach nao. Khong co tang, khong co carry.
    """
    return bin(a & MASK8).count("1")


def popcount_tree(a):
    """Mo hinh 2 - mo phong DUNG so do cay cong cua Charter muc 10.

        tang 1: 4 bo cong 1-bit  (half adder) : 8 bit -> 4 so trong dai 0..2
        tang 2: 2 bo cong 2-bit               : 4 so  -> 2 so trong dai 0..4
        tang 3: 1 bo cong 3-bit               : 2 so  -> 1 so trong dai 0..8

    Tra ve ca ket qua cuoi lan cac gia tri trung gian, de testbench va tai
    lieu co the doi chieu tung mat xich.
    """
    bits = [(a >> i) & 1 for i in range(8)]

    # ---- TANG 1 : bon half adder hoan toan song song ----
    l1 = [
        bits[0] + bits[1],
        bits[2] + bits[3],
        bits[4] + bits[5],
        bits[6] + bits[7],
    ]
    for v in l1:
        assert 0 <= v <= 2, "tang 1 phai nam trong dai 0..2"

    # ---- TANG 2 : hai bo cong 2-bit ----
    l2 = [l1[0] + l1[1], l1[2] + l1[3]]
    for v in l2:
        assert 0 <= v <= 4, "tang 2 phai nam trong dai 0..4"

    # ---- TANG 3 : mot bo cong 3-bit ----
    ones = l2[0] + l2[1]
    assert 0 <= ones <= 8, "tang 3 phai nam trong dai 0..8"

    return ones, l1, l2


# =====================================================================
#  2. HA TANG BAO CAO
# =====================================================================

class Report:
    def __init__(self):
        self.checks = 0
        self.fails = 0
        self.lines = []

    def check(self, ok, what):
        self.checks += 1
        if not ok:
            self.fails += 1
            self.lines.append("    [FAIL] " + what)

    def section(self, title):
        print("")
        print("-" * 72)
        print("  " + title)
        print("-" * 72)


R = Report()


# =====================================================================
#  3. HAI MO HINH PHAI TRUNG KHIT TREN TOAN BO 256 GIA TRI
# =====================================================================

def check_two_models():
    R.section("Mo hinh CAY CONG == mo hinh DEM TRUC TIEP tren 256 gia tri")
    bad = 0
    for a in range(256):
        direct = popcount(a)
        tree, _l1, _l2 = popcount_tree(a)
        if direct != tree:
            bad += 1
            if bad <= 5:
                R.lines.append("    [FAIL] a=0x%02X direct=%d tree=%d" % (a, direct, tree))
    R.check(bad == 0, "hai mo hinh lech nhau %d gia tri" % bad)
    print("    da so khop : 256 gia tri")
    print("    lech       : %d" % bad)
    print("    ==> cay cong 4 -> 2 -> 1 tinh dung population count : %s"
          % ("DUNG" if bad == 0 else "SAI"))


# =====================================================================
#  4. MUOI CA CO TEN - Charter muc 8 + ca tu xay dung
# =====================================================================
#  Day la dung 10 vector co ten ma testbench SystemVerilog cung chay,
#  theo dung thu tu. Tong so vector mo phong = 10 + 256 = 266.
# ---------------------------------------------------------------------

NAMED = [
    # (ten ca,                             A,     ky vong, ghi chu)
    ("TC-001 bien duoi tuyet doi",         0x00, 0, "Charter muc 8"),
    ("TC-002 bien tren tuyet doi",         0xFF, 8, "Charter muc 8 - ca duy nhat bat ones[3]"),
    ("TC-003 nua thap day",                0x0F, 4, "Charter muc 8"),
    ("TC-004 mau xen ke",                  0xAA, 4, "Charter muc 8 - khong HA nao sinh carry"),
    ("TC-005 mot bit o vi tri cao nhat",   0x80, 1, "Charter muc 8"),
    ("TC-006 BIEN mot bit o vi tri 0",     0x01, 1, "tu xay - doi xung TC-005"),
    ("TC-007 nua cao day",                 0xF0, 4, "tu xay - doi ngau TC-003"),
    ("TC-008 mau xen ke nghich",           0x55, 4, "tu xay - doi ngau TC-004"),
    ("TC-009 BIEN 7 bit 1, tat bit 0",     0x7F, 7, "tu xay - gia tri lon nhat VAN vua 3 bit"),
    ("TC-010 BIEN 7 bit 1, tat bit 7",     0xFE, 7, "tu xay - cung 7 nhung khac vi tri"),
]


def check_named():
    R.section("Ca co ten . Charter muc 8 + ca tu xay dung (%d vector)" % len(NAMED))
    for name, a, exp, note in NAMED:
        direct = popcount(a)
        tree, l1, l2 = popcount_tree(a)
        ok = (direct == exp) and (tree == exp)
        R.check(ok, "%s: A=0x%02X ky vong %d, direct=%d tree=%d" % (name, a, exp, direct, tree))
        print("    %-33s A=%s | l1=%s l2=%s | ones=%d  [%s]"
              % (name, format(a, "08b"), "".join(str(v) for v in reversed(l1)),
                 "".join(str(v) for v in reversed(l2)), tree,
                 "PASS" if ok else "FAIL"))
    return len(NAMED)


# =====================================================================
#  5. BAT BIEN INV-1 .. INV-6 TREN TOAN BO 256 GIA TRI
# =====================================================================

def check_invariants():
    R.section("Bat bien INV-1..INV-6 tren toan bo 256 gia tri dau vao")

    n = {k: 0 for k in range(1, 7)}
    bad = {k: 0 for k in range(1, 7)}
    hist = [0] * 9

    for a in range(256):
        ones, l1, l2 = popcount_tree(a)
        hist[ones] += 1
        bits = [(a >> i) & 1 for i in range(8)]

        # INV-1 : cay cong dung hinh dang Charter muc 10
        n[1] += 1
        ok = (l1[0] == bits[0] + bits[1] and
              l1[1] == bits[2] + bits[3] and
              l1[2] == bits[4] + bits[5] and
              l1[3] == bits[6] + bits[7] and
              l2[0] == l1[0] + l1[1] and
              l2[1] == l1[2] + l1[3] and
              ones == l2[0] + l2[1])
        if not ok:
            bad[1] += 1

        # INV-2 : 0 <= ones <= 8
        n[2] += 1
        if not (0 <= ones <= 8):
            bad[2] += 1

        # INV-3 : ones(A) + ones(~A) = 8
        n[3] += 1
        if ones + popcount((~a) & MASK8) != 8:
            bad[3] += 1

        # INV-4 : ones(A) = ones(nua thap) + ones(nua cao) - dieu tang 2 bao dam
        n[4] += 1
        if ones != popcount(a & 0x0F) + popcount((a >> 4) & 0x0F):
            bad[4] += 1

        # INV-6 : ones = 0 <=> A = 0x00 ; ones = 8 <=> A = 0xFF
        n[6] += 1
        if (ones == 0) != (a == 0x00):
            bad[6] += 1
        if (ones == 8) != (a == 0xFF):
            bad[6] += 1

    # INV-5 : phan bo ket qua khop he so nhi thuc C(8,k) - chi kiem duoc
    #         SAU KHI da quet het 256 gia tri
    n[5] += 1
    binom = [1, 8, 28, 56, 70, 56, 28, 8, 1]
    if hist != binom:
        bad[5] += 1

    table = [
        (1, "cay cong dung hinh dang Charter muc 10"),
        (2, "0 <= ones <= 8"),
        (3, "ones(A) + ones(~A) = 8"),
        (4, "ones(A) = ones(A[3:0]) + ones(A[7:4])"),
        (5, "phan bo khop he so nhi thuc C(8,k)"),
        (6, "ones=0 <=> A=0x00 ; ones=8 <=> A=0xFF"),
    ]
    total = 0
    for k, desc in table:
        total += n[k]
        R.check(bad[k] == 0, "INV-%d vi pham %d lan" % (k, bad[k]))
        print("    INV-%d  %-44s %5d lan, %d vi pham" % (k, desc, n[k], bad[k]))

    print("")
    print("    Phan bo do duoc : %s" % hist)
    print("    He so C(8,k)    : %s" % binom)
    print("    Tong so gia tri : %d" % sum(hist))
    print("    %-51s %5d lan" % ("TONG so lan kiem bat bien", total))
    return total


# =====================================================================
#  6. CHUONG TRINH CHINH
# =====================================================================

def main():
    print("=" * 72)
    print("  A08 . MO HINH CHUAN PYTHON - bo dem so bit 1 (population count) 8-bit")
    print("  Khong gian dau vao: 2^8 = 256 gia tri  => quet VET CAN duoc")
    print("=" * 72)

    check_two_models()
    n_named = check_named()
    n_inv = check_invariants()

    print("")
    print("=" * 72)
    print("  TONG KET")
    print("=" * 72)
    print("  Gia tri da quet vet can  : 256")
    print("  Vector co ten            : %d" % n_named)
    print("  Lan kiem bat bien        : %d" % n_inv)
    print("  So phep kiem             : %d" % R.checks)
    print("  So phep kiem that bai    : %d" % R.fails)

    if R.fails:
        for line in R.lines[:40]:
            print(line)
        print("")
        print("  A08 REFERENCE MODEL: FAIL")
        return 1

    print("")
    print("  A08 REFERENCE MODEL: PASS - %d/%d phep kiem dat, 0 sai lech"
          % (R.checks, R.checks))
    return 0


if __name__ == "__main__":
    sys.exit(main())
