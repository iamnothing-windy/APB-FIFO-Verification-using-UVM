`timescale 1ns/1ps

`include "defines.svh"
`include "uvm_macros.svh"

import uvm_pkg::*;
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
