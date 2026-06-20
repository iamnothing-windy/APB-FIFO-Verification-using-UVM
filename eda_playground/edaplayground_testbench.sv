`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

`ifndef APB_FIFO_FULL_FLOW_DEFINES_SV
`define APB_FIFO_FULL_FLOW_DEFINES_SV
`define AWIDTH      4
`define DWIDTH      8
`define FIFO_DEPTH  8
`define APB_ADDR_DATA       4'h0
`define APB_ADDR_STATUS     4'h4
`define APB_ADDR_COUNT      4'h8
`define APB_ADDR_INVALID_0  4'hc
`define APB_ADDR_INVALID_1  4'hf
`endif

interface apb_if(input logic pclk);
  logic presetn;
  logic                psel;
  logic                penable;
  logic                pwrite;
  logic [`AWIDTH-1:0]  paddr;
  logic [`DWIDTH-1:0]  pwdata;
  logic [`DWIDTH-1:0]  prdata;
  logic                pready;
  logic                pslverr;

  clocking drv_cb @(posedge pclk);
    default input #1step output #1step;
    output psel;
    output penable;
    output pwrite;
    output paddr;
    output pwdata;
    input  prdata;
    input  pready;
    input  pslverr;
  endclocking

  clocking mon_cb @(posedge pclk);
    default input #1step output #1step;
    input presetn;
    input psel;
    input penable;
    input pwrite;
    input paddr;
    input pwdata;
    input prdata;
    input pready;
    input pslverr;
  endclocking

  property penable_requires_psel;
    @(posedge pclk) disable iff (!presetn) penable |-> psel;
  endproperty

  property setup_goes_to_access;
    @(posedge pclk) disable iff (!presetn) (psel && !penable) |=> (psel && penable);
  endproperty

  assert property (penable_requires_psel)
    else $error("APB protocol violation: penable asserted without psel");

  assert property (setup_goes_to_access)
    else $error("APB protocol violation: setup phase did not move to access phase");
endinterface

package apb_fifo_pkg;
  import uvm_pkg::*;

  typedef enum bit {APB_READ = 1'b0, APB_WRITE = 1'b1} apb_cmd_e;
  typedef enum int {
    EV_NORMAL,
    EV_OVERFLOW,
    EV_UNDERFLOW,
    EV_INVALID_ADDR,
    EV_READ_ONLY_WRITE
  } apb_event_e;

  function automatic bit is_data_addr(bit [`AWIDTH-1:0] addr);
    return (addr == `APB_ADDR_DATA);
  endfunction

  function automatic bit is_status_addr(bit [`AWIDTH-1:0] addr);
    return (addr == `APB_ADDR_STATUS);
  endfunction

  function automatic bit is_count_addr(bit [`AWIDTH-1:0] addr);
    return (addr == `APB_ADDR_COUNT);
  endfunction

  function automatic bit is_valid_addr(bit [`AWIDTH-1:0] addr);
    return is_data_addr(addr) || is_status_addr(addr) || is_count_addr(addr);
  endfunction

  class apb_trans extends uvm_sequence_item;
    rand apb_cmd_e          cmd;
    rand bit [`AWIDTH-1:0]  addr;
    rand bit [`DWIDTH-1:0]  data;
    bit [`DWIDTH-1:0]       rdata;
    bit                     slverr;

    constraint addr_dist_c {
      addr dist {
        `APB_ADDR_DATA      := 8,
        `APB_ADDR_STATUS    := 2,
        `APB_ADDR_COUNT     := 2,
        `APB_ADDR_INVALID_0 := 1,
        `APB_ADDR_INVALID_1 := 1
      };
    }

    constraint cmd_dist_c {
      cmd dist {APB_READ := 5, APB_WRITE := 5};
    }

    `uvm_object_utils_begin(apb_trans)
      `uvm_field_enum(apb_cmd_e, cmd, UVM_DEFAULT)
      `uvm_field_int(addr, UVM_DEFAULT | UVM_HEX)
      `uvm_field_int(data, UVM_DEFAULT | UVM_HEX)
      `uvm_field_int(rdata, UVM_DEFAULT | UVM_HEX)
      `uvm_field_int(slverr, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "apb_trans");
      super.new(name);
    endfunction

    function string convert2string();
      return $sformatf("cmd=%s addr=0x%0h data=0x%0h rdata=0x%0h slverr=%0b",
                       (cmd == APB_WRITE) ? "WRITE" : "READ", addr, data, rdata, slverr);
    endfunction
  endclass

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

  class apb_sequencer extends uvm_sequencer #(apb_trans);
    `uvm_component_utils(apb_sequencer)

    function new(string name = "apb_sequencer", uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  class apb_driver extends uvm_driver #(apb_trans);
    `uvm_component_utils(apb_driver)

    virtual apb_if vif;

    function new(string name = "apb_driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("NOVIF", "virtual interface must be set for apb_driver")
      end
    endfunction

    virtual task run_phase(uvm_phase phase);
      reset_bus();

      forever begin
        seq_item_port.get_next_item(req);
        drive_transfer(req);
        seq_item_port.item_done();
      end
    endtask

    protected task reset_bus();
      vif.presetn <= 1'b0;
      vif.drv_cb.psel    <= 1'b0;
      vif.drv_cb.penable <= 1'b0;
      vif.drv_cb.pwrite  <= 1'b0;
      vif.drv_cb.paddr   <= '0;
      vif.drv_cb.pwdata  <= '0;

      repeat (3) @(vif.drv_cb);
      vif.presetn <= 1'b1;
      repeat (2) @(vif.drv_cb);
    endtask

    protected task drive_transfer(apb_trans tr);
      @(vif.drv_cb);
      vif.drv_cb.psel    <= 1'b1;
      vif.drv_cb.penable <= 1'b0;
      vif.drv_cb.pwrite  <= (tr.cmd == APB_WRITE);
      vif.drv_cb.paddr   <= tr.addr;
      vif.drv_cb.pwdata  <= tr.data;

      @(vif.drv_cb);
      vif.drv_cb.penable <= 1'b1;

      do begin
        @(vif.drv_cb);
      end while (!vif.drv_cb.pready);

      tr.rdata  = vif.drv_cb.prdata;
      tr.slverr = vif.drv_cb.pslverr;

      vif.drv_cb.psel    <= 1'b0;
      vif.drv_cb.penable <= 1'b0;
      vif.drv_cb.pwrite  <= 1'b0;
      vif.drv_cb.paddr   <= '0;
      vif.drv_cb.pwdata  <= '0;

      `uvm_info("APB_DRV", {"Drove ", tr.convert2string()}, UVM_MEDIUM)
    endtask
  endclass

  class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_if vif;
    uvm_analysis_port #(apb_trans) ap;

    function new(string name = "apb_monitor", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ap = new("ap", this);

      if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("NOVIF", "virtual interface must be set for apb_monitor")
      end
    endfunction

    virtual task run_phase(uvm_phase phase);
      apb_trans tr;

      forever begin
        @(vif.mon_cb);

        if (!vif.mon_cb.presetn) begin
          continue;
        end

        if (vif.mon_cb.psel && vif.mon_cb.penable && vif.mon_cb.pready) begin
          tr = apb_trans::type_id::create("tr", this);
          tr.cmd    = vif.mon_cb.pwrite ? APB_WRITE : APB_READ;
          tr.addr   = vif.mon_cb.paddr;
          tr.data   = vif.mon_cb.pwdata;
          tr.rdata  = vif.mon_cb.prdata;
          tr.slverr = vif.mon_cb.pslverr;

          ap.write(tr);
          `uvm_info("APB_MON", {"Observed ", tr.convert2string()}, UVM_MEDIUM)
        end
      end
    endtask
  endclass

  class apb_scoreboard extends uvm_component;
    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(apb_trans, apb_scoreboard) analysis_export;
    bit [`DWIDTH-1:0] expected_fifo[$];
    int unsigned error_count;

    function new(string name = "apb_scoreboard", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      analysis_export = new("analysis_export", this);
    endfunction

    virtual function void write(apb_trans tr);
      bit [`DWIDTH-1:0] expected_data;
      bit [`DWIDTH-1:0] expected_status;

      if (tr.cmd == APB_WRITE) begin
        if (is_data_addr(tr.addr)) begin
          if (expected_fifo.size() >= `FIFO_DEPTH) begin
            expect_error(tr, "write DATA when FIFO is full");
          end else begin
            expect_no_error(tr, "write DATA");
            expected_fifo.push_back(tr.data);
          end
        end else if (is_status_addr(tr.addr) || is_count_addr(tr.addr)) begin
          expect_error(tr, "write read-only register");
        end else begin
          expect_error(tr, "write invalid address");
        end
      end else begin
        if (is_data_addr(tr.addr)) begin
          if (expected_fifo.size() == 0) begin
            expect_error(tr, "read DATA when FIFO is empty");
            if (tr.rdata !== '0) begin
              record_error($sformatf("Underflow read data mismatch: expected 0x0 got 0x%0h", tr.rdata));
            end
          end else begin
            expected_data = expected_fifo.pop_front();
            expect_no_error(tr, "read DATA");
            if (!tr.slverr && (tr.rdata !== expected_data)) begin
              record_error($sformatf("FIFO data mismatch: expected 0x%0h got 0x%0h", expected_data, tr.rdata));
            end
          end
        end else if (is_status_addr(tr.addr)) begin
          expected_status = '0;
          expected_status[0] = (expected_fifo.size() == 0);
          expected_status[1] = (expected_fifo.size() >= `FIFO_DEPTH);
          expect_no_error(tr, "read STATUS");
          if (!tr.slverr && (tr.rdata !== expected_status)) begin
            record_error($sformatf("STATUS mismatch: expected 0x%0h got 0x%0h", expected_status, tr.rdata));
          end
        end else if (is_count_addr(tr.addr)) begin
          expected_data = expected_fifo.size();
          expect_no_error(tr, "read COUNT");
          if (!tr.slverr && (tr.rdata !== expected_data)) begin
            record_error($sformatf("COUNT mismatch: expected 0x%0h got 0x%0h", expected_data, tr.rdata));
          end
        end else begin
          expect_error(tr, "read invalid address");
          if (tr.rdata !== '0) begin
            record_error($sformatf("Invalid address read data mismatch: expected 0x0 got 0x%0h", tr.rdata));
          end
        end
      end
    endfunction

    virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);

      if (error_count == 0) begin
        `uvm_info("APB_SB", "Scoreboard completed with no mismatches", UVM_LOW)
      end else begin
        `uvm_error("APB_SB", $sformatf("Scoreboard detected %0d mismatches", error_count))
      end
    endfunction

    protected function void expect_error(apb_trans tr, string ctx);
      if (!tr.slverr) begin
        record_error($sformatf("Expected PSLVERR for %s: %s", ctx, tr.convert2string()));
      end
    endfunction

    protected function void expect_no_error(apb_trans tr, string ctx);
      if (tr.slverr) begin
        record_error($sformatf("Unexpected PSLVERR for %s: %s", ctx, tr.convert2string()));
      end
    endfunction

    protected function void record_error(string msg);
      error_count++;
      `uvm_error("APB_SB", msg)
    endfunction
  endclass

  class apb_coverage extends uvm_subscriber #(apb_trans);
    `uvm_component_utils(apb_coverage)

    apb_cmd_e sampled_cmd;
    bit [`AWIDTH-1:0] sampled_addr;
    bit sampled_slverr;
    int unsigned sampled_count;
    apb_event_e sampled_event;
    int unsigned model_count;

    covergroup apb_cg;
      option.per_instance = 1;

      cmd_cp: coverpoint sampled_cmd {
        bins read  = {APB_READ};
        bins write = {APB_WRITE};
      }

      addr_cp: coverpoint sampled_addr {
        bins data    = {`APB_ADDR_DATA};
        bins status  = {`APB_ADDR_STATUS};
        bins count   = {`APB_ADDR_COUNT};
        bins invalid = default;
      }

      slverr_cp: coverpoint sampled_slverr {
        bins no_error = {0};
        bins error    = {1};
      }

      count_cp: coverpoint sampled_count {
        bins empty   = {0};
        bins partial = {[1:(`FIFO_DEPTH-1)]};
        bins full    = {`FIFO_DEPTH};
      }

      event_cp: coverpoint sampled_event {
        bins normal          = {EV_NORMAL};
        bins overflow        = {EV_OVERFLOW};
        bins underflow       = {EV_UNDERFLOW};
        bins invalid_addr    = {EV_INVALID_ADDR};
        bins read_only_write = {EV_READ_ONLY_WRITE};
      }

      cmd_addr_cross: cross cmd_cp, addr_cp;
      error_event_cross: cross slverr_cp, event_cp;
    endgroup

    function new(string name = "apb_coverage", uvm_component parent = null);
      super.new(name, parent);
      apb_cg = new();
    endfunction

    virtual function void write(apb_trans t);
      sampled_cmd    = t.cmd;
      sampled_addr   = t.addr;
      sampled_slverr = t.slverr;
      sampled_event  = classify_event(t);

      if (is_data_addr(t.addr) && !t.slverr) begin
        if (t.cmd == APB_WRITE && model_count < `FIFO_DEPTH) begin
          model_count++;
        end else if (t.cmd == APB_READ && model_count > 0) begin
          model_count--;
        end
      end

      sampled_count = model_count;
      apb_cg.sample();
    endfunction

    protected function apb_event_e classify_event(apb_trans t);
      if (!is_valid_addr(t.addr)) begin
        return EV_INVALID_ADDR;
      end

      if (t.cmd == APB_WRITE && (is_status_addr(t.addr) || is_count_addr(t.addr))) begin
        return EV_READ_ONLY_WRITE;
      end

      if (is_data_addr(t.addr) && t.cmd == APB_WRITE && t.slverr) begin
        return EV_OVERFLOW;
      end

      if (is_data_addr(t.addr) && t.cmd == APB_READ && t.slverr) begin
        return EV_UNDERFLOW;
      end

      return EV_NORMAL;
    endfunction
  endclass

  class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_sequencer sequencer;
    apb_driver    driver;
    apb_monitor   monitor;

    function new(string name = "apb_agent", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active)) begin
        is_active = UVM_ACTIVE;
      end

      monitor = apb_monitor::type_id::create("monitor", this);

      if (is_active == UVM_ACTIVE) begin
        sequencer = apb_sequencer::type_id::create("sequencer", this);
        driver    = apb_driver::type_id::create("driver", this);
      end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      if (is_active == UVM_ACTIVE) begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
      end
    endfunction
  endclass

  class apb_env extends uvm_env;
    `uvm_component_utils(apb_env)

    apb_agent      agent;
    apb_scoreboard scoreboard;
    apb_coverage   coverage;

    function new(string name = "apb_env", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent      = apb_agent::type_id::create("agent", this);
      scoreboard = apb_scoreboard::type_id::create("scoreboard", this);
      coverage   = apb_coverage::type_id::create("coverage", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.monitor.ap.connect(scoreboard.analysis_export);
      agent.monitor.ap.connect(coverage.analysis_export);
    endfunction
  endclass

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
endpackage

import apb_fifo_pkg::*;

module top;
  logic pclk = 1'b0;

  always #5 pclk = ~pclk;

  apb_if apb_vif(pclk);

  apb_fifo_slave dut (
    .pclk    (pclk),
    .presetn (apb_vif.presetn),
    .psel    (apb_vif.psel),
    .penable (apb_vif.penable),
    .pwrite  (apb_vif.pwrite),
    .paddr   (apb_vif.paddr),
    .pwdata  (apb_vif.pwdata),
    .prdata  (apb_vif.prdata),
    .pready  (apb_vif.pready),
    .pslverr (apb_vif.pslverr)
  );

  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "vif", apb_vif);

    if ($test$plusargs("UVM_TESTNAME")) begin
      run_test();
    end else begin
      run_test("apb_fifo_full_regression_test");
    end
  end

  initial begin
    #20000;
    `uvm_fatal("TIMEOUT", "Simulation timed out")
  end
endmodule
