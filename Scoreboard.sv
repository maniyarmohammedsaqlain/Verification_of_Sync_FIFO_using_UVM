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
    `uvm_info("SCB",$sformatf("[%0t] DATAIN:%0d DOUT:%0d OPER:%0d RD:%0d WR:%0d EMPTY:%0d FULL;%0d",$time,trans.din,trans.dout,trans.oper,trans.rd,trans.wr,trans.empty,trans.full),UVM_NONE);
    if(trans.wr)
      begin
        if(trans.full==1'b0)
          begin
            mem.push_front(trans.din);
            `uvm_info("SCB",$sformatf("[%0t] DATA STORED IN FIFO",$time),UVM_NONE);
          end
        else
          begin
            `uvm_info("STATUS",$sformatf("[%0t] FIFO IS FULL",$time),UVM_NONE);
          end
        `uvm_info("FINISH","------------------------------------------------------",UVM_NONE);
      end
    if(trans.rd)
      begin
        if(trans.empty==1'b0)
          begin
            temp=mem.pop_back();
            if(trans.dout==temp)
              begin
                `uvm_info("SCB",$sformatf("[%0t] MATCHED",$time),UVM_NONE);
              end
            else
              begin
                `uvm_info("SCB",$sformatf("[%0t] MISMATCHED",$time),UVM_NONE);
              end
          end
        else
          `uvm_info("STATUS",$sformatf("[%0t] FIFO IS EMPTY",$time),UVM_NONE);
        `uvm_info("FINISH","------------------------------------------------------",UVM_NONE);
      end
  endfunction
endclass
