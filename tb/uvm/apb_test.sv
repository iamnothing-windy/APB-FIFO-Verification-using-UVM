`ifndef APB_TEST_SV
`define APB_TEST_SV

class apb_fifo_base_test extends uvm_test;
  `uvm_component_utils(apb_fifo_base_test)

  apb_env env;

  function new(string name = "apb_fifo_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_env::type_id::create("env", this);
  endfunction

  protected task run_sequence(uvm_phase phase, uvm_sequence #(apb_trans) seq);
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #20;
    phase.drop_objection(this);
  endtask
endclass

class apb_fifo_reset_test extends apb_fifo_base_test;
  `uvm_component_utils(apb_fifo_reset_test)

  function new(string name = "apb_fifo_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_fifo_reset_check_sequence seq;
    seq = apb_fifo_reset_check_sequence::type_id::create("seq");
    run_sequence(phase, seq);
  endtask
endclass

class apb_fifo_basic_test extends apb_fifo_base_test;
  `uvm_component_utils(apb_fifo_basic_test)

  function new(string name = "apb_fifo_basic_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_fifo_basic_sequence seq;
    seq = apb_fifo_basic_sequence::type_id::create("seq");
    run_sequence(phase, seq);
  endtask
endclass

class apb_fifo_full_overflow_test extends apb_fifo_base_test;
  `uvm_component_utils(apb_fifo_full_overflow_test)

  function new(string name = "apb_fifo_full_overflow_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_fifo_full_overflow_sequence seq;
    seq = apb_fifo_full_overflow_sequence::type_id::create("seq");
    run_sequence(phase, seq);
  endtask
endclass

class apb_fifo_underflow_test extends apb_fifo_base_test;
  `uvm_component_utils(apb_fifo_underflow_test)

  function new(string name = "apb_fifo_underflow_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_fifo_underflow_sequence seq;
    seq = apb_fifo_underflow_sequence::type_id::create("seq");
    run_sequence(phase, seq);
  endtask
endclass

class apb_fifo_wrap_test extends apb_fifo_base_test;
  `uvm_component_utils(apb_fifo_wrap_test)

  function new(string name = "apb_fifo_wrap_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_fifo_wrap_sequence seq;
    seq = apb_fifo_wrap_sequence::type_id::create("seq");
    run_sequence(phase, seq);
  endtask
endclass

class apb_fifo_register_test extends apb_fifo_base_test;
  `uvm_component_utils(apb_fifo_register_test)

  function new(string name = "apb_fifo_register_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_fifo_register_sequence seq;
    seq = apb_fifo_register_sequence::type_id::create("seq");
    run_sequence(phase, seq);
  endtask
endclass

class apb_fifo_invalid_addr_test extends apb_fifo_base_test;
  `uvm_component_utils(apb_fifo_invalid_addr_test)

  function new(string name = "apb_fifo_invalid_addr_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_fifo_invalid_addr_sequence seq;
    seq = apb_fifo_invalid_addr_sequence::type_id::create("seq");
    run_sequence(phase, seq);
  endtask
endclass

class apb_fifo_random_test extends apb_fifo_base_test;
  `uvm_component_utils(apb_fifo_random_test)

  function new(string name = "apb_fifo_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_fifo_random_sequence seq;
    seq = apb_fifo_random_sequence::type_id::create("seq");
    run_sequence(phase, seq);
  endtask
endclass

class apb_fifo_full_regression_test extends apb_fifo_base_test;
  `uvm_component_utils(apb_fifo_full_regression_test)

  function new(string name = "apb_fifo_full_regression_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_fifo_full_regression_sequence seq;
    seq = apb_fifo_full_regression_sequence::type_id::create("seq");
    run_sequence(phase, seq);
  endtask
endclass

class apb_test extends apb_fifo_full_regression_test;
  `uvm_component_utils(apb_test)

  function new(string name = "apb_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass

`endif
