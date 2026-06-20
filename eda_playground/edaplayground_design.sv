`timescale 1ns/1ps

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

module apb_fifo_slave #(
  parameter int AWIDTH = `AWIDTH,
  parameter int DWIDTH = `DWIDTH,
  parameter int DEPTH  = `FIFO_DEPTH
) (
  input  logic                pclk,
  input  logic                presetn,
  input  logic                psel,
  input  logic                penable,
  input  logic                pwrite,
  input  logic [AWIDTH-1:0]   paddr,
  input  logic [DWIDTH-1:0]   pwdata,
  output logic [DWIDTH-1:0]   prdata,
  output logic                pready,
  output logic                pslverr
);

  localparam int PTR_WIDTH   = (DEPTH <= 2) ? 1 : $clog2(DEPTH);
  localparam int COUNT_WIDTH = $clog2(DEPTH + 1);
  localparam logic [PTR_WIDTH-1:0]   LAST_PTR    = DEPTH - 1;
  localparam logic [COUNT_WIDTH-1:0] DEPTH_COUNT = DEPTH;

  logic [DWIDTH-1:0]       fifo_mem [0:DEPTH-1];
  logic [PTR_WIDTH-1:0]    wr_ptr;
  logic [PTR_WIDTH-1:0]    rd_ptr;
  logic [COUNT_WIDTH-1:0]  count;

  wire apb_access = psel && penable;
  wire fifo_empty = (count == '0);
  wire fifo_full  = (count == DEPTH_COUNT);

  always_comb begin
    pready  = 1'b1;
    pslverr = 1'b0;
    prdata  = '0;

    if (apb_access) begin
      case (paddr)
        `APB_ADDR_DATA: begin
          if (pwrite) begin
            pslverr = fifo_full;
          end else begin
            pslverr = fifo_empty;
            prdata  = fifo_empty ? '0 : fifo_mem[rd_ptr];
          end
        end

        `APB_ADDR_STATUS: begin
          pslverr = pwrite;
          prdata  = {{(DWIDTH-2){1'b0}}, fifo_full, fifo_empty};
        end

        `APB_ADDR_COUNT: begin
          pslverr = pwrite;
          prdata  = count;
        end

        default: begin
          pslverr = 1'b1;
        end
      endcase
    end
  end

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;

      for (int i = 0; i < DEPTH; i++) begin
        fifo_mem[i] <= '0;
      end
    end else if (apb_access && (paddr == `APB_ADDR_DATA)) begin
      if (pwrite && !fifo_full) begin
        fifo_mem[wr_ptr] <= pwdata;
        wr_ptr <= (wr_ptr == LAST_PTR) ? '0 : wr_ptr + 1'b1;
        count  <= count + 1'b1;
      end else if (!pwrite && !fifo_empty) begin
        rd_ptr <= (rd_ptr == LAST_PTR) ? '0 : rd_ptr + 1'b1;
        count  <= count - 1'b1;
      end
    end
  end

endmodule
