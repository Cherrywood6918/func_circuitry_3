`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2022 23:28:51
// Design Name: 
// Module Name: mult
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


module mult(
    input clk_i,
    input rst_i,
    input [7:0] a_bi,
    input [7:0] b_bi,
    input start_i,
    output ready_o,
    output reg [15:0] y_bo

);

    localparam IDLE = 2'b00;
    localparam WORK = 2'b01;
    localparam READY = 2'b10;

    reg [2:0] ctr;
    wire [2:0] end_step;
    wire [7:0] part_sum;
    wire [15:0] shifted_part_sum;
    reg [7:0] a, b;
    reg [15:0] part_res;
    reg [2:0] state;

    assign part_sum = a & {8{b[ctr]}};
    assign shifted_part_sum = part_sum << ctr;
    assign end_step = ( ctr == 3'h7 );
    assign ready_o = (state == READY);
    
    always @(posedge clk_i or negedge rst_i)
        if (!rst_i) begin
            ctr <= 0;
            part_res <= 0;
            y_bo <= 0;
            $display("MULT_RST");
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    begin
                        if (start_i) begin
                        $display("MULT_START");
                            a <= a_bi;
                            b <= b_bi;
                            $display("a %d", a_bi);
                            $display("b %d", b_bi);
                            ctr <= 0;
                            part_res <= 0;
                            state <= WORK;
                        end
                    end
                WORK:
                    begin
                    $display("MULT_WORK");
                        if (end_step) begin
                           $display("MULT_END");
                            y_bo <= part_res;
                            state <= READY;
                        end else begin
                        part_res <= part_res + shifted_part_sum;
                        ctr <= (ctr + 1);
                        $display("part_res %d", part_res);
                        $display("ctr %d", ctr);
                        end
                    end
                  READY: begin
                  $display("ready_o %d", ready_o);
                  end  
            endcase
        end
endmodule
