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
//     @(posedge inf.clk);
    inf.rst=1'b1;
    inf.rd=1'b0;
    inf.wr=1'b0;
    inf.din=0;
    repeat(5)@(posedge inf.clk);
    inf.rst<=1'b0;
    `uvm_info("RST",$sformatf("[%0t] DUT RESET DONE",$time),UVM_NONE);
  endtask
  
  task write();
    @(posedge inf.clk)
    inf.rst<=1'b0;
    inf.rd<=1'b0;
    inf.wr<=1'b1;
    inf.din<=trans.din;
    @(posedge inf.clk);
    inf.wr<=1'b0;
    `uvm_info("DRV",$sformatf("[%0t] WRITE OPERATION DONE of DATA=%0d",$time,trans.din),UVM_NONE);
  endtask
  
  task read();
    @(posedge inf.clk)
    inf.rst<=1'b0;
    inf.rd<=1'b1;
    inf.wr<=1'b0;
    @(posedge inf.clk);
    inf.rd<=1'b0;
    `uvm_info("DRV",$sformatf("[%0t] READ OPERATION DONE",$time),UVM_NONE);
  endtask
      
       
  
  virtual task run_phase(uvm_phase phase);
    forever
      begin
        seq_item_port.get_next_item(trans);
        if(trans.oper==1'b1)
          write();
        else
          read();
        seq_item_port.item_done(trans);
      end
  endtask
endclass
