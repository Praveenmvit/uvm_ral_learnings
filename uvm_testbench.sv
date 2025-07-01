// Code your testbench here
// or browse Examples

`include "uvm_macros.svh"
import uvm_pkg::*;
interface in(input clk);
  logic [31:0] data;
  logic [1:0] register_field_sel;
  logic register_sel;
  logic read_write;
  logic enable;
endinterface

class packet extends uvm_sequence_item;
  
  rand bit[31:0] data;
  rand bit [1:0] register_field_sel;
  rand bit register_sel;
  rand bit read_write;
  
  
  constraint c {
    data inside {[200:300]};
    register_sel dist {0:=2,1:=1};             
  }
  
  `uvm_object_utils_begin(packet)
  `uvm_field_int(data,UVM_ALL_ON)
  `uvm_field_int(register_field_sel,UVM_ALL_ON)
  `uvm_field_int(register_sel,UVM_ALL_ON)
  `uvm_field_int(read_write,UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name="packet");
    super.new(name);
  endfunction
  
endclass


class register_control extends uvm_reg;
  
  `uvm_object_utils(register_control)
  
  rand uvm_reg_field mode_en;
  rand uvm_reg_field dbg_en;
  rand uvm_reg_field parity_en;
  rand uvm_reg_field ctrl_en;  
  
  function new(string name="register_control");
    super.new(name,32,build_coverage(UVM_NO_COVERAGE));
  endfunction
  
  function void build();
    mode_en = uvm_reg_field::type_id::create("mode_en");
    dbg_en = uvm_reg_field::type_id::create("dbg_en");
    parity_en = uvm_reg_field::type_id::create("parity_en");
    ctrl_en = uvm_reg_field::type_id::create("ctrl_en");
    
    mode_en.configure(this,1,0,"RW",0,'h5,1,1,1); // (parent,size,lsb_pos,access,volatile,reset_value"HARD KIND",has_reset,rand,individually accessible)
    dbg_en.configure(this,1,1,"RW",0,'h6,1,1,1);
    parity_en.configure(this,1,2,"RW",0,'h7,1,1,1);
    ctrl_en.configure(this,29,3,"RW",0,'h8,1,1,1); 
    
  endfunction
  
endclass

class register_debug extends uvm_reg;
  `uvm_object_utils(register_debug)
  
  rand uvm_reg_field debug;
  
  function new(string name= "register_debug");
    super.new(name,32,build_coverage(UVM_NO_COVERAGE));
  endfunction
  
  function void build();
    debug = uvm_reg_field::type_id::create("debug");
    debug.configure(this,32,0,"RW",0,'h9,1,1,0);
  endfunction
  
endclass

class register_model extends uvm_reg_block;
  
  `uvm_object_utils(register_model)
  
  register_control reg_ctrl;
  register_debug reg_dbg;
  
  function new(string name="register_model");
    super.new(name);
  endfunction
  
  function void build();
    reg_ctrl = register_control::type_id::create("reg_ctrl");
    reg_dbg = register_debug::type_id::create("reg_dbg");
    
    reg_ctrl.build();
    reg_ctrl.configure(this,null,"");
    reg_dbg.build();
    reg_dbg.configure(this,null,"debug");
    reg_ctrl.add_hdl_path_slice("mode_en",0,1);
    reg_ctrl.add_hdl_path_slice("dbg_en",1,1);
    reg_ctrl.add_hdl_path_slice("parity_en",2,1);
    reg_ctrl.add_hdl_path_slice("ctrl_en",3,29);
    reg_ctrl.set_reset(32'h1,"SOFT");
    reg_dbg.set_reset(32'h2,"SOFT");
    
    this.default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 1);
   
    this.default_map.add_reg(reg_ctrl,`UVM_REG_ADDR_WIDTH'h0,"RW");
    this.default_map.add_reg(reg_dbg,`UVM_REG_ADDR_WIDTH'h4,"RW");
    
    add_hdl_path("tb.dut");
   
  endfunction
  
endclass


class driver extends uvm_driver#(packet);
  
  `uvm_component_utils(driver)
  virtual in vif;
  
  packet pkt;
  
  function new(string name="driver",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    uvm_config_db#(virtual in)::get(this,"","vif",vif);
  endfunction
  
  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(pkt);
        @(posedge vif.clk);
        vif.enable = 1;
        vif.register_field_sel = pkt.register_field_sel;
        vif.register_sel = pkt.register_sel;
        vif.read_write = pkt.read_write;
        //pkt.print();

        if(pkt.read_write == 1) begin
          vif.data = pkt.data;
        end

          @(negedge vif.clk); // for sampling the data line of vif at negedge.
          vif.enable = 0;

        if(pkt.read_write == 0) begin
          pkt.data = vif.data;
        end
        seq_item_port.item_done(); // adapter will be called after this.

    end
        
  endtask
  
endclass

class seq extends uvm_sequence;
    
  `uvm_object_utils(seq)
  packet pkt;
  packet pkt1;
  
  function new(string name="seq");
    super.new(name);
  endfunction
  
  task body();
    pkt = packet::type_id::create("packet");
    
    for(int i=0;i<3;i++) begin
      start_item(pkt); // for handshake
      pkt.randomize() with {read_write == 1;}; // using sequence only to write.
      
      finish_item(pkt);
    end
    
  endtask
  
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  
  packet pkt;
  uvm_analysis_port#(packet) port;
  virtual in vif;
  
  function new(string name="monitor",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    port = new("monitor_port",this);
    uvm_config_db#(virtual in)::get(this,"","vif",vif);
  endfunction
  
  task run_phase(uvm_phase phase);
    forever
     begin
      pkt = packet::type_id::create("pkt_port");
      
      @(negedge vif.enable);
      
      pkt.register_field_sel = vif.register_field_sel;
      pkt.register_sel = vif.register_sel;
      pkt.read_write = vif.read_write;
       
      pkt.data = vif.data;
      
      port.write(pkt);
      
    end
    
  endtask
  
endclass

class my_adapter extends uvm_reg_adapter;
  
  `uvm_object_utils(my_adapter)
  
  function new(string name="my_adapter");
    super.new(name);
  endfunction
  
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    packet pkt = packet::type_id::create("adapter_packte");
    
    pkt.read_write = (rw.kind == UVM_WRITE) ? 1: 0;
    if(rw.addr == 'h0) begin
      pkt.register_sel = 0;
    end
    else 
      pkt.register_sel = 1;
    pkt.data  = rw.data;
    `uvm_info ("adapter", $sformatf ("reg2bus addr=0x%0h data=0x%0h kind=%s", pkt.register_sel, pkt.data, rw.kind.name), UVM_HIGH)
    return pkt;
  endfunction
  
  virtual function void bus2reg (uvm_sequence_item bus_item,ref uvm_reg_bus_op rw);
    packet pkt;
    $cast(pkt,bus_item);
     rw.kind = pkt.read_write ? UVM_WRITE : UVM_READ;
    if(pkt.register_sel == 0) begin
      rw.addr = 'h0;
    end
    else 
      rw.addr = 'h4; // register address map.
    
     rw.data = pkt.data;
      `uvm_info ("adapter", $sformatf("bus2reg : addr=0x%0h data=0x%0h kind=%s status=%s", rw.addr, rw.data, rw.kind.name(), rw.status.name()), UVM_HIGH)
   endfunction

endclass

class my_agent extends uvm_agent;
  
  `uvm_component_utils(my_agent)
  
  uvm_sequencer#(packet) my_seqr;
  driver my_dri;
  monitor my_mon;
  
  function new(string name="my_agent",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    my_seqr = uvm_sequencer#(packet)::type_id::create("my_seqr",this);
    my_dri = driver::type_id::create("driv",this);
    my_mon = monitor::type_id::create("my_mon",this);
    
  endfunction
  
  function void connect_phase(uvm_phase phase);
    my_dri.seq_item_port.connect(my_seqr.seq_item_export);
  endfunction
  
endclass

class register_environment extends uvm_env;
  
  `uvm_component_utils(register_environment)
  register_model model;
  my_agent agt;
  uvm_reg_predictor#(packet) predictor;
  my_adapter adapter;
  
  function new(string name="register_environment", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    model=register_model::type_id::create("register_mod",this);
    agt = my_agent::type_id::create("agt",this);
    adapter = my_adapter::type_id::create("adapt");
    
    predictor= uvm_reg_predictor#(packet)::type_id::create("predict",this); // explicit predictor
    
    model.build();
    
    model.lock_model();
    model.print();
    
  endfunction
  
  function void connect_phase(uvm_phase phase);
    predictor.map = model.default_map;
    predictor.adapter = adapter;
    //agt.my_mon.port.connect(predictor.bus_in); 
    // NO need for predictor and monitor in this scenario. as during the read and write bus2reg will be called twice one for monitor and another for seqr connection with adapter in map.
    // As below adapters seqr, adapter connect to address map.
    model.default_map.set_sequencer(agt.my_seqr,this.adapter);
  endfunction
  
endclass



class test extends uvm_test;
  
  `uvm_component_utils(test)
  seq my_seq;
  register_environment env;
  uvm_status_e status;
  uvm_reg_data_t mirrored_data;
  uvm_reg_data_t desired_data;
  uvm_reg_data_t dut_data;
  
  function new(string name="test",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    env= register_environment::type_id::create("env",this);
  endfunction
  
  task main_phase(uvm_phase phase);
    my_seq= seq::type_id::create("my_sequence");
    phase.raise_objection(this);
    
    my_seq.start(env.agt.my_seqr);
    phase.drop_objection(this);
  endtask
  
  task shutdown_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    #10;
    mirrored_data = env.model.reg_dbg.get_mirrored_value();
    `uvm_info("in test",$sformatf("get mirrored value of reg debug after sequence write :%0h",mirrored_data),UVM_MEDIUM)
    
    env.model.reg_dbg.read(status,dut_data,UVM_FRONTDOOR);
    `uvm_info("in test",$sformatf("read dut_data from reg dbg:%0h",dut_data),UVM_MEDIUM)    
    
    env.model.reg_dbg.write(status,32'h001123aa,.path(UVM_BACKDOOR));
    `uvm_info("in test",$sformatf("writing into the register dbg status  :%s",status.name()),UVM_MEDIUM) // backdoor write.
    
    
    
    mirrored_data = env.model.reg_dbg.get_mirrored_value();
    `uvm_info("in test",$sformatf("get mirrored value after backdoor writing into reg debug register :%0h",mirrored_data),UVM_MEDIUM)
    
    //***********************************************************************
    
    env.model.reg_dbg.predict(32'h001103aa); // update d.v and mi.value.
    
     mirrored_data = env.model.reg_dbg.get_mirrored_value();
    `uvm_info("in test",$sformatf("get mirrored value after predict into reg dbg register :%0h",mirrored_data),UVM_MEDIUM)
    
    env.model.reg_dbg.mirror(status,UVM_CHECK,UVM_FRONTDOOR);
    `uvm_info("in test",$sformatf("mirror register with check enabled -reg dbg:%s",status.name()),UVM_MEDIUM) // if d.v != design reg value error come. update dv and mv.
    
    mirrored_data = env.model.reg_dbg.get_mirrored_value();
    `uvm_info("in test",$sformatf("get mirrored value after mirror :%0h",mirrored_data),UVM_MEDIUM)
    
    //************************************************************************
    
    // reg  ctrl
    
    mirrored_data = env.model.reg_ctrl.get_mirrored_value();
    `uvm_info("in test",$sformatf("get mirrored value after sequence write reg ctrl :%0h",mirrored_data),UVM_MEDIUM)
    env.model.reg_ctrl.read(status,dut_data,UVM_FRONTDOOR);
    `uvm_info("in test",$sformatf("read dut_data from reg ctrl:%0h",dut_data),UVM_MEDIUM)    
    
    //********************************************************************
    
    // register field writes.
    
    mirrored_data = env.model.reg_ctrl.ctrl_en.get_mirrored_value();
    `uvm_info("in test",$sformatf("get mirrored value after sequence write reg ctrl.ctrl en field:%0h",mirrored_data),UVM_MEDIUM) // 0 as the register fields have separate mirrored value fields.
    env.model.reg_ctrl.ctrl_en.read(status,dut_data,UVM_FRONTDOOR);
    `uvm_info("in test",$sformatf("read dut_data from reg ctrl field register:%0h",dut_data),UVM_MEDIUM)    
    
     mirrored_data = env.model.reg_ctrl.get_mirrored_value();
    `uvm_info("in test",$sformatf("get mirrored value after sequence write reg ctrl :%0h",mirrored_data),UVM_MEDIUM) // mirrored value of field updated after any operation happens on the register field. not register.
    
    //*******************************************************************
    
      
    env.model.reg_ctrl.ctrl_en.poke(status,29'd37); // accesing individual register fields through poke backdoor.
    `uvm_info("in test",$sformatf("writing into the register dbg status  :%s",status.name()),UVM_MEDIUM) 
    
    env.model.reg_ctrl.read(status,dut_data,UVM_FRONTDOOR);
    `uvm_info("in test",$sformatf("read dut_data from reg ctrl:%0h",dut_data),UVM_MEDIUM)
    
    
    //*********************************************************************
    
    env.model.reg_ctrl.reset("HARD"); // will update dv and mv of registers.
    
    desired_data = env.model.reg_ctrl.get();
    `uvm_info("in test",$sformatf("get desired value after reset :%0b",desired_data),UVM_MEDIUM)
       
    env.model.reg_ctrl.set(32'h11); // set desired value
    env.model.reg_ctrl.update(status,UVM_FRONTDOOR); // if d.v != mi.value update design register with desired value.
    env.model.reg_ctrl.read(status,dut_data,UVM_FRONTDOOR);
    `uvm_info("in test",$sformatf("read dut_data from reg ctrl after update:%0h",dut_data),UVM_MEDIUM)
    
    mirrored_data = env.model.reg_dbg.get_mirrored_value();
    `uvm_info("in test",$sformatf("get mirrored value before poke :%0h",mirrored_data),UVM_MEDIUM)
    
    //*************************************************************************
    
    env.model.reg_dbg.poke(status,32'h12); // use backdoor access if hdl path is provided or front door. poke changes the dv and mv values of registers
    
    mirrored_data = env.model.reg_dbg.get_mirrored_value();
    `uvm_info("in test",$sformatf("get mirrored value after poke :%0h",mirrored_data),UVM_MEDIUM)
    
    
    #20;
    $display("praveen %0h",tb.dut.debug);
    phase.drop_objection(this);
  endtask
  
endclass

module tb;
  
  bit clk;
  
  always #5 clk=~clk;
  
  in vif(clk);
  register dut(vif);
  
  initial 
    begin
      uvm_config_db#(virtual in)::set(null,"*","vif",vif);
      
      run_test("test");
      
    end
  
  initial
    begin
      $dumpfile("dump.vcd");
      $dumpvars;
    end
endmodule
  
  
