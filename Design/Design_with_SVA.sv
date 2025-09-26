module FIFO(input clk, rst, wr, rd,
            input [7:0] din, output reg [7:0] dout,
            output empty, full);
  reg [3:0] wptr = 0, rptr = 0;

  reg [4:0] cnt = 0;
  
  reg [7:0] mem [15:0];
 
  always @(posedge clk)
    begin
      if (rst == 1'b1)
        begin
          wptr <= 0;
          rptr <= 0;
          cnt  <= 0;
        end
      else if (wr && !full)
        begin
          mem[wptr] <= din;
          wptr      <= wptr + 1;
          cnt       <= cnt + 1;
        end
      else if (rd && !empty)
        begin
          dout <= mem[rptr];
          rptr <= rptr + 1;
          cnt  <= cnt - 1;
        end
    end
 
  assign empty = (cnt == 0) ? 1'b1 : 1'b0;
  assign full  = (cnt == 16) ? 1'b1 : 1'b0;

//P1
property ed_e_f_flag;
@(posedge clk)
$rose(rst) |-> (full==1'b0 && empty==1'b1)
endproperty


assert property(ed_e_f_flag)
begin
$display("PASSED P1");
end
else
$display("FAILED P1");

property le_e_f_flag;
@(posedge clk)
(rst==1'b1) |-> (full==1'b0 && empty==1'b1)
endproperty

assert property(le_e_f_flag)
begin
$display("PASSED P11");
end
else
$display("FAILED P11"); 


//P2
property full_wptr;
@(posedge clk)
(wptr==16) |-> (full==1'b1)
endproperty

assert property(full_wptr)
begin
$display("PASSED P2");
end
else
$display("FAILED P2"); 
//-------------------------------------------------
property emp_rptr;
@(posedge clk)
(rptr==16) |-> (empty==1'b1)
endproperty

//P3
property p3;
@(posedge clk)
(empty==1'b1) |-> (rd==1'b0)
endproperty

assert property(p3)
begin
$display("PASSED P3");
end
else
$display("FAILED P3"); 

//P4
property p4;
@(posedge clk)
(full==1'b1) |-> (wr==1'b0)
endproperty

assert property(p4)
begin
$display("PASSED P4");
end
else
$display("FAILED P4"); 

//P5
property p5;
@(posedge clk)
(wr && !full) |=> $changed(wptr)
endproperty

assert property(p5)
begin
$display("PASSED P5");
end
else
$display("FAILED P5"); 

//P6
property p6;
@(posedge clk)
(!wr) |=> $stable(wptr)
endproperty
assert property(p6)
begin
$display("PASSED P6");
end
else
$display("FAILED P6"); 

//P7
property p7;
@(posedge clk)
(rd) |=> $stable(wptr)
endproperty

assert property(p7)
begin
$display("PASSED P7");
end
else
$display("FAILED P7"); 

//P8
property p8;
@(posedge clk)
(rd) |=> $changed(rptr)
endproperty
assert property(p8)
begin
$display("PASSED P8");
end
else
$display("FAILED P8"); 

endmodule


interface fifoint;
  logic clk;
  logic rst;
  logic wr;
  logic rd;
  logic [7:0]din;
  logic [7:0]dout;
  logic empty;
  logic full;
endinterface
