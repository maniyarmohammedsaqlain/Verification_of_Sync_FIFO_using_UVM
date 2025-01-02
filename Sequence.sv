class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1);
  transaction trans;
  function new(string path="seq");
    super.new(path);
  endfunction
  
  virtual task body();
    trans=transaction::type_id::create("trans");
    repeat(10)
      begin
        start_item(trans);
        trans.randomize();
        `uvm_info("trans",$sformatf("[%0t] OPER=%0d, DIN=%0d",$time,trans.oper,trans.din),UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass
