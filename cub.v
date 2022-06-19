`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2022 23:30:35
// Design Name: 
// Module Name: cub
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
`include "sr_cpu.vh"

module cub(
    input clk_i,
    input rst_i,
    input [8:0] x_bi,
    input start_i,
    output ready_o,
    output reg [2:0] y_bo);
    
    localparam IDLE = 3'b000;
    localparam MULT_Y = 3'b001;
    localparam MULT_PART_RES_1 = 3'b010;
    localparam MULT_PART_RES_2 = 3'b011;
    localparam WAIT_B = 3'b100;
    localparam IF = 3'b101;
    localparam READY = 3'b111;
    
    reg [8:0] x;
    reg [7:0] y;
    reg [3:0] s;
    reg [7:0] b;
    reg [2:0] state;
    
    reg [7:0] m1, m2;
    reg mult_rst, mult_start;
    wire mult_ready;
    wire [15:0] mult_y;  
 
    assign ready_o = (state == READY);
   
    mult mult_func(
        .clk_i(clk_i),
        .rst_i(mult_rst),
        .a_bi(m1), 
        .b_bi(m2), 
        .start_i(mult_start),
        .ready_o(mult_ready),
        .y_bo(mult_y));     
 
    always @(posedge clk_i or negedge rst_i)
        if (!rst_i) begin
            s <= 0;  
            y <= 0;
            b <= 0;
            y_bo <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    begin
                        if(start_i) begin
                            s <= 9;  
                            x <= x_bi;
                            y <= 0;
                            b <= 0;
                            state <= MULT_Y;
                        end
                    end
                MULT_Y:
                    begin
                        if(s == 0) begin
                            y_bo <= y;
                            state <= READY;
                        end else begin
                            y <= y<<1;//y*2 
                            state <= MULT_PART_RES_1;
                        end
                    end
                MULT_PART_RES_1:
                    begin 
                        m1 <= 3;
                        m2 <= y;
                        mult_rst <= 0;
                        mult_start <= 1;                    
                        state <= MULT_PART_RES_2;
                    end   
                MULT_PART_RES_2:     
                    begin
                        if(mult_rst == 0) begin 
                            mult_rst <= 1;
                        end else begin
                            if (mult_start == 1) begin 
                                mult_start <= 0;
                            end else
                                if(mult_ready) begin
                                    m1 <= mult_y;
                                    m2 <= (y | 1'b1); //y+1 
                                    mult_rst <= 0;
                                    mult_start <= 1;   
                                    state <= WAIT_B;                           
                                end      
                            end
                    end
                 WAIT_B:
                    begin
                        if(mult_rst == 0) begin 
                            mult_rst <= 1;
                        end else begin
                            if (mult_start == 1) begin 
                                mult_start <= 0;
                            end else
                                if(mult_ready) begin
                                    b <= (mult_y | 1'b1) << (s - 3);
                                    state <= IF;                          
                                end      
                            end
                    end
                 IF:
                    begin
                        if(x>=b) begin
                            x <= x - b;
                            y <= y | 1'b1;
                        end
                        s <= s-3;
                        state <= MULT_Y;
                    end
            endcase
        end
endmodule

    
    
  /*  localparam IDLE = 4'b0000;
    localparam MULT_Y = 4'b0001;
    localparam WAIT_MULT_2Y = 4'b0010;
    localparam MULT_PART_RES_2 = 4'b0011;
    localparam WAIT_B = 4'b0100;
    localparam IF = 4'b0101;
    localparam READY = 4'b0111;
    localparam WAIT_SUB = 4'b1000;
    localparam WAIT_ADD = 4'b1001;
    localparam ENDIF = 4'b1010;
    localparam WAIT_SUB_S = 4'b1011;
    
    reg [8:0] x;
    reg [7:0] y;
    reg [3:0] s;
    reg [7:0] b;
    reg [3:0] state;
    
    reg [7:0] m1, m2;
    reg mult_rst, mult_start;
    wire mult_ready;
    wire [15:0] mult_y;  
 
    assign ready_o = (state == READY);
   
    mult mult_func(
        .clk_i(clk_i),
        .rst_i(mult_rst),
        .a_bi(m1), 
        .b_bi(m2), 
        .start_i(mult_start),
        .ready_o(mult_ready),
        .y_bo(mult_y));     
 
    always @(posedge clk_i or negedge rst_i)
        if (!rst_i) begin
            s <= 0;  
            y <= 0;
            b <= 0;
            y_bo <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                        if(start_i) begin
                            $display("CUB START");
                            s <= 9;  
                            x <= x_bi;
                            $display("x %d", x_bi);
                            y <= 0;
                            b <= 0;
                            state <= MULT_Y;
                        end
                    end
                MULT_Y: begin
                        $display(" MULT_Y");
                        if(s == 0) begin
                            y_bo <= y;
                            state <= READY;
                        end else begin
                             y <= y<<1;//y*2
                            // partA <= y;
                            // partB <= 1;
                            // oper <= `ALU_SLL;       
                             state <= WAIT_MULT_2Y;
                        end
                    end
                WAIT_MULT_2Y: begin 
                        $display(" WAIT_MULT_2Y");
                         
                        m1 <= 3;
                        m2 <= y;
                        mult_rst <= 1;
                        mult_start <= 1;                    
                        state <= MULT_PART_RES_2;
                    end   
                MULT_PART_RES_2: begin
                        $display("MULT_PART_RES_2");
                        $display("mult_ready %d", mult_ready);
                        if(mult_rst == 1) begin 
                            mult_rst <= 0;
                        end else begin
                            if (mult_start == 1) begin 
                                mult_start <= 0;
                            end else
                                if(mult_ready) begin
                                    m1 <= mult_y;
                                    m2 <= (y | 1'b1); //y+1 
                                    mult_rst <= 1;
                                    mult_start <= 1;   
                                    state <= WAIT_B;                           
                                end      
                            end
                    end
                 WAIT_B: begin
                         $display("WAIT_B");
                        if(mult_rst == 1) begin 
                            mult_rst <= 0;
                        end else begin
                            if (mult_start == 1) begin 
                                mult_start <= 0;
                            end else
                                if(mult_ready) begin
                                    b <= (mult_y | 1'b1) << (s - 3);
                                    state <= IF;                          
                                end      
                            end
                    end
                 IF: begin
                        $display("IF");
                        if(x>=b) begin
                           //x <= (x - b);
                           partA <= x;
                           partB <= b;
                           oper <= `ALU_SUB;                             
                           state <= WAIT_SUB;      
                        end else begin
                           state <= ENDIF; 
                        end
                    end
                 WAIT_SUB: begin
                        $display("WAIT_SUB"); 
                        x <= partRes;
                        //$display("x %d", x); 
                        //y <= y + 1;
                         partA <= y;
                         partB <= 1;
                         oper <= `ALU_ADD;                            
                         state <= WAIT_ADD;  
                    end
                 WAIT_ADD: begin
                        $display("WAIT_ADD"); 
                        y <= partRes; 
                        state <= ENDIF;   
                    end 
                 ENDIF: begin
                        $display("ENDIF"); 
                        // s <= s - 3; 
                         partA <= s;
                         partB <= 3;
                         oper <= `ALU_SUB; 
                         state <= WAIT_SUB_S;                                          
                    end 
                 WAIT_SUB_S: begin
                        $display("WAIT_SUB_S"); 
                        s <= partRes;
                        //$display("x %d", x); 
                        state <= MULT_Y;  
                    end  
            endcase
        end
endmodule*/
