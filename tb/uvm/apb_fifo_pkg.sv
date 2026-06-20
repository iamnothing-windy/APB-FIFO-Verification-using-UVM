`ifndef APB_FIFO_PKG_SV
`define APB_FIFO_PKG_SV

package apb_fifo_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "defines.svh"

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

  `include "apb_trans.sv"
  `include "apb_sequence.sv"
  `include "apb_sequencer.sv"
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_scoreboard.sv"
  `include "apb_coverage.sv"
  `include "apb_agent.sv"
  `include "apb_env.sv"
  `include "apb_test.sv"
endpackage

`endif
