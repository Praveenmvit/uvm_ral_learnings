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

6.  
