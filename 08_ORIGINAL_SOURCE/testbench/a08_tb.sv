module a08_tb;
    logic clk,rst,en;
    logic [7:0] d,q,qr;

    a08_register dut(.clk(clk),.rst(rst),.en(en),.d(d),.q(q));
    a08_reference ref_i(.clk(clk),.rst(rst),.en(en),.d(d),.q(qr));

    always #5 clk=~clk;

    task automatic apply(
        input logic rr,
        input logic ee,
        input logic [7:0] dd,
        input logic [7:0] expected
    );
        begin
            rst=rr; en=ee; d=dd;
            @(posedge clk); #1;
            assert(q===expected) else $fatal(1,"Q mismatch");
            assert(qr===expected) else $fatal(1,"Reference Q mismatch");
        end
    endtask

    initial begin
        clk=0; rst=1; en=0; d=0;
        apply(1,0,8'hA5,8'h00);

        apply(0,1,8'h3C,8'h3C);
        apply(0,0,8'hF0,8'h3C);
        apply(0,1,8'hF0,8'hF0);

        apply(1,1,8'h55,8'h00);
        apply(0,0,8'hAA,8'h00);
        apply(0,1,8'hAA,8'hAA);

        $display("A08 register validation PASS");
        $finish;
    end
endmodule
