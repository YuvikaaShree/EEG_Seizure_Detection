`timescale 1ns / 1ps
module cnn_top(
    input clk,
    input rst,
    input [2:0] sw,           // Switch to select input set (0-4)
    output [15:0] led,
    output [6:0] SEG,         // 7-segment outputs (a-g)
    output [3:0] AN           // Anode selectors (AN3 is leftmost)
);

    wire seizure_detected;
    reg signed [16*23-1:0] eeg_input_flat;

    // --- SEVEN-SEGMENT DISPLAY LOGIC SIGNALS ---
    wire [3:0] seg_display_val;

    // Select EEG input set using switches (EXISTING LOGIC)
    always @(*) begin
        case (sw)
            3'd0: eeg_input_flat = {16'd114, 16'd42, 16'd30, 16'd46, 16'd46, -16'd22, 16'd10, 16'd62,
                                     16'd6, 16'd25, 16'd43, 16'd58, -16'd2, 16'd3, -16'd55, -16'd57,
                                     16'd19, 16'd56, 16'd33, 16'd33, 16'd0, 16'd0, 16'd0}; //ictal
            3'd1: eeg_input_flat = {16'd115, 16'd46, 16'd25, 16'd51, 16'd39, -16'd20, 16'd26, 16'd76,
                                     16'd9, 16'd37, 16'd36, 16'd50, -16'd2, 16'd3, -16'd56, -16'd51,
                                     16'd16, 16'd57, 16'd21, 16'd21, 16'd0, 16'd0, 16'd0}; //ictal
            3'd2: eeg_input_flat = {-16'd21, 16'd3, -16'd3, 16'd0,
                                     -16'd4, -16'd13, 16'd0, -16'd3,
                                     -16'd30, -16'd23, -16'd48, -16'd14,
                                     -16'd16, 16'd0, 16'd20, -16'd19,
                                     16'd4, -16'd4, -16'd23, 16'd13,
                                     16'd4, 16'd14, 16'd14}; //preictal
            3'd3: eeg_input_flat = {16'd20, 16'd10, 16'd22, 16'd37, 16'd32, 16'd35, 16'd16, 16'd46,
                                     -16'd7, 16'd43, 16'd40, 16'd13, -16'd14, 16'd34, 16'd24, -16'd30,
                                     16'd10, -16'd11, -16'd37, 16'd8, 16'd12, 16'd21, 16'd21}; //preictal
            3'd4: eeg_input_flat = {16'd38, 16'd57, 16'd23, 16'd91,
                                     16'd27, 16'd22, 16'd27, 16'd33,
                                     -16'd30, -16'd4, 16'd97, -16'd10,
                                     16'd102, 16'd20, 16'd52, -16'd30,
                                     16'd12, -16'd28, -16'd82, 16'd14,
                                     16'd28, -16'd36, -16'd36}; //ictal
            default: eeg_input_flat = 0;
        endcase
    end

    // CNN instance
    cnn_1d cnn (
        .clk(clk),
        .rst(rst),
        .eeg_input_flat(eeg_input_flat),
        .seizure_detected(seizure_detected)
    );

    // LED output
    assign led[0] = ~seizure_detected; // No seizure
    assign led[1] = seizure_detected;  // Seizure
    assign led[15:2] = 14'b0;

    // 7-segment: 1 for seizure, 0 for normal
    assign seg_display_val = seizure_detected ? 4'd1 : 4'd0;

    // Enable only rightmost digit
    assign AN = 4'b0111;

    // 7-segment encoder
    assign SEG = hex_to_seg(seg_display_val);

    function automatic [6:0] hex_to_seg;
    input [3:0] code;
    begin
        case(code)
            4'd0: hex_to_seg = 7'b0000001; // 0
            4'd1: hex_to_seg = 7'b1001111; // 1
            default: hex_to_seg = 7'b1111111; // Blank
        endcase
    end
endfunction

endmodule

