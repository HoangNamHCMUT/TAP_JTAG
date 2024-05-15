`include "/home/ftv_training/SFD/4_Intern/2024_Mar/tuan_huynh/verilog_introduction/verilog/parameters.vh"
module TAP
(
  input            TCK,
  input            TRST_n,
  input            TDI_agent_tap,
  input            TMS_agent_tap,
  output reg         RorW_tap_ahb,
  output reg         RorW_tap_apb,
  output reg         TRANSFER_tap_ahb,
  output reg           TRANSFER_tap_apb,
  output reg [`ADDR_WIDTH-1:0] ADDR_tap_ahb,
  output reg [`ADDR_WIDTH-1:0] ADDR_tap_apb,
  output reg [`DATA_WIDTH-1:0] DATA_tap_ahb,
  output reg [`DATA_WIDTH-1:0] DATA_tap_apb,
  input [`DATA_WIDTH-1:0]      DATA_ahb_tap,
  input [`DATA_WIDTH-1:0]      DATA_apb_tap,
  input [`ERR_WIDTH-1:0]       FAIL_ahb_tap,
  input [`ERR_WIDTH-1:0]       FAIL_apb_tap,
  input            DONE_ahb_tap,
  input            DONE_apb_tap,
  output reg         TDO_tap_agent
);
  reg [`IR_WIDTH-1:0] ir_shift_reg;
  reg [`IR_WIDTH-1:0] ir_hold_reg;
  reg [`DATA_WIDTH-1:0] dr_shift_reg;
  reg [`DATA_WIDTH-1:0] dr_hold_reg;
  reg [`DATA_WIDTH-1:0] DATA_ahb_tap_tmp;
  reg [`DATA_WIDTH-1:0] DATA_apb_tap_tmp;
  reg [3:0] state;
  reg [`ERR_WIDTH-1:0] FAIL_ahb_tap_tmp;
  reg [`ERR_WIDTH-1:0] FAIL_apb_tap_tmp;
  reg DONE_ahb_tap_tmp;
  reg  DONE_apb_tap_tmp;

  reg [`IR_WIDTH-1:0] ir_hold_reg_tmp;
  reg [`IR_WIDTH-1:0] ir_shift_reg_tmp;
  reg [`DATA_WIDTH-1:0] dr_hold_reg_tmp;
  reg [`DATA_WIDTH-1:0] dr_shift_reg_tmp;

  reg TRANSFER_tap_ahb_tmp;
  reg RorW_tap_ahb_tmp;
  reg [`ADDR_WIDTH-1:0] ADDR_tap_ahb_tmp;
  reg [`DATA_WIDTH-1:0] DATA_tap_ahb_tmp;

  reg TRANSFER_tap_apb_tmp;
  reg RorW_tap_apb_tmp;
  reg [`ADDR_WIDTH-1:0] ADDR_tap_apb_tmp;
  reg [`DATA_WIDTH-1:0] DATA_tap_apb_tmp;

  reg TDO_ir;
  reg TDO_dr;
  reg[`DATA_WIDTH-1:0] TDO_tap_agent_dr;
  reg[`IR_WIDTH-1:0] TDO_tap_agent_ir;
  reg TDO_tap_agent_tmp;

  wire ir_update;
  wire ir_capture;
  wire ir_shift;
  wire dr_update;
  wire dr_capture;
  wire dr_shift;
  wire idle;
  wire reset;

 // wire write_stt;
 // wire read_stt;
 // wire read_data;
  wire ahb_read;
  wire ahb_write_addr;
  wire ahb_write_data;
  wire apb_read;
  wire apb_write_addr;
  wire apb_write_data;

  reg done_ahb_tap_w;
  reg [`ERR_WIDTH-1:0] fail_ahb_tap_w;
  reg [`DATA_WIDTH-1:0] data_ahb_tap_w;
  reg done_apb_tap_w;
  reg [`ERR_WIDTH-1:0] fail_apb_tap_w;
  reg [`DATA_WIDTH-1:0] data_apb_tap_w;

  wire [`DATA_WIDTH-1:0] data_captured;

  TAP_Controller FSM ( .TCK(TCK),
             .TRST_n(TRST_n),
           .TMS_agent_tap(TMS_agent_tap),
           .state_out(state)
         );

  assign ir_capture = (state == `IR_CAPTURE);
  assign ir_update = (state == `IR_UPDATE);
  assign ir_shift = (state == `IR_SHIFT);
  assign dr_capture = (state == `DR_CAPTURE);
  assign dr_update = (state == `DR_UPDATE);
  assign dr_shift = (state == `DR_SHIFT);
//  assign idle = (state == `IDLE);
 // assign reset = (state == `RESET);

  //assign write_stt = (ir_hold_reg == `WRITE_STT);
  //assign read_stt = (ir_hold_reg == `READ_STT);
  //assign read_data = (ir_hold_reg ==`READ_DATA);
  assign ahb_read = (ir_hold_reg == `AHB_READ);
  assign ahb_write_addr = (ir_hold_reg == `AHB_WRITE_ADDR);
  assign ahb_write_data = (ir_hold_reg == `AHB_WRITE_DATA);
  assign apb_read = (ir_hold_reg == `APB_READ);
  assign apb_write_addr = (ir_hold_reg == `APB_WRITE_ADDR);
  assign apb_write_data = (ir_hold_reg == `APB_WRITE_DATA);
  assign data_captured = Capture_Data(
                            ir_hold_reg,
            DATA_ahb_tap_tmp,
          DATA_apb_tap_tmp,
                            DONE_ahb_tap_tmp,
                            DONE_apb_tap_tmp,
                            FAIL_ahb_tap_tmp,
                            FAIL_apb_tap_tmp);
 assign keep_off = (~(TRANSFER_tap_ahb_tmp | TRANSFER_tap_apb_tmp));
 ////////////////////////////////////////////////////////////////////////////////////////
  //Shift and Hold Registers in TAP
  always @ (posedge TCK or negedge TRST_n) begin
  if(!TRST_n) begin
    ir_hold_reg <= {`IR_WIDTH{1'b0}};
    dr_hold_reg <= {`DATA_WIDTH{1'b0}};
    ir_shift_reg <= {`IR_WIDTH{1'b0}};
    dr_shift_reg <= {`DATA_WIDTH{1'b0}};
  end else begin
    ir_hold_reg <=  ir_hold_reg_tmp;
    ir_shift_reg <= ir_shift_reg_tmp;
    dr_hold_reg <= dr_hold_reg_tmp;
    dr_shift_reg <= dr_shift_reg_tmp;
  end
  end

  always @(*) begin
      ir_hold_reg_tmp = ir_update ? ir_shift_reg : ir_hold_reg;
    ir_shift_reg_tmp = ir_capture ? ir_hold_reg : ir_shift ? {TDI_agent_tap,ir_shift_reg[`IR_WIDTH-1:1]} :ir_shift_reg;
    dr_hold_reg_tmp = dr_update ? dr_shift_reg : dr_hold_reg;
    dr_shift_reg_tmp = dr_capture ? data_captured :
            dr_shift ? {TDI_agent_tap,dr_shift_reg[`DATA_WIDTH-1:1]}:
            dr_shift_reg;
  end
  /////////////////////////////////////////////////////////////////////////////////////////
  //TAP-AHB interace
  always @ (posedge TCK or negedge TRST_n) begin
    if(!TRST_n) begin
        TRANSFER_tap_ahb <= 1'b0;
        RorW_tap_ahb <= 1'b0;
        ADDR_tap_ahb <= {`ADDR_WIDTH{1'b0}};
        DATA_tap_ahb <= {`DATA_WIDTH{1'b0}};
    end
    else begin
  TRANSFER_tap_ahb <= TRANSFER_tap_ahb_tmp;
        RorW_tap_ahb <= RorW_tap_ahb_tmp;
        ADDR_tap_ahb <=  ADDR_tap_ahb_tmp;
  DATA_tap_ahb <= DATA_tap_ahb_tmp;
  end
 end
  always @ (*) begin
  TRANSFER_tap_ahb_tmp = (dr_update & (ahb_read | ahb_write_data));
  RorW_tap_ahb_tmp = (dr_update & ahb_write_data);
  ADDR_tap_ahb_tmp = (dr_update & (ahb_read | ahb_write_addr)) ? dr_shift_reg : ADDR_tap_ahb;
  DATA_tap_ahb_tmp = (dr_update & ahb_write_data) ? dr_shift_reg : DATA_tap_ahb;
  end

  always @(posedge TCK or negedge TRST_n) begin
  if(!TRST_n) begin
    DONE_ahb_tap_tmp <= 1'b0;
    FAIL_ahb_tap_tmp <= 2'b0;
    DATA_ahb_tap_tmp <= {`DATA_WIDTH{1'b0}};
  end else begin
      DONE_ahb_tap_tmp <= done_ahb_tap_w;
    FAIL_ahb_tap_tmp <= fail_ahb_tap_w;
    DATA_ahb_tap_tmp <= data_ahb_tap_w;
  end
  end

  always @(*) begin
      done_ahb_tap_w = (DONE_ahb_tap) ? 1'b1 : (keep_off) ? DONE_ahb_tap_tmp : 1'b0;
          fail_ahb_tap_w = (DONE_ahb_tap) ? FAIL_ahb_tap : (keep_off) ? FAIL_ahb_tap_tmp :{`ERR_WIDTH{1'b0}};
          data_ahb_tap_w = (DONE_ahb_tap) ? DATA_ahb_tap : (keep_off) ? DATA_ahb_tap_tmp : 0;
  end


 /////////////////////////////////////////////////////////////////////////////////////////
 //TAP-APB interface
 always @ (posedge TCK or negedge TRST_n) begin
   if(!TRST_n) begin
        TRANSFER_tap_apb <= 1'b0;
        RorW_tap_apb <= 1'b0;
        ADDR_tap_apb <= {`ADDR_WIDTH{1'b0}};
        DATA_tap_apb <= {`DATA_WIDTH{1'b0}};
   end
   else begin
  TRANSFER_tap_apb <= TRANSFER_tap_apb_tmp;
        RorW_tap_apb <= RorW_tap_apb_tmp;
        ADDR_tap_apb <=  ADDR_tap_apb_tmp;
  DATA_tap_apb <= DATA_tap_apb_tmp;
   end
  end

  always @ (*) begin
  TRANSFER_tap_apb_tmp = (dr_update & (apb_read | apb_write_data));
  RorW_tap_apb_tmp = (dr_update & apb_write_data);
  ADDR_tap_apb_tmp = (dr_update & (apb_read | apb_write_addr)) ? dr_shift_reg : ADDR_tap_apb;
  DATA_tap_apb_tmp = (dr_update & apb_write_data) ? dr_shift_reg : DATA_tap_apb;
  end
  always @(posedge TCK or negedge TRST_n) begin
  if(!TRST_n) begin
    DONE_apb_tap_tmp <= 1'b0;
    FAIL_apb_tap_tmp <= 2'b0;
    DATA_apb_tap_tmp <= {`DATA_WIDTH{1'b0}};
  end else begin
      DONE_apb_tap_tmp <= done_apb_tap_w;
    FAIL_apb_tap_tmp <= fail_apb_tap_w;
    DATA_apb_tap_tmp <= data_apb_tap_w;
  end
  end

  always @(*) begin
          done_apb_tap_w = (DONE_apb_tap) ? 1'b1 : (keep_off) ? DONE_apb_tap_tmp : 1'b0;
          fail_apb_tap_w = (DONE_apb_tap) ? FAIL_apb_tap : (keep_off) ? FAIL_apb_tap_tmp :{`ERR_WIDTH{1'b0}};
          data_apb_tap_w = (DONE_apb_tap) ? DATA_apb_tap : (keep_off) ? DATA_apb_tap_tmp : 0;
  end


 /////////////////////////////////////////////////////////////////////////////////////////
 //TAP to Agent
  always @(negedge TCK or negedge TRST_n) begin
    if(!TRST_n)
       TDO_tap_agent <= 1'b0;
    else
       TDO_tap_agent <= TDO_tap_agent_tmp;
       //TDO_tap_agent_dr <= {TDO_dr,TDO_tap_agent_dr[31:1]};
       //TDO_tap_agent_ir <= {TDO_ir,TDO_tap_agent_ir[9:1]};
   end

  always @(*) begin
    //TDO_ir = ir_shift ? ir_shift_reg[0] : 1'b0;
  //TDO_dr = dr_shift ? dr_shift_reg[0] : 1'b0;
  TDO_tap_agent_tmp = dr_shift ? dr_shift_reg[0] : ir_shift_reg[0];
  end
 /////////////////////////////////////////////////////////////////////////////////////////
 //Capture data and status returned by AHB or APB

  function [`DATA_WIDTH-1:0] Capture_Data (
       input [`IR_WIDTH-1:0] cur_ins,
       input [`DATA_WIDTH-1:0] DATA_h_t,
       input [`DATA_WIDTH-1:0] DATA_p_t,
       input DONE_h_t,
       input DONE_p_t,
       input [`ERR_WIDTH-1:0] FAIL_h_t,
       input [`ERR_WIDTH-1:0] FAIL_p_t
);
  begin
       case (cur_ins)
       `WRITE_STT, `READ_STT: begin
           if(DONE_h_t)
        Capture_Data = (FAIL_h_t == `DONE) ? 32'hCAFE_CAFE : // CAFE_CAFE
           (FAIL_h_t == `INVALID_ADDR) ? 32'hBEEF_DEAD :
            32'hDEAD_BEEF;
     else if(DONE_p_t)
        Capture_Data = (FAIL_p_t == `DONE) ? 32'hCAFE_CAFE :
                                   (FAIL_p_t == `INVALID_ADDR) ? 32'hBEEF_DEAD :
                                   32'hDEAD_BEEF;
       else Capture_Data = 32'hDEAD_BEEF;

      end
      `READ_DATA: begin
    if(DONE_h_t)
              Capture_Data = DATA_h_t;
    else if(DONE_p_t)
        Capture_Data = DATA_p_t;
    else
        Capture_Data = 32'hDEAD_BEEF;
      end
      default:  Capture_Data = 32'h0;
      endcase
 end
endfunction
endmodule

