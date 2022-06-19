/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 

`include "sr_cpu.vh"

module sr_cpu
(
    input           clk,        // clock
    input           rst_n,      // reset
    input   [ 4:0]  regAddr,    // debug access reg address
    output  [31:0]  regData,    // debug access reg data
    output  [31:0]  imAddr,     // instruction memory address
    input   [31:0]  imData      // instruction memory data
);
    //control wires
    wire        aluZero;
    wire        pcSrc;
    wire        pcEnable; //NEW
    wire        regWrite;
    wire        aluSrc;
    wire  [1:0] wdSrc;
    wire  [2:0] aluControl;
    wire        funcFlag; //NEW
    

    //instruction decode wires
    wire [ 6:0] cmdOp;
    wire [ 4:0] rd;
    wire [ 2:0] cmdF3;
    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [ 6:0] cmdF7;
    wire [31:0] immI;
    wire [31:0] immB;
    wire [31:0] immU;

    wire        ready; //NEW

    //program counter
    wire [31:0] pc;
    wire [31:0] pcBranch = pc + immB;
    wire [31:0] pcPlus4  = pc + 4;
    wire [31:0] pcNext   = pcSrc ? pcBranch : pcPlus4;   
    sm_register_we r_pc(clk ,rst_n, pcEnable, pcNext, pc); //UPDATE
    //sm_register r_pc(clk ,rst_n, pcNext, pc);

    //program memory access
    assign imAddr = pc >> 2;
    wire [31:0] instr = imData;

    //instruction decode
    sr_decode id (
        .instr      ( instr        ),
        .cmdOp      ( cmdOp        ),
        .rd         ( rd           ),
        .cmdF3      ( cmdF3        ),
        .rs1        ( rs1          ),
        .rs2        ( rs2          ),
        .cmdF7      ( cmdF7        ),
        .immI       ( immI         ),
        .immB       ( immB         ),
        .immU       ( immU         ) 
    );

    //register file
    wire [31:0] rd0;
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] wd3;  

    sm_register_file rf (
        .clk        ( clk          ),
        .a0         ( regAddr      ),
        .a1         ( rs1          ),
        .a2         ( rs2          ),
        .a3         ( rd           ),
        .rd0        ( rd0          ),
        .rd1        ( rd1          ),
        .rd2        ( rd2          ),
        .wd3        ( wd3          ),
        .we3        ( regWrite     )
    );

    //debug register access
    assign regData = (regAddr != 0) ? rd0 : pc;

    //alu
    //NEW
    wire [7:0] partA;
    wire [7:0] partB;
    wire [2:0] funcControl;  
    
    wire [31:0] srcB = aluSrc ? immI : rd2; 
    
    wire [31:0] aluA = funcFlag ? partA : rd1; 
    wire [31:0] aluB = funcFlag ? partB : srcB;
    wire [2:0] aluOper = funcFlag ? funcControl : aluControl;
    
    wire [31:0] aluResult;
    
    sr_alu alu (
        .srcA       ( aluA         ),//
        .srcB       ( aluB         ),//
        .oper       ( aluOper      ),//
        .zero       ( aluZero      ),
        .result     ( aluResult    ) 
    );
    
    wire [2:0] funcResult;
    
     //arithmetic_block
    //NEW 
    arithmetic arithm (
        .clk         ( clk          ),  // clock
        .rst_n       ( rst_n        ),
        .start       ( funcFlag     ), //
        .a           ( rd1          ),
        .b           ( srcB         ),
        .partRes     ( aluResult[15:0]),
        .funcControl ( funcControl  ),
        .partA       ( partA        ),
        .partB       ( partB        ),
        .ready       ( ready        ),
        .result      ( funcResult   )
    );
    


    
    assign wd3 = wdSrc == (2'b10)? funcResult : (wdSrc == (2'b01) ? immU : aluResult); //NEW

    //control
    sr_control sm_control (
        .cmdOp      ( cmdOp        ),
        .cmdF3      ( cmdF3        ),
        .cmdF7      ( cmdF7        ),
        .aluZero    ( aluZero      ),
        .pcSrc      ( pcSrc        ),
        .pcEnable   ( pcEnable     ), //NEW
        .regWrite   ( regWrite     ),
        .aluSrc     ( aluSrc       ),
        .wdSrc      ( wdSrc        ),
        .funcFlag   ( funcFlag     ), //NEW
        .aluControl ( aluControl   ) 
    );
endmodule

module sr_decode
(
    input      [31:0] instr,
    output     [ 6:0] cmdOp,
    output     [ 4:0] rd,
    output     [ 2:0] cmdF3,
    output     [ 4:0] rs1,
    output     [ 4:0] rs2,
    output     [ 6:0] cmdF7,
    output reg [31:0] immI,
    output reg [31:0] immB,
    output reg [31:0] immU 
);
    assign cmdOp = instr[ 6: 0];
    assign rd    = instr[11: 7];
    assign cmdF3 = instr[14:12];
    assign rs1   = instr[19:15];
    assign rs2   = instr[24:20];
    assign cmdF7 = instr[31:25];

    // I-immediate
    always @ (*) begin
        immI[10: 0] = instr[30:20];
        immI[31:11] = { 21 {instr[31]} };
    end

    // B-immediate
    always @ (*) begin
        immB[    0] = 1'b0;
        immB[ 4: 1] = instr[11:8];
        immB[10: 5] = instr[30:25];
        immB[   11] = instr[7];
        immB[31:12] = { 20 {instr[31]} };
    end

    // U-immediate
    always @ (*) begin
        immU[11: 0] = 12'b0;
        immU[31:12] = instr[31:12];
    end

endmodule

module sr_control
(
    input     [ 6:0] cmdOp,
    input     [ 2:0] cmdF3,
    input     [ 6:0] cmdF7,
    input            aluZero,
    input            ready, //NEW
    output           pcSrc,
    output           pcEnable, //NEW  
    output reg       regWrite, 
    output reg       aluSrc,
    output reg [1:0] wdSrc,
    output reg       funcFlag, //NEW
    output reg [2:0] aluControl
);
    reg          branch;
    reg          condZero;
    assign pcSrc = branch & (aluZero == condZero);
    assign pcEnable = ready | !funcFlag; //NEW 

    always @ (*) begin
        branch      = 1'b0;
        condZero    = 1'b0;
        regWrite    = 1'b0;
        aluSrc      = 1'b0;
        wdSrc       = 2'b00;
        funcFlag    = 1'b0;
        aluControl  = `ALU_ADD;

        casez( {cmdF7, cmdF3, cmdOp} )
            { `RVF7_ADD,  `RVF3_ADD,  `RVOP_ADD  } : begin regWrite = 1'b1; aluControl = `ALU_ADD;  end
            { `RVF7_OR,   `RVF3_OR,   `RVOP_OR   } : begin regWrite = 1'b1; aluControl = `ALU_OR;   end
            { `RVF7_SRL,  `RVF3_SRL,  `RVOP_SRL  } : begin regWrite = 1'b1; aluControl = `ALU_SRL;  end
            { `RVF7_SLTU, `RVF3_SLTU, `RVOP_SLTU } : begin regWrite = 1'b1; aluControl = `ALU_SLTU; end
            { `RVF7_SUB,  `RVF3_SUB,  `RVOP_SUB  } : begin regWrite = 1'b1; aluControl = `ALU_SUB;  end

            { `RVF7_ANY,  `RVF3_ADDI, `RVOP_ADDI } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD; end       
            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_LUI  } : begin regWrite = 1'b1; wdSrc  = 2'b01; end

            { `RVF7_ANY,  `RVF3_BEQ,  `RVOP_BEQ  } : begin branch = 1'b1; condZero = 1'b1; aluControl = `ALU_SUB; end
            { `RVF7_ANY,  `RVF3_BNE,  `RVOP_BNE  } : begin branch = 1'b1; aluControl = `ALU_SUB; end
            
            { `RVF7_SRLI,  `RVF3_SRLI, `RVOP_SRLI } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_SRL;end
            
            { `RVF7_FUNC, `RVF3_FUNC, `RVOP_FUNC } : begin funcFlag = 1'b1; wdSrc = 2'b10; end
        endcase     
    end
endmodule

module sr_alu
(
    input  [31:0] srcA,
    input  [31:0] srcB,
    input  [ 2:0] oper,
    output        zero,
    output reg [31:0] result
);
    always @ (*) begin
        case (oper)
            default   : result = srcA + srcB;
            `ALU_ADD  : result = srcA + srcB;
            `ALU_OR   : result = srcA | srcB;
            `ALU_SRL  : result = srcA >> srcB [4:0];
            `ALU_SLTU : result = (srcA < srcB) ? 1 : 0;
            `ALU_SUB  : result = srcA - srcB; 
            `ALU_SLL  : result = srcA << srcB [4:0];                                 
        endcase
        // $display("ALU %d RES %d", oper, result);
    end

    assign zero   = (result == 0);
endmodule

module sm_register_file
(
    input         clk,
    input  [ 4:0] a0,
    input  [ 4:0] a1,
    input  [ 4:0] a2,
    input  [ 4:0] a3,
    output [31:0] rd0,
    output [31:0] rd1,
    output [31:0] rd2,
    input  [31:0] wd3,
    input         we3
);
    reg [31:0] rf [31:0];

    assign rd0 = (a0 != 0) ? rf [a0] : 32'b0;
    assign rd1 = (a1 != 0) ? rf [a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf [a2] : 32'b0;

    always @ (posedge clk)
        if(we3) rf [a3] <= wd3;
endmodule

//NEW
module arithmetic
(
    input         clk,        // clock
    input         rst_n,
    input         start,
    input  [7:0]  a,
    input  [7:0]  b,
    input  [7:0] partRes,
    output [2:0]  funcControl,
    output [7:0]  partA,
    output [7:0]  partB,
    output        ready,
    output reg [2:0] result  //???
);
     
   
    localparam IDLE = 2'b00;
    localparam ADD = 2'b01;
    localparam CUB = 2'b10;
    localparam READY = 2'b11;

    reg [15:0] cub_part_res;
    reg [2:0] state;

    assign ready = (state == READY);

    reg sqrt_start;
    wire sqrt_ready;
    wire [3:0] sqrt_b;
    wire [2:0]  funcControlSrc;
    wire [7:0]  partASrc;
    wire [7:0]  partBSrc;
    
    sqrt sqrt_func(
        .clk_i      (clk),
        .rst_i      (rst_n),
        .start_i    (sqrt_start),
        .x_bi       (b),
        .partRes    (partRes),
        .partA      (partASrc),
        .partB      (partBSrc),
        .oper       (funcControlSrc),
        .ready_o    (sqrt_ready),
        .y_bo       (sqrt_b)
    );
 
 
    reg cub_start;
    wire cub_ready;
    wire [2:0] cub_res;
    wire [2:0]  funcControlCub;
    wire [7:0]  partACub;
    wire [7:0]  partBCub;
    
     cub cub_func(
        .clk_i(clk),
        .rst_i(rst_n),
        .x_bi(125),
        .start_i(cub_start),
        .ready_o(cub_ready),
        .y_bo(cub_res)
    );
    
    assign funcControl = sqrt_ready ? funcControlCub : funcControlSrc;
    assign  partA = sqrt_ready ? partACub : partASrc;
    assign  partB = sqrt_ready ? partBCub : partBSrc;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin      
            cub_part_res <= 0;
            result <= 0;           
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                begin
                    if(start) begin
                        $display("FUNC START");
                        sqrt_start <= 1;
                        state <= ADD;
                    end
                    end
                ADD:
                    begin
                     if (sqrt_start == 1) begin
                                sqrt_start <= 0;
                            end else
                                 if(sqrt_ready) begin
                                    cub_part_res <= (a + sqrt_b);
                                    $display("SQRT %d", sqrt_b);
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
                                    result <= cub_res;
                                    $display("CUB %d", cub_res);
                                    state <= READY;
                                end
                    end
            endcase
        end 
  
   
endmodule
