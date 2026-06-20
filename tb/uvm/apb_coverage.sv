`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

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

`endif
