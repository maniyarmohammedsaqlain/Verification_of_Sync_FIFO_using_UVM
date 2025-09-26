`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction);
  function new(string path="trans");
    super.new(path);
  endfunction
  bit rst;
  bit[1:0] oper;          
  bit rd, wr;            
  rand bit [7:0] din;      
  bit full, empty;        
  bit [7:0] dout;   
endclass 
class reset_seq extends uvm_sequence#(transaction);
  `uvm_object_utils(reset_seq);
  transaction trans;
  function new(string path="reset_seq");
    super.new(path);
  endfunction
  
  virtual task body();
    trans=transaction::type_id::create("trans");
    repeat(1)
      begin
        start_item(trans);
        assert(trans.randomize());
	trans.oper = 2'b00;
        `uvm_info("trans",$sformatf("[%0t] OPER=%0d RESET APPLIED",$time,trans.oper),UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass

class wrt_seq extends uvm_sequence#(transaction);
  `uvm_object_utils(wrt_seq);
  transaction trans;
  function new(string path="wrt_seq");
    super.new(path);
  endfunction
  
  virtual task body();
    trans=transaction::type_id::create("trans");
    repeat(20)
      begin
        start_item(trans);
        assert(trans.randomize());
	trans.oper = 2'b01;
        `uvm_info("trans",$sformatf("[%0t] OPER=%0d, DIN=%0d",$time,trans.oper,trans.din),UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass


class rd_seq extends uvm_sequence#(transaction);
  `uvm_object_utils(rd_seq);
  transaction trans;
  function new(string path="rd_seq");
    super.new(path);
  endfunction
  
  virtual task body();
    trans=transaction::type_id::create("trans");
    repeat(20)
      begin
        start_item(trans);
        assert(trans.randomize());
	       trans.oper = 2'b10;
        `uvm_info("trans",$sformatf("[%0t] OPER=%0d, DIN=%0d",$time,trans.oper,trans.din),UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver);
  transaction trans;
  virtual fifoint inf;
  function new(string path="drv",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans");
    
    if(!uvm_config_db #(virtual fifoint)::get(this,"","inf",inf))
       `uvm_info("drv","error in config of driver",UVM_NONE);
  endfunction
  task reset();
    @(posedge inf.clk);
    inf.rst=1'b1;
    inf.rd=1'b0;
    inf.wr=1'b0;
    inf.din=0;
    `uvm_info("RST",$sformatf("[%0t] DUT RESET DONE",$time),UVM_NONE);
    @(posedge inf.clk);
  endtask
  
  task write();
    @(posedge inf.clk)
    inf.rst=1'b0;
    inf.rd=1'b0;
    inf.wr=1'b1;
    inf.din=trans.din;
    `uvm_info("DRV",$sformatf("[%0t] WRITE OPERATION DONE of DATA=%0d",$time,trans.din),UVM_NONE);
    @(posedge inf.clk);
    inf.wr=1'b0;
  endtask

task read();
    @(posedge inf.clk);
    inf.rst = 1'b0;
    inf.rd = 1'b1;
    inf.wr = 1'b0;
    `uvm_info("DRV", $sformatf("[%0t] READ OPERATION INITIATED", $time), UVM_NONE);
    @(posedge inf.clk);
    #20;
   
    inf.rd = 1'b0;  
endtask
      
    
  
  virtual task run_phase(uvm_phase phase);
    forever
      begin
        seq_item_port.get_next_item(trans);
	if(trans.oper == 2'b00)
	  reset();
        else if(trans.oper == 2'b01)
          write();
        else if(trans.oper == 2'b10)
          read();
        seq_item_port.item_done();
      end
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  transaction trans;
  virtual fifoint inf;
  uvm_analysis_port #(transaction)send; 
  function new(string path="mon",uvm_component parent=null);
    super.new(path,parent);
    send=new("send",this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans");
    if(!uvm_config_db #(virtual fifoint)::get(this,"","inf",inf))
      `uvm_info("mon","error in config of monitor",UVM_NONE);
endfunction

virtual task run_phase(uvm_phase phase);
    forever begin
        @(posedge inf.clk);
        if(inf.rst) begin
	    @(posedge inf.clk);
            trans.rst = inf.rst;
            `uvm_info("MON", "RESET DETECTED IN MONITOR", UVM_NONE);
            send.write(trans);
        end
        else if(inf.wr) begin   
	    @(posedge inf.clk);  
            trans.rst = inf.rst;
            trans.din = inf.din;
            trans.dout = inf.dout;
            trans.empty = inf.empty;
            trans.full = inf.full;
            trans.wr = inf.wr;
            trans.rd = inf.rd;     
            `uvm_info("MON", $sformatf("[%0t] WRITE: DIN=%0d EMPTY=%0d FULL=%0d", $time, trans.din, trans.empty, trans.full), UVM_NONE);
            send.write(trans);
        end
        else if(inf.rd) begin     
	    @(posedge inf.clk);
	    #20;
            trans.rst = inf.rst;
            trans.dout = inf.dout;  
            trans.empty = inf.empty;
            trans.full = inf.full;
            trans.rd = inf.rd;
            trans.wr = inf.wr;
            `uvm_info("MON", $sformatf("[%0t] READ: DOUT=%0d EMPTY=%0d FULL=%0d", $time, trans.dout, trans.empty, trans.full), UVM_NONE);
            send.write(trans);
        end
    end
endtask
endclass


class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);
  transaction trans;
  uvm_analysis_imp #(transaction,scoreboard)recv;
  bit [7:0] mem [$];
  bit [7:0]temp;
  function new(string path="scb",uvm_component parent=null);
    super.new(path,parent);
    recv=new("recv",this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans");
  endfunction
  
  virtual function void write(transaction tr);
    trans=tr;
  if(trans.rst)
    begin
	`uvm_info("SCB","RESET DETECTED IN DUT",UVM_NONE);
    `uvm_info("FINISH","------------------------------------------------------",UVM_NONE);
    end
    else if(trans.wr)
      begin
        if(trans.full==1'b0)
          begin
            mem.push_front(trans.din);
            `uvm_info("SCB",$sformatf("[%0t] DATA STORED IN FIFO",$time),UVM_NONE);
    `uvm_info("FINISH","------------------------------------------------------",UVM_NONE);
          end
        else
          begin
            `uvm_info("STATUS",$sformatf("[%0t] FIFO IS FULL",$time),UVM_NONE);
    `uvm_info("FINISH","------------------------------------------------------",UVM_NONE);
          end
        
      end
    else if(trans.rd)
      begin
        if(trans.empty==1'b0)
          begin
            temp=mem.pop_back();
            if(trans.dout==temp)
              begin
                `uvm_info("SCB",$sformatf("[%0t] MATCHED",$time),UVM_NONE);
    `uvm_info("FINISH","------------------------------------------------------",UVM_NONE);
              end
            else
              begin
                `uvm_info("SCB",$sformatf("[%0t] MISMATCHED",$time),UVM_NONE);
    `uvm_info("FINISH","------------------------------------------------------",UVM_NONE);
              end
          end
        else
          `uvm_info("STATUS",$sformatf("[%0t] FIFO IS EMPTY",$time),UVM_NONE);
        `uvm_info("FINISH","------------------------------------------------------",UVM_NONE);
      end
  endfunction
endclass

class agent extends uvm_agent;
  `uvm_component_utils(agent);
  driver drv;
  monitor mon;
  uvm_sequencer#(transaction)seqr;
  function new(string path="agent",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv=driver::type_id::create("drv",this);
    mon=monitor::type_id::create("mon",this);
    seqr=uvm_sequencer#(transaction)::type_id::create("seqr",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env);

  agent a;
  scoreboard scb;

  function new(string path="env",uvm_component parent=null);
    super.new(path,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a   = agent::type_id::create("a", this);
    scb = scoreboard::type_id::create("scb", this);

endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.mon.send.connect(scb.recv);
  endfunction
endclass


class test extends uvm_test;
  `uvm_component_utils(test);
  env e;
  reset_seq seq1;
  wrt_seq seq2;
  rd_seq seq3;
  function new(string path="test",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    e=env::type_id::create("e",this);
    seq1=reset_seq::type_id::create("seq1",this);
    seq2=wrt_seq::type_id::create("seq2",this);
    seq3=rd_seq::type_id::create("seq3",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq1.start(e.a.seqr);
    seq2.start(e.a.seqr);
    seq3.start(e.a.seqr);
    phase.drop_objection(this);
  endtask
endclass

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
