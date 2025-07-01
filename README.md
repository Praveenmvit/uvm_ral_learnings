# uvm_ral_learnings
edaplayground link: https://www.edaplayground.com/x/HHTY  
## Need for RAL
The RAL (Register Abstraction Layer) provides a standardized and automated way to describe, access, and verify registers and memories in a DUT — without hardcoding addresses, bitfields, or access types. 
## Created simple RAL for understanding
The below register setup is modelled using the UVM RAL in testbench and few ral function are tested on the register to get the knowledge about how it will work.
<div align="center">
  <image src = "https://github.com/user-attachments/assets/97cca516-148c-4496-828d-bc1e6fa391a8">  
</div> 
<p align="center">
    Register model in design for which we going to construct RAL
</p> 

## RAL Structure
1.  Create a uvm register(uvm_reg) containing uvm_register fields.
2.  For that create uvm_reg class, declare uvm_register fields in it.
3.  create and configure the uvm register fields.
4.  function void configure(
        uvm_reg parent,  
        int unsigned size, // Size of the uvm field.   
        int unsigned lsb_pos, // least significant bit of the register where register field start  
        string access,  // "RW","RO",etc.,  
        bit volatile,  
        uvm_reg_data_t reset,  
        bit has_reset,  
        bit is_rand,  
        bit individually_accessible  
    )  

5.  So, we need two register containing its respective register fields.
6.  After we need register block(uvm_reg_block) that mimics all the register, memories in dut.
7.  The created register should be added in register map.
8.  Two important things in constructing RAL model is adapter and predictor.
9.  Adapter that consist of reg2bus and bus2reg converting function. which are used to snoop the interface and update the RAL, when the register write or read happening through the interface.
10.  Predictor that will be connected through the monitor, which will monitor and send the transaction to predictor through analysis port.
11.  Predictor will have the handle of the adapter and register map.
12.  We can also set the sequencer in reg map, that send transaction to the design.
13.  whenever transaction happens through the sequencer, the RAL MODEL will be updated.
<div align="center">
  <image src = "https://github.com/user-attachments/assets/4f9a3d26-b9fc-4225-9d80-76ec26f2179e">  
</div> 
<p align="center">
    Explicit predictor
</p> 

## Working and Useful function
<div align="center">
  <image src = "https://github.com/user-attachments/assets/cfaf9f5c-8eab-4339-95bc-fc90e62212b0">  
</div>

1.  We can read and write into the design register in two ways.
-  UVM FRONTDOOR
-  UVM BACKDOOR
  
2.  UVM FRONTDOOR - Takes simulation cycles.
3.  UVM BACKDOOR - Does not take. it will read/write into registers through HDL path directly.
4.  ALL the register and register fields will have 2 values in RAL **Desired and mirrored value.**
5.  The desired values in UVM RAL is the value, what we need to be there in design registers.
6.  **set(value)** - set desired value field of register or reg fields.
7.  **write and read(status,value,access)** - write and read into design, this will update both DV AND MV.
8.  **get_mirrored_value() and get()** - to see mirrored and desired values of registers.
9.  **mirror(status,UVM_CHECK,access);** - Compare mirrored vs DUT value, log error on mismatch.
10.  **reset("HARD"OR"SOFT)** - reset DV and MV of register to reset values of registers.
11.  **update(status,access)** - if d.v != m.v update design register with desired value.
12.  **poke(status,data)** - Use backdoor access if hdl path is provided or front door. poke changes the dv and mv values of registers.(mostly backdoor).
13.  **peek(status,data)** - read data from design register.
14.  **predict()** - update mirrored and desired values.


