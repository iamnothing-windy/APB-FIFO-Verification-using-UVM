`ifndef APB_SEQUENCE_SV
`define APB_SEQUENCE_SV

class apb_fifo_base_sequence extends uvm_sequence #(apb_trans);
  `uvm_object_utils(apb_fifo_base_sequence)

  function new(string name = "apb_fifo_base_sequence");
    super.new(name);
  endfunction

  protected task send_transfer(
    string name,
    apb_cmd_e cmd,
    bit [`AWIDTH-1:0] addr,
    bit [`DWIDTH-1:0] data = '0
  );
    apb_trans tr;

    tr = apb_trans::type_id::create(name);
    start_item(tr);
    tr.cmd  = cmd;
    tr.addr = addr;
    tr.data = data;
    finish_item(tr);
  endtask
endclass

class apb_fifo_reset_check_sequence extends apb_fifo_base_sequence;
  `uvm_object_utils(apb_fifo_reset_check_sequence)

  function new(string name = "apb_fifo_reset_check_sequence");
    super.new(name);
  endfunction

  virtual task body();
    send_transfer("reset_read_status", APB_READ, `APB_ADDR_STATUS);
    send_transfer("reset_read_count", APB_READ, `APB_ADDR_COUNT);
  endtask
endclass

class apb_fifo_basic_sequence extends apb_fifo_base_sequence;
  `uvm_object_utils(apb_fifo_basic_sequence)

  function new(string name = "apb_fifo_basic_sequence");
    super.new(name);
  endfunction

  virtual task body();
    send_transfer("basic_write_0", APB_WRITE, `APB_ADDR_DATA, 8'h11);
    send_transfer("basic_write_1", APB_WRITE, `APB_ADDR_DATA, 8'h22);
    send_transfer("basic_write_2", APB_WRITE, `APB_ADDR_DATA, 8'h33);
    send_transfer("basic_read_count_partial", APB_READ, `APB_ADDR_COUNT);
    send_transfer("basic_read_status_partial", APB_READ, `APB_ADDR_STATUS);
    send_transfer("basic_read_0", APB_READ, `APB_ADDR_DATA);
    send_transfer("basic_read_1", APB_READ, `APB_ADDR_DATA);
    send_transfer("basic_read_2", APB_READ, `APB_ADDR_DATA);
    send_transfer("basic_read_status_empty", APB_READ, `APB_ADDR_STATUS);
    send_transfer("basic_read_count_empty", APB_READ, `APB_ADDR_COUNT);
  endtask
endclass

class apb_fifo_full_overflow_sequence extends apb_fifo_base_sequence;
  `uvm_object_utils(apb_fifo_full_overflow_sequence)

  function new(string name = "apb_fifo_full_overflow_sequence");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < `FIFO_DEPTH; i++) begin
      send_transfer($sformatf("full_write_%0d", i), APB_WRITE, `APB_ADDR_DATA, 8'hA0 + i);
    end

    send_transfer("full_read_status", APB_READ, `APB_ADDR_STATUS);
    send_transfer("full_read_count", APB_READ, `APB_ADDR_COUNT);
    send_transfer("overflow_write", APB_WRITE, `APB_ADDR_DATA, 8'h5A);

    for (int i = 0; i < `FIFO_DEPTH; i++) begin
      send_transfer($sformatf("full_read_%0d", i), APB_READ, `APB_ADDR_DATA);
    end

    send_transfer("after_full_read_status_empty", APB_READ, `APB_ADDR_STATUS);
    send_transfer("after_full_read_count_empty", APB_READ, `APB_ADDR_COUNT);
  endtask
endclass

class apb_fifo_underflow_sequence extends apb_fifo_base_sequence;
  `uvm_object_utils(apb_fifo_underflow_sequence)

  function new(string name = "apb_fifo_underflow_sequence");
    super.new(name);
  endfunction

  virtual task body();
    send_transfer("underflow_read", APB_READ, `APB_ADDR_DATA);
    send_transfer("underflow_status_empty", APB_READ, `APB_ADDR_STATUS);
    send_transfer("underflow_count_empty", APB_READ, `APB_ADDR_COUNT);
  endtask
endclass

class apb_fifo_wrap_sequence extends apb_fifo_base_sequence;
  `uvm_object_utils(apb_fifo_wrap_sequence)

  function new(string name = "apb_fifo_wrap_sequence");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < 5; i++) begin
      send_transfer($sformatf("wrap_initial_write_%0d", i), APB_WRITE, `APB_ADDR_DATA, 8'hD0 + i);
    end

    for (int i = 0; i < 3; i++) begin
      send_transfer($sformatf("wrap_initial_read_%0d", i), APB_READ, `APB_ADDR_DATA);
    end

    for (int i = 0; i < 6; i++) begin
      send_transfer($sformatf("wrap_second_write_%0d", i), APB_WRITE, `APB_ADDR_DATA, 8'hE0 + i);
    end

    send_transfer("wrap_read_status_full", APB_READ, `APB_ADDR_STATUS);
    send_transfer("wrap_read_count_full", APB_READ, `APB_ADDR_COUNT);

    for (int i = 0; i < `FIFO_DEPTH; i++) begin
      send_transfer($sformatf("wrap_final_read_%0d", i), APB_READ, `APB_ADDR_DATA);
    end

    send_transfer("wrap_read_status_empty", APB_READ, `APB_ADDR_STATUS);
    send_transfer("wrap_read_count_empty", APB_READ, `APB_ADDR_COUNT);
  endtask
endclass

class apb_fifo_register_sequence extends apb_fifo_base_sequence;
  `uvm_object_utils(apb_fifo_register_sequence)

  function new(string name = "apb_fifo_register_sequence");
    super.new(name);
  endfunction

  virtual task body();
    send_transfer("write_status_read_only", APB_WRITE, `APB_ADDR_STATUS, 8'h55);
    send_transfer("write_count_read_only", APB_WRITE, `APB_ADDR_COUNT, 8'h66);
    send_transfer("read_status_after_ro_write", APB_READ, `APB_ADDR_STATUS);
    send_transfer("read_count_after_ro_write", APB_READ, `APB_ADDR_COUNT);
  endtask
endclass

class apb_fifo_invalid_addr_sequence extends apb_fifo_base_sequence;
  `uvm_object_utils(apb_fifo_invalid_addr_sequence)

  function new(string name = "apb_fifo_invalid_addr_sequence");
    super.new(name);
  endfunction

  virtual task body();
    send_transfer("write_invalid_addr_0", APB_WRITE, `APB_ADDR_INVALID_0, 8'h77);
    send_transfer("read_invalid_addr_0", APB_READ, `APB_ADDR_INVALID_0);
    send_transfer("write_invalid_addr_1", APB_WRITE, `APB_ADDR_INVALID_1, 8'h88);
    send_transfer("read_invalid_addr_1", APB_READ, `APB_ADDR_INVALID_1);
  endtask
endclass

class apb_fifo_random_sequence extends apb_fifo_base_sequence;
  `uvm_object_utils(apb_fifo_random_sequence)

  int unsigned num_items = 50;

  function new(string name = "apb_fifo_random_sequence");
    super.new(name);
  endfunction

  virtual task body();
    apb_trans tr;

    for (int i = 0; i < num_items; i++) begin
      tr = apb_trans::type_id::create($sformatf("random_%0d", i));
      start_item(tr);
      if (!tr.randomize()) begin
        `uvm_fatal("RANDFAIL", "Failed to randomize APB transaction")
      end
      finish_item(tr);
    end

    for (int i = 0; i < (`FIFO_DEPTH + 2); i++) begin
      send_transfer($sformatf("random_drain_%0d", i), APB_READ, `APB_ADDR_DATA);
    end

    send_transfer("random_final_status", APB_READ, `APB_ADDR_STATUS);
    send_transfer("random_final_count", APB_READ, `APB_ADDR_COUNT);
  endtask
endclass

class apb_fifo_full_regression_sequence extends apb_fifo_base_sequence;
  `uvm_object_utils(apb_fifo_full_regression_sequence)

  function new(string name = "apb_fifo_full_regression_sequence");
    super.new(name);
  endfunction

  virtual task body();
    apb_fifo_reset_check_sequence    reset_seq;
    apb_fifo_basic_sequence          basic_seq;
    apb_fifo_full_overflow_sequence  full_seq;
    apb_fifo_underflow_sequence      underflow_seq;
    apb_fifo_wrap_sequence           wrap_seq;
    apb_fifo_register_sequence       reg_seq;
    apb_fifo_invalid_addr_sequence   invalid_seq;
    apb_fifo_random_sequence         random_seq;

    reset_seq = apb_fifo_reset_check_sequence::type_id::create("reset_seq");
    reset_seq.start(m_sequencer);

    basic_seq = apb_fifo_basic_sequence::type_id::create("basic_seq");
    basic_seq.start(m_sequencer);

    full_seq = apb_fifo_full_overflow_sequence::type_id::create("full_seq");
    full_seq.start(m_sequencer);

    underflow_seq = apb_fifo_underflow_sequence::type_id::create("underflow_seq");
    underflow_seq.start(m_sequencer);

    wrap_seq = apb_fifo_wrap_sequence::type_id::create("wrap_seq");
    wrap_seq.start(m_sequencer);

    reg_seq = apb_fifo_register_sequence::type_id::create("reg_seq");
    reg_seq.start(m_sequencer);

    invalid_seq = apb_fifo_invalid_addr_sequence::type_id::create("invalid_seq");
    invalid_seq.start(m_sequencer);

    random_seq = apb_fifo_random_sequence::type_id::create("random_seq");
    random_seq.start(m_sequencer);
  endtask
endclass

`endif
