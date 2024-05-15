`include "/home/ftv_training/SFD/4_Intern/2024_Mar/tuan_huynh/verilog_introduction/verilog/parameters.vh"
module TAP_Controller (
    input TCK,
    input TRST_n,
    input TMS_agent_tap,
    output reg [3:0] state_out
);

reg [3:0] current_state, next_state;

always @ (posedge TCK or negedge TRST_n) begin
    if (~TRST_n) begin
        current_state <= `RESET;
    end else begin
        current_state <= next_state;
    end
end

always @ (*) begin
    case (current_state)
  `RESET: next_state = TMS_agent_tap ? `RESET : `IDLE;
        `IDLE: next_state = TMS_agent_tap ? `DR_SELECT : `IDLE;
        `DR_SELECT: next_state = TMS_agent_tap ? `IR_SELECT : `DR_CAPTURE;
        `DR_CAPTURE: next_state = TMS_agent_tap ?`DR_EXIT1 : `DR_SHIFT;
        `DR_SHIFT: next_state = TMS_agent_tap ? `DR_EXIT1 : `DR_SHIFT;
        `DR_EXIT1: next_state = TMS_agent_tap ? `DR_UPDATE : `DR_PAUSE;
        `DR_PAUSE: next_state = TMS_agent_tap ? `DR_EXIT2 : `DR_PAUSE;
        `DR_EXIT2: next_state = TMS_agent_tap ? `DR_UPDATE : `DR_SHIFT;
        `DR_UPDATE: next_state = TMS_agent_tap ? `DR_SELECT : `IDLE;
        `IR_SELECT: next_state = TMS_agent_tap ? `RESET : `IR_CAPTURE;
        `IR_CAPTURE: next_state = TMS_agent_tap ? `IR_EXIT1 : `IR_SHIFT;
        `IR_SHIFT: next_state = TMS_agent_tap ?`IR_EXIT1 : `IR_SHIFT;
        `IR_EXIT1: next_state = TMS_agent_tap ? `IR_UPDATE : `IR_PAUSE;
        `IR_PAUSE: next_state = TMS_agent_tap ? `IR_EXIT2 : `IR_PAUSE;
        `IR_EXIT2: next_state = TMS_agent_tap ? `IR_UPDATE : `IR_SHIFT;
        `IR_UPDATE: next_state = TMS_agent_tap ? `DR_SELECT : `IDLE;
        default: next_state = `RESET;
    endcase
end

always @ (*) begin

    state_out = current_state;
end

endmodule

