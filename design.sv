// Code your design here
module register(in inf);
  
  reg mode_en,dbg_en,parity_en;
  reg [28:0] ctrl_en;
  reg [31:0] debug;
  
  always @(inf.clk) begin
    
    if(inf.read_write == 1) begin  // for write.
    case(inf.register_sel) 
      0: begin
        {ctrl_en,parity_en,dbg_en,mode_en} = inf.data;
      end
      
      1: begin
        debug = inf.data;
      end
      
    endcase
    end
    else begin
      case(inf.register_sel)  // for read.
      0: inf.data = {ctrl_en,parity_en,dbg_en,mode_en};   
      1: inf.data = debug;
      endcase
    end
              
  end
  
  
endmodule
        
