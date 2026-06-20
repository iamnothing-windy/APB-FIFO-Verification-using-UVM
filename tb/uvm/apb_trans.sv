`ifndef APB_TRANS_SV
`define APB_TRANS_SV

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

`endif
