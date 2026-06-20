# EDA Playground Run Notes

Use these two paste-ready files on https://edaplayground.com:

1. Paste `edaplayground_design.sv` into the Design pane.
2. Paste `edaplayground_testbench.sv` into the Testbench pane.
3. Select `SystemVerilog/Verilog`.
4. Select a simulator with UVM support, for example `Cadence Xcelium`, `Synopsys VCS`, `Siemens Questa`, or `Aldec Riviera Pro` if available.
5. Enable/select `UVM 1.2` in the libraries/options.
6. Set top module to `top` if EDA Playground asks for it.
7. Run.

Expected result: the log should end without `UVM_ERROR`, and it should print `Scoreboard completed with no mismatches`.

The EDA Playground version runs `apb_fifo_full_regression_test` by default. This includes reset, basic write/read, full/overflow, empty/underflow, wrap-around, read-only register write, invalid address, and random mixed traffic.

This folder is a paste-ready version of the main multi-file repository layout. The verification intent is the same, but files are flattened for EDA Playground convenience. See `../docs/eda_vs_repo_layout.txt` for the detailed comparison.

Do not paste the original multi-file repo layout directly into EDA Playground unless you also add every include file and set the include directories. The paste-ready files above already inline macros and package the UVM testbench in the order EDA Playground expects.

If one simulator gives a license or availability error, switch to another UVM-capable simulator on EDA Playground. Do not select Icarus Verilog for this testbench because it does not support UVM.
