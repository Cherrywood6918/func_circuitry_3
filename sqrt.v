`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2022 23:29:38
// Design Name: 
// Module Name: sqrt
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

module sqrt(
    input clk_i ,
    input rst_i ,
    input start_i ,
    input [7:0] x_bi ,
    input [7:0] partRes ,
    output reg [7:0] partA ,
    output reg [7:0] partB ,
    output reg [2:0] oper,
    output ready_o ,
    output reg [3:0] y_bo 
    );
    
    localparam IDLE = 4'b0000;
    localparam WORK = 4'b0001;
    localparam WAIT_OR_B = 4'b0010;
    localparam WAIT_SHIFT_Y = 4'b0011;
    localparam IF = 4'b0100;
    localparam WAIT_SUB = 4'b0101;
    localparam WAIT_OR_Y = 4'b0110;
    localparam ENDIF = 4'b0111;
    localparam WAIT_SHIFT_M = 4'b1000;
    localparam READY = 4'b1001;
    
        
    reg [7:0] x;
    reg [7:0] m;
    reg [7:0] y;
    reg [3:0] state;  
    reg [7:0] b;
    
    assign ready_o = (state == READY);

    always @(posedge clk_i or negedge rst_i)
        if (!rst_i) begin      
            m <= 0;
            y <= 0;
            b <= 0;
            partA <= 0;
            partB <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    if(start_i) begin
                        $display("SQRT START");
                        m <= 64;
                        x <= x_bi;                       
                        state <= WORK;
                    end
                WORK: begin
                       // $display("WORK");
                       // $display("m %d", m);  
                        //$display("Y %d", y);
                        if(m == 0) begin                            
                            y_bo <= y;
                            state <= READY;
                        end else begin  
                            //b <= y | m;
                            partA <= y;
                            partB <= m;
                            oper <= `ALU_OR;  
                            state <= WAIT_OR_B;                               
                        end
                    end
                    WAIT_OR_B: begin
                       // $display("WAIT_OR_B"); 
                        b <= partRes;
                        //$display("partRes %d", partRes);
                        //$display("b %d", b); 
                         partA <= y;
                         partB <= 1;
                         oper <= `ALU_SRL;                            
                         state <= WAIT_SHIFT_Y;   
                    end                   
                    WAIT_SHIFT_Y: begin
                        //$display("WAIT_SHIFT_Y"); 
                        // $display("b %d", b); 
                        y <= partRes;  
                        //$display("y %d", y); 
                        state <= IF;   
                    end 
                    IF: begin
                        //$display("IF");  
                        // $display("y %d", y); 
                       if(x >= b) begin
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
                        //$display("WAIT_SUB"); 
                        x <= partRes;
                        //$display("x %d", x); 
                        //y <= (y | m);
                         partA <= y;
                         partB <= m;
                         oper <= `ALU_OR;                            
                         state <= WAIT_OR_Y;  
                    end
                    WAIT_OR_Y: begin
                        //$display("WAIT_OR_Y"); 
                        //$display("x %d", x);
                        y <= partRes;
                        //$display("y %d", y); 
                         //y <= (y >> 1);
                         partA <= y;
                         partB <= 1;
                         oper <= `ALU_SRL;                            
                         state <= ENDIF; 
                    end
                    ENDIF: begin
                       // $display("ENDIF"); 
                        // m <= m >> 2; 
                        //$display("y %d", y);                  
                         partA <= m;
                         partB <= 2;
                         oper <= `ALU_SRL;                            
                         state <= WAIT_SHIFT_M; 
                    end
                    WAIT_SHIFT_M: begin
                       // $display("WAIT_SHIFT_M");
                         m <= partRes;
                                                    
                         state <= WORK; 
                    end                           
            endcase
        end
endmodule
