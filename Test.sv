class test extends uvm_test;
  `uvm_component_utils(test);
  env e;
  sequence1 seq;
  function new(string path="test",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    e=env::type_id::create("e",this);
    seq=sequence1::type_id::create("seq",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
//     e.a.drv.reset();
    seq.start(e.a.seqr);
    #50;
    phase.drop_objection(this);
  endtask
endclass
