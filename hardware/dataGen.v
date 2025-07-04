`timescale 1ns / 1ps
`define lineSize 1920
`define frameSize 1920*1080

module dataGen(
    input i_clk,
    input i_reset_n,
    output reg [23:0] o_data, // For 3  8-bit data bits, Color channels Red, Green, Blue
    output reg o_data_valid,
    input i_data_ready,
    output reg o_sof,
    output reg o_eol
    );
    
    reg [1:0] state;
    localparam IDLE = 'd0, SEND_DATA = 'd1, END_LINE = 'd3;
    integer linePixelCounter;
    integer dataCounter;
    
    
    // 1920 / 3 = 640
    always @(*)
    begin
        if(linePixelCounter >= 0 && linePixelCounter < 640) begin
            o_data <= 24'h000_0ff; // RED 
        end 
        else if(linePixelCounter >= 640 && linePixelCounter < 1280) begin
            o_data <= 24'h00ff00;
        end
        else
            o_data <= 24'hff0000;
    end
    
    
    always @(posedge i_clk) begin
        if(!i_reset_n) begin 
            state <= IDLE;
            linePixelCounter <= 0;
            dataCounter <= 0;
            o_data_valid <= 1'b0;
            o_sof <= 1'b0;
            o_eol <= 1'b0;
        end
        else begin
            case(state)
                IDLE: begin
                    o_sof <= 1'b1; 
                    o_data_valid <= 1'b1;
                    state <= SEND_DATA;
                end
                SEND_DATA: begin
                    if(i_data_ready) begin
                        o_sof <= 1'b0;
                        linePixelCounter <= linePixelCounter + 1;
                        dataCounter <= dataCounter + 1;
                    end
                    if(linePixelCounter == `lineSize-2) begin
                        o_eol <= 1'b1;
                        state <= END_LINE;
                    end 
                end
                END_LINE: begin
                    if(i_data_ready) begin
                        o_eol <= 1'b0;
                        linePixelCounter <= 0;
                        dataCounter <= dataCounter + 1;
                    end 
                    if(dataCounter == `frameSize-1) begin
                        state <= IDLE;
                        o_data_valid <= 1'b0;
                        dataCounter <= 0;
                    end
                    else begin 
                        state <= SEND_DATA;
                    end 
                end 
            endcase
        end 
    end 
endmodule
