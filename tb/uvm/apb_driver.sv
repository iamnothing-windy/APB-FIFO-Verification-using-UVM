`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

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

    tr.rdata = vif.drv_cb.prdata;
    tr.slverr = vif.drv_cb.pslverr;

    vif.drv_cb.psel    <= 1'b0;
    vif.drv_cb.penable <= 1'b0;
    vif.drv_cb.pwrite  <= 1'b0;
    vif.drv_cb.paddr   <= '0;
    vif.drv_cb.pwdata  <= '0;

    `uvm_info("APB_DRV", {"Drove ", tr.convert2string()}, UVM_MEDIUM)
  endtask
endclass

`endif
