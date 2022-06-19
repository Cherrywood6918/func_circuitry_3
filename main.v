`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2022 23:31:26
// Design Name: 
// Module Name: main_func
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module main_func(
    input clk_i,
    input rst_i,
    input [7:0] a_bi,
    input [7:0] b_bi,
    input start_i,
    output ready_o,
    output reg [2:0] y_bo
);

    localparam IDLE = 2'b00;
    localparam ADD = 2'b01;
    localparam CUB = 2'b10;
    localparam READY = 2'b11;

    reg [8:0] part_res;
    reg [2:0] state;

    assign ready_o = (state == READY);

 
    wire sqrt_ready;
    wire [3:0] sqrt_b;
    sqrt sqrt_func(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .x_bi(b_bi),
        .start_i(start_i),
        .ready_o(sqrt_ready),
        .y_bo(sqrt_b)
    );

    reg cub_start;
    wire cub_ready;
    wire [2:0] cub_res;
    cub cub_func(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .x_bi(part_res),
        .start_i(cub_start),
        .ready_o(cub_ready),
        .y_bo(cub_res)
    );

    always @(posedge clk_i)
        if (rst_i) begin
            part_res <= 0;
            y_bo <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    if(start_i) begin
                        state <= ADD;
                    end
                ADD:
                    begin
                        if(sqrt_ready) begin
                            part_res <= (a_bi + sqrt_b);
                            cub_start <= 1;
                            state <= CUB;
                        end
                    end
                CUB:
                    begin
                        if (cub_start == 1) begin
                                cub_start <= 0;
                            end else
                                if(cub_ready) begin
                                    y_bo <= cub_res;
                                    state <= READY;
                                end
                    end
            endcase
        end
endmodule
