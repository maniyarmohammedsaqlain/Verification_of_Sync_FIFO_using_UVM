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
    forever
      begin
        repeat(2)@(posedge inf.clk);
        trans.din=inf.din;
        trans.dout=inf.dout;
        trans.empty=inf.empty;
        trans.full=inf.full;
        trans.wr=inf.wr;
        trans.rd=inf.rd;
        `uvm_info("MON",$sformatf("[%0t] DATAIN:%0d DOUT:%0d OPER:%0d RD:%0d WR:%0d EMPTY:%0d FULL;%0d",$time,trans.din,trans.dout,trans.oper,trans.rd,trans.wr,trans.empty,trans.full),UVM_NONE);
        send.write(trans);
      end
  endtask
endclass
