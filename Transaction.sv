class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction);
  function new(string path="trans");
    super.new(path);
  endfunction
  
  rand bit oper;          
  bit rd, wr;            
  rand bit [7:0] din;      
  bit full, empty;        
  bit [7:0] dout;   
  constraint oper_ctrl {  
    oper dist {1 :/ 50 , 0 :/ 50}; 
  }
endclass 
