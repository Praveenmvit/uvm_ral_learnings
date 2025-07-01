# uvm_ral_learnings
## Need for RAL
The RAL (Register Abstraction Layer) provides a standardized and automated way to describe, access, and verify registers and memories in a DUT — without hardcoding addresses, bitfields, or access types.
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


