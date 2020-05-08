module EXE(

	//MODULE INPUTS
	
		//CONTROL SIGNALS
		input CLOCK,
		input RESET,		

		//ID/EXE --> EXE
		input [31:0] 	OperandA_IN,		
		input [31:0] 	OperandB_IN,		
		input [5:0]  	ALUControl_IN,		
		input [4:0]  	ShiftAmount_IN,
		/**************************/
		//FORWARD --> EXE
		input [31:0] 	FOperandA_IN,		
		input [31:0] 	FOperandB_IN,
		input  [31:0] S_operandA_IN,
        input  [31:0] S_operandB_IN,

		input 		Alu_forward,
		input		mem_forwardIN,
		//input		forwardMEM,
		/************************/
	//MODULE OUTPUT

		//EXE --> EXE/MEM
		output [31:0] 	ALUResult_OUT		

);

reg [31:0] HI/*verilator public*/;
reg [31:0] LO/*verilator public*/;

wire [31:0] newHI;
wire [31:0] newLO;

/*******************************/	
// reg _forwardexe;
wire [31:0] OperandA;
wire [31:0] OperandB;

// assign _forwardexe = Alu_forward;
always begin
	case (Alu_forward)
		1'b0:begin
			case(mem_forwardIN)
				1'b1:begin
				OperandA = S_operandA_IN;
				OperandB = S_operandB_IN;
				end
				default: begin
				OperandA = OperandA_IN;
				OperandB = OperandB_IN;
				end
			endcase
		end
		1'b1:begin
		OperandA = FOperandA_IN;
		OperandB = FOperandB_IN;
		end

	endcase
end
/*******************************/
ALU ALU(

	//MODULE INPUTS
	.HI_IN(HI),
	.LO_IN(LO),
	.OperandA_IN(OperandA), //OperandA_IN
	.OperandB_IN(OperandB), //OperandB_IN
	.ALUControl_IN(ALUControl_IN), 
	.ShiftAmount_IN(ShiftAmount_IN), 

	//MODULE OUTPUTS
	.ALUResult_OUT(ALUResult_OUT),
	.HI_OUT(newHI),
	.LO_OUT(newLO)

);

//ON THE RISING EDGE OF THE CLOCK OR FALLING EDGE OF RESET
always @(posedge CLOCK or negedge RESET) begin

	//IF THE MODULE HAS BEEN RESET
	if(!RESET) begin

		HI <= 0;
		LO <= 0;

	//ELSE IF THE CLOCK HAS RISEN
	end else if(CLOCK) begin

		HI <= newHI;
		LO <= newLO;

		$display("");
		$display("----- EXE -----");
		$display("HI:\t%x", HI);
		$display("LO:\t%x", LO);

	end

end

endmodule
