module tb;
  fifoint inf();
  FIFO DUT(.clk(inf.clk),.rst(inf.rst),.wr(inf.wr),.rd(inf.rd),.din(inf.din),.dout(inf.dout),.empty(inf.empty),.full(inf.full));
  
  initial
    begin
      inf.clk=0;
    end
  always
    #10 inf.clk=~inf.clk;
  initial
    begin
      uvm_config_db #(virtual fifoint)::set(null,"*","inf",inf);
      run_test("test");
    end
endmodule
