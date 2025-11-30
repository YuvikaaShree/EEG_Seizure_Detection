`timescale 1ns / 1ps

module cnn_1d(
    input clk,
    input rst,
    input signed [16*23-1:0] eeg_input_flat,  // Flattened 23-channel EEG
    output reg seizure_detected

);
    // Parameters
    parameter INPUT_SIZE = 23;
    parameter KERNEL = 3;
    parameter CONV_OUT = INPUT_SIZE - KERNEL + 1;
    parameter FILTERS = 2;       // For simulation
    parameter DENSE1 = 4;
    integer i, j, k, idx;
    // Unpack EEG input
    reg signed [15:0] eeg_input [0:22];
    always @(*) begin
        for(i=0;i<INPUT_SIZE;i=i+1)
            eeg_input[i] = eeg_input_flat[16*i +: 16];
    end
    // Conv layer
    reg signed [15:0] conv_weights[FILTERS-1:0][KERNEL-1:0];
    reg signed [15:0] conv_bias[FILTERS-1:0];
    reg signed [31:0] conv_out[FILTERS-1:0][CONV_OUT-1:0];
    // Dense layers
    reg signed [15:0] dense1_weights[FILTERS*CONV_OUT-1:0][DENSE1-1:0];
    reg signed [15:0] dense1_bias[DENSE1-1:0];
    reg signed [15:0] dense2_weights[DENSE1-1:0];
    reg signed [15:0] dense2_bias;
    reg signed [31:0] flat[FILTERS*CONV_OUT-1:0];
    reg signed [31:0] dense_out[DENSE1-1:0];
    reg signed [31:0] sum_dense;
    // Initialize weights 
    initial begin      
        for(i=0;i<FILTERS;i=i+1) begin
            conv_bias[i]=0;
            for(j=0;j<KERNEL;j=j+1) conv_weights[i][j]=1;
        end
        for(i=0;i<FILTERS*CONV_OUT;i=i+1)
            for(j=0;j<DENSE1;j=j+1) dense1_weights[i][j]=1;
        for(i=0;i<DENSE1;i=i+1) begin
            dense1_bias[i]=0;
            dense2_weights[i]=1;
        end
        dense2_bias=0;
    end
    // ReLU function
    function signed [31:0] relu;
        input signed [31:0] x;
        begin
            if(x<0) relu=0; else relu=x;

        end
    endfunction
    // CNN + dense computation
    always @(posedge clk or posedge rst) begin
        if(rst)
            seizure_detected <= 0;
        else begin
            // Conv1D + ReLU
            for(i=0;i<FILTERS;i=i+1) begin
                for(j=0;j<CONV_OUT;j=j+1) begin
                    conv_out[i][j]=conv_bias[i];
                    for(k=0;k<KERNEL;k=k+1)
                        conv_out[i][j]=conv_out[i][j]+eeg_input[j+k]*conv_weights[i][k];
                    conv_out[i][j] = relu(conv_out[i][j]);
                end
            end
            // Flatten conv
            idx=0;
            for(i=0;i<FILTERS;i=i+1)
                for(j=0;j<CONV_OUT;j=j+1) begin
                    flat[idx]=conv_out[i][j];
                    idx=idx+1;
                end
            // Dense1 + ReLU
            for(j=0;j<DENSE1;j=j+1) begin
                dense_out[j]=dense1_bias[j];
                for(i=0;i<FILTERS*CONV_OUT;i=i+1)
                    dense_out[j]=dense_out[j]+flat[i]*dense1_weights[i][j];
                dense_out[j]=relu(dense_out[j]);
            end
            // Dense2 sum
            sum_dense=dense2_bias;
            for(i=0;i<DENSE1;i=i+1)
                sum_dense=sum_dense + dense_out[i]*dense2_weights[i];
            // Threshold to detect seizure
            if(sum_dense>1000)
                seizure_detected <= 1;
            else
                seizure_detected <= 0;
        end
    end
endmodule
