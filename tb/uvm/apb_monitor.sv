`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

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

`endif
