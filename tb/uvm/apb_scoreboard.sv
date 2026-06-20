`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV

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

`endif
