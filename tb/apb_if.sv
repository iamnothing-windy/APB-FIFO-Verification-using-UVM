`ifndef APB_IF_SV
`define APB_IF_SV

`include "defines.svh"

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

  modport master (
    clocking drv_cb,
    output presetn
  );

  modport monitor (
    clocking mon_cb
  );

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

`endif
