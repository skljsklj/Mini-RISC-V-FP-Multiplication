Small RISC‑V core with IEEE‑754 single‑precision multiply. Includes minimal IMEM/DMEM, a self‑contained testbench, and Vivado scripts to run simulation with waveforms.
To run simulation simply run file run_sim.cmd (Windows) and at the bottom of waveforms you'll see multiplication of 2 signals (rose color) and their result.

Note: rv_imem.v initializes a tiny program that loads 2.0f and 3.0f from DMEM, executes FMUL.S, and stores 6.0f to address 0x1008
