module IF(

        //MODULE INPUTS

                //SYSTEM --> IF
                input CLOCK,
                input RESET,
                input STALL,

                //ID --> IF
                input [31:0]    AltPC_IN,
                input           AltPCEnable_IN,
                input [31:0]		jump_RegisterFOR_IN,
		input		_Forward,

        //MODULE OUTPUTS

                //IF --> IF/ID
                output [31:0]   InstructionAddressPlus4_OUT,

                //IF --> IM
                output [31:0]   InstructionAddress_OUT

);

reg [31:0]      ProgramCounter/*verilator public*/;
reg             BranchEnable;
reg [31:0]      BranchTarget;
wire [31:0]     IncrementAmount = 32'd4;

assign          InstructionAddressPlus4_OUT     = ProgramCounter + IncrementAmount;
assign          InstructionAddress_OUT          = ProgramCounter;

//WHEN CLOCK RISES OR RESET FALLS
always @(posedge CLOCK or negedge RESET) begin

        //IF RESET IS LOW
        if(!RESET) begin

                BranchTarget    = 0;
                BranchEnable    = 0;
                ProgramCounter  = 32'hBFC00000; /* START OF BOOT SEQUENCE */

        end 
        //ELSE IF CLOCK IS HIGH
        else if(CLOCK) begin
                $display("");
                $display("----- IF -----");
                $display("ProgramCounter:\t\t%x", ProgramCounter);
                if(!STALL)begin
                BranchTarget    = BranchEnable ? BranchTarget : AltPC_IN;
                BranchEnable    = !STALL ? (BranchEnable ? 1 : AltPCEnable_IN) : 0;
                end
                $display("BranchEnable:\t\t%d", BranchEnable);
                $display("BranchTarget:\t\t%x", BranchTarget);
                //SET PROGRAM COUNTER TO EITHER BRANCH OR NEXT INSTRUCTION
                if(!STALL)begin
                        ProgramCounter = BranchEnable ? BranchTarget : InstructionAddressPlus4_OUT;
                end
                BranchEnable = 0;
                //ELSE IF THE MODULE IS BEING STALLED

                if(STALL) begin
                        //DO NOTHING
                end

        end
end

always begin
        if(_Forward)begin
                BranchTarget = jump_RegisterFOR_IN;
                BranchEnable = 1'b1;
        end
end

endmodule