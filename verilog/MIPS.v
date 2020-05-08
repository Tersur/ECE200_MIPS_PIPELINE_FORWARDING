//-----------------------------------------
//	5-Stage Multicycle MIPS I
//-----------------------------------------
module MIPS (

	/* NOTE 
 	 * The names of these inputs/outputs cannot be changed.
 	 * They are referenced directly by the test bench.
 	 * Renaming will result in the program failing to compile.
 	 */

	//MODULE INPUTS
	
		input 		CLOCK,
		input 		RESET,	

		input [31:0] 	Instruction_IN,		//INSTRUCTION FROM INSTRUCTION MEMORY
		input [31:0] 	Data_IN,		//DATA FROM DATA MEMORY

		/* verilator lint_off UNUSED */
		input [255:0]	InstructionBlock_IN,
		input [255:0]	DataBlock_IN,
		/* verilator lint_on UNUSED */

	//MODULE OUTPUTS
	
		output [31:0] 	InstructionAddress_OUT,	//ADDRESS OF INSTRUCTION TO FETCH FROM INSTRUCTION MEMORY
		output [31:0] 	DataAddress_OUT,	//ADDRESS OF DATA MEMORY WE WANT TO INTERACT WITH (Read/Write)
	
		/* NOTE
 		 * DataSize_OUT follows the convention:
 		 * 1 byte: 	1
 		 * 2 bytes:  	2
 		 * 3 bytes: 	3
 		 * 4 bytes: 	0
 		 */
	
		output [31:0] 	Data_OUT,		//DATA TO WRITE TO DATA MEMORY		
		output [1:0] 	DataSize_OUT,		//NUMBER OF BYTES TO WRITE TO DATA MEMORY
		output 		MemRead_OUT,		//TELL DATA MEMORY WE WANT TO READ
		output 		MemWrite_OUT,		//TELL DATA MEMORY WE WANT TO WRITE	
		
		output 		SYS,			//TELL THE SYSTEM TO EXECUTE A SYSCALL

		/* verilator lint_off UNUSED */
		output [255:0] 	DataBlock_OUT,		//Data being written
		output 		MemBlockRead_OUT,	//Request a block read
		output 		MemBlockWrite_OUT	//Request a block write
		/* verilator lint_on UNUSED */
	
);

//-----------------------------------
//WIRES ORIGINATING FROM THE IF STAGE
//-----------------------------------

	//IF --> IF/ID
	wire [31:0]	InstructionAddressPlus4_IFtoIFID;

	//IF --> IM
	wire [31:0]	InstructionAddress_IFtoIM;

//-----------------------------------------
//WIRES ORIGINATING FROM THE IF/ID REGISTER
//-----------------------------------------

	//IF/ID --> ID
	wire [31:0] Instruction_IFIDtoID;
	wire [31:0] InstructionAddressPlus4_IFIDtoID;
	wire b_STALL;
//-----------------------------------
//WIRES ORIGINATING FROM THE ID STAGE
//-----------------------------------

	//ID --> IF
	wire [31:0]	AltPC_IDtoIF;
	wire 		AltPCEnable_IDtoIF;
	
	//ID --> ID/EXE
	wire [31:0]	OperandA_IDtoIDEXE;
	wire [31:0]	OperandB_IDtoIDEXE;
	wire [5:0]	ALUControl_IDtoIDEXE;
	wire [4:0]	ShiftAmount_IDtoIDEXE; 

	wire [31:0]	MemWriteData_IDtoIDEXE;
	wire		MemRead_IDtoIDEXE;
	wire		MemWrite_IDtoIDEXE;

	wire [4:0]	WriteRegister_IDtoIDEXE;
	wire 		WriteEnable_IDtoIDEXE;
	
	/***********************************/
	wire [4:0]	b_RegisterRS_IDtoIDEXE;
	wire [4:0]	b_RegisterRT_IDtoIDEXE;
	wire b_immed_IDtoIDEXE;
	wire b_branchID;

	//ID --> HAZARD
	wire	b_SYS;

	//ID --> FORWARD
	wire [31:0]	b_regvalueRegfile_IDtoFOR;
	wire [4:0]  b_regRegfile_IDtoFOR;
	wire	b_writeEnable_IDtoFOR;
	wire	b_jump_IDtoFOR;
	wire	b_jumpIDEXE;
	/***********************************/

//------------------------------------------
//WIRES ORIGINATING FROM THE ID/EXE REGISTER
//------------------------------------------

	//ID/EXE --> EXE
	wire [31:0] 	OperandA_IDEXEtoEXE;
	wire [31:0] 	OperandB_IDEXEtoEXE;
	wire [5:0]  	ALUControl_IDEXEtoEXE;
	wire [4:0]  	ShiftAmount_IDEXEtoEXE;

	//ID/EXE --> EXE/MEM
	wire [31:0] 	MemWriteData_IDEXEtoEXEMEM;
	wire        	MemRead_IDEXEtoEXEMEM;
	wire        	MemWrite_IDEXEtoEXEMEM;

	wire [4:0]  	WriteRegister_IDEXEtoEXEMEM;
	wire        	WriteEnable_IDEXEtoEXEMEM;
	
	/***********************************/
	//IDEXE --> FORWARD
	wire [4:0]	b_RegisterRS_IDEXEtoFORWARD;
	wire [4:0]	b_RegisterRT_IDEXEtoFORWARD;
	wire b_immed_IDEXEtoFOR;
	wire b_jump_IDEXEtoFOR;
	wire b_jump_FOR;
	/***********************************/

//------------------------------------
//WIRES ORIGINATING FROM THE EXE STAGE
//------------------------------------

	//EXE --> EXE/MEM
	wire [31:0] 	ALUResult_EXEtoEXEMEM;

//-------------------------------------------
//WIRES ORIGINATING FROM THE EXE/MEM REGISTER
//-------------------------------------------

	//EXE/MEM --> MEM
	wire [31:0] 	MemWriteData_EXEMEMtoMEM;
	wire [5:0] 	MemControl_EXEMEMtoMEM;
	wire 		MemRead_EXEMEMtoMEM;

	wire [31:0] 	ALUResult_EXEMEMtoMEM;

	//EXE/MEM --> MEM/WB
	wire [4:0] 	WriteRegister_EXEMEMtoMEMWB;
	wire 		WriteEnable_EXEMEMtoMEMWB;

	//EXE/MEM --> DM
	wire		MemWrite_EXEMEMtoDM;

//------------------------------------
//WIRES ORIGINATING FROM THE MEM STAGE
//------------------------------------

	//MEM --> MEM/WB
	wire [31:0] 	WriteData_MEMtoMEMWB;

	//MEM --> DM
	wire [31:0]	Data_MEMtoDM;
	wire [1:0]	DataSize_MEMtoDM;

//------------------------------------------
//WIRES ORIGINATING FROM THE MEM/WB REGISTER
//------------------------------------------

	//MEM/WB --> ID	
	wire [31:0] 	WriteData_MEMWBtoID;
	wire [4:0]  	WriteRegister_MEMWBtoID;
	wire        	WriteEnable_MEMWBtoID;

//-----------------------------------------
//WIRES ORIGINATING FROM INSTRUCTION MEMORY
//-----------------------------------------

	//IM --> IF/ID
	wire [31:0] 	Instruction_IMtoIFID;

//----------------------------------
//WIRES ORIGINATING FROM DATA MEMORY
//----------------------------------

	//DM --> MEM
	wire [31:0]	Data_DMtoMEM;

//------------------------------------------
//WIRES ORIGINATING FROM THE FORWARDING UNIT
//------------------------------------------


//------------------------------------------------
//WIRES ORIGINATING FROM THE HAZARD DETECTION UNIT
//------------------------------------------------

	//HAZARD --> IF/ID
	wire 	STALL_toIFID;
	wire 	FLUSH_toIFID;

	//HAZARD --> ID/EXE
	wire 	STALL_toIDEXE;
	wire 	FLUSH_toIDEXE;

	//HAZARD --> EXE/MEM
	wire 	STALL_toEXEMEM;
	wire 	FLUSH_toEXEMEM;

	//HAZARD --> MEM/WB
	wire 	STALL_toMEMWB;
	wire 	FLUSH_toMEMWB;

/***********************************/
//------------------------------------------------
//WIRES ORIGINATING FROM THE FORWARD UNIT
//------------------------------------------------
	
	wire [31:0] b_operandA_OUT;
	wire [31:0] b_operandB_OUT;
	wire [31:0] sb_operandA_OUT;
	wire [31:0] sb_operandB_OUT;

	wire		b_forward;

	wire [31:0] b_jump_Register;
	wire		b_forwardIF;

	wire [31:0] b_branch_operandA;
	wire [31:0] b_branch_operandB;
	wire		b_branch;

	wire		b_mem_forward;
	wire [31:0] b_mem_write_data;
/***********************************/

//DISABLE BLOCK READ/WRITE
assign MemBlockRead_OUT		= 1'b0;
assign MemBlockWrite_OUT	= 1'b0;
assign DataBlock_OUT		= 256'b0;

//PROCESSOR INPUTS
assign Instruction_IMtoIFID 	= Instruction_IN;
assign Data_DMtoMEM 		= Data_IN;

//PROCESSOR OUTPUTS
assign InstructionAddress_OUT 	= InstructionAddress_IFtoIM; 
assign Data_OUT 		= Data_MEMtoDM;
assign DataAddress_OUT 		= ALUResult_EXEMEMtoMEM;
assign DataSize_OUT 		= DataSize_MEMtoDM;
assign MemRead_OUT 		= MemRead_EXEMEMtoMEM;
assign MemWrite_OUT 		= MemWrite_EXEMEMtoDM;

//INSTRUCTION FETCH STAGE
IF IF(

	//MODULE INPUTS
		
		//CONTROL SIGNALS
		.CLOCK(CLOCK),	
		.RESET(RESET),		
		.STALL(STALL_toIFID),

		//ID --> IF
		.AltPC_IN(AltPC_IDtoIF),
		.AltPCEnable_IN(AltPCEnable_IDtoIF),
		//FORWARD --> ID		
		.jump_RegisterFOR_IN(b_jump_Register),
		._Forward(b_forwardIF),
	//MODULE OUTPUTS
	
		//IF --> IF/ID
		.InstructionAddressPlus4_OUT(InstructionAddressPlus4_IFtoIFID),
		
		//IF --> IM
		.InstructionAddress_OUT(InstructionAddress_IFtoIM)


);

//IF/ID REGISTER
IFID IFID(

	//MODULE INPUTS

		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		.STALL(STALL_toIFID),
		.FLUSH(FLUSH_toIFID),

		//INFORMATION FOR ID STAGE
		.Instruction_IN(Instruction_IMtoIFID),
		.InstructionAddressPlus4_IN(InstructionAddressPlus4_IFtoIFID),

	//MODULE OUTPUTS
	
		//INFORMATION FOR ID STAGE
		.Instruction_OUT(Instruction_IFIDtoID),
		.InstructionAddressPlus4_OUT(InstructionAddressPlus4_IFIDtoID)

);

//INSTRUCTION DECODE STAGE
ID ID(

	//MODULE INPUTS
	
		//GLOBAL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),	

		//MEM/WB --> ID	
		.WriteEnable_IN(WriteEnable_MEMWBtoID),
		.WriteData_IN(WriteData_MEMWBtoID),	
		.WriteRegister_IN(WriteRegister_MEMWBtoID),

		//IF/ID --> ID
		.Instruction_IN(Instruction_IFIDtoID),
		.InstructionAddressPlus4_IN(InstructionAddressPlus4_IFIDtoID),

		//FORWARD --> ID
		.branch_operandA_IN(b_branch_operandA),
		.branch_operandB_IN(b_branch_operandB),
		.branch_Forward_IN(b_branch),


	//MODULE OUTPUTS
	
		.Syscall_OUT(b_SYS),
	
		//ID --> IF
		.AltPCEnable_OUT(AltPCEnable_IDtoIF),
		.AltPC_OUT(AltPC_IDtoIF),

		//ID --> ID/EXE	
		.OperandA_OUT(OperandA_IDtoIDEXE),
		.OperandB_OUT(OperandB_IDtoIDEXE),
		.ALUControl_OUT(ALUControl_IDtoIDEXE),
		.ShiftAmount_OUT(ShiftAmount_IDtoIDEXE),

		.MemWriteData_OUT(MemWriteData_IDtoIDEXE),
		.MemRead_OUT(MemRead_IDtoIDEXE),
		.MemWrite_OUT(MemWrite_IDtoIDEXE),

		.WriteRegister_OUT(WriteRegister_IDtoIDEXE),
		.WriteEnable_OUT(WriteEnable_IDtoIDEXE),
		
		/****************/
		.RegisterRS_OUT(b_RegisterRS_IDtoIDEXE),
		.RegisterRT_OUT(b_RegisterRT_IDtoIDEXE),
		/****************/
		.if_jumpID_OUT(b_jumpIDEXE),

		//ID --> FORWARD
		._RegisterValue_OUT(b_regvalueRegfile_IDtoFOR),		
		._Register_OUT(b_regRegfile_IDtoFOR),
		._writeEnable_OUT(b_writeEnable_IDtoFOR),
		.if_immed_OUT(b_immed_IDtoIDEXE),
		.if_jumpReg_OUT(b_jump_IDtoFOR),
		.if_branchID_OUT(b_branchID)
		/******************************/
);

//ID/EXE REGISTER
IDEXE IDEXE(

	//MODULE INPUTS
	
		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		.STALL(STALL_toIDEXE),
		.FLUSH(FLUSH_toIDEXE),

		//EXE STAGE INFORMATION	
		.OperandA_IN(OperandA_IDtoIDEXE),
		.OperandB_IN(OperandB_IDtoIDEXE),
		.ALUControl_IN(ALUControl_IDtoIDEXE),
		.ShiftAmount_IN(ShiftAmount_IDtoIDEXE),
	
		//MEM STAGE INFORMATION
		.MemWriteData_IN(MemWriteData_IDtoIDEXE),
		.MemRead_IN(MemRead_IDtoIDEXE),
		.MemWrite_IN(MemWrite_IDtoIDEXE),
		
		//WB STAGE INFORMATION
		.WriteRegister_IN(WriteRegister_IDtoIDEXE),
		.WriteEnable_IN(WriteEnable_IDtoIDEXE),	
		
		/****************/
		.RegisterRS_IN(b_RegisterRS_IDtoIDEXE),
		.RegisterRT_IN(b_RegisterRT_IDtoIDEXE),
		.immed_IN(b_immed_IDtoIDEXE),
		.jumpReg_IN(b_jump_IDtoFOR),
		.if_jumpIDEXE_IN(b_jumpIDEXE),
		/****************/

	//MODULE OUTPUTS
	
		//EXE STAGE INFORMATION
		.OperandA_OUT(OperandA_IDEXEtoEXE),
		.OperandB_OUT(OperandB_IDEXEtoEXE),
		.ALUControl_OUT(ALUControl_IDEXEtoEXE),
		.ShiftAmount_OUT(ShiftAmount_IDEXEtoEXE),
	
		//MEM STAGE INFORMATION	
		.MemWriteData_OUT(MemWriteData_IDEXEtoEXEMEM),
		.MemRead_OUT(MemRead_IDEXEtoEXEMEM),
		.MemWrite_OUT(MemWrite_IDEXEtoEXEMEM),
	
		//WB STAGE INFORMATION
		.WriteRegister_OUT(WriteRegister_IDEXEtoEXEMEM),
		.WriteEnable_OUT(WriteEnable_IDEXEtoEXEMEM),
	
		/****************/
		._RegisterRS_OUT(b_RegisterRS_IDEXEtoFORWARD),
		._RegisterRT_OUT(b_RegisterRT_IDEXEtoFORWARD),
		._immed_OUT(b_immed_IDEXEtoFOR),
		._jumpReg_OUT(b_jump_IDEXEtoFOR),
		.if_jumpIDEXE_OUT(b_jump_FOR)
		/****************/

);

//EXECUTION STAGE
EXE EXE(

	//MODULE INPUTS
		
		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),		

		//ID/EXE --> EXE
		.OperandA_IN(OperandA_IDEXEtoEXE),
		.OperandB_IN(OperandB_IDEXEtoEXE),	
		.ALUControl_IN(ALUControl_IDEXEtoEXE),
		.ShiftAmount_IN(ShiftAmount_IDEXEtoEXE),
		
		/***********************************/
		//FORWARD --> EXE
		.FOperandA_IN(b_operandA_OUT),
		.FOperandB_IN(b_operandB_OUT),
		.S_operandA_IN(sb_operandA_OUT),
		.S_operandB_IN(sb_operandB_OUT),
		.forward(b_forward),
		.Fmem_forwardIN(b_mem_forward),
		//.forwardMEM(b_forwardMEM),
		/***********************************/
	//MODULE OUTPUTS
	
		//EXE --> EXE/MEM
		.ALUResult_OUT(ALUResult_EXEtoEXEMEM)
);

//EXE/MEM REGISTER
EXEMEM EXEMEM(

	//MODULE INPUTS
	
		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		.STALL(STALL_toEXEMEM),
		.FLUSH(FLUSH_toEXEMEM),

		//INFORMATION FOR MEM STAGE
		.MemRead_IN(MemRead_IDEXEtoEXEMEM),
		.MemWrite_IN(MemWrite_IDEXEtoEXEMEM),
		.MemControl_IN(ALUControl_IDEXEtoEXE),
		.MemWriteData_IN(MemWriteData_IDEXEtoEXEMEM),

		//INFORMATION FOR WB STAGE
		.ALUResult_IN(ALUResult_EXEtoEXEMEM),
		.WriteRegister_IN(WriteRegister_IDEXEtoEXEMEM),
		.WriteEnable_IN(WriteEnable_IDEXEtoEXEMEM),
		.Fmem_data(b_mem_write_data),
		.Fmem_forwardIN(b_mem_forward),

	//MODULE OUTPUTS

		//INFORMATION FOR MEM STAGE
		.MemRead_OUT(MemRead_EXEMEMtoMEM),
		.MemWrite_OUT(MemWrite_EXEMEMtoDM),
		.MemControl_OUT(MemControl_EXEMEMtoMEM),
		.MemWriteData_OUT(MemWriteData_EXEMEMtoMEM),

		//INFORMATION FOR WB STAGE
		.ALUResult_OUT(ALUResult_EXEMEMtoMEM),
		.WriteRegister_OUT(WriteRegister_EXEMEMtoMEMWB),
		.WriteEnable_OUT(WriteEnable_EXEMEMtoMEMWB)
);

MEM MEM(

	//MODULE INPUTS
		//EXE/MEM --> MEM
		.MemRead_IN(MemRead_EXEMEMtoMEM),
		.MemControl_IN(MemControl_EXEMEMtoMEM),
		.ALUResult_IN(ALUResult_EXEMEMtoMEM),
		.MemWriteData_IN(MemWriteData_EXEMEMtoMEM),
		
		//DM --> MEM
		.Data_IN(Data_DMtoMEM),


	//MODULE OUTPUTS
		
		//MEM --> DM
		.DataSize_OUT(DataSize_MEMtoDM),	
		.Data_OUT(Data_MEMtoDM),		
		
		//MEM --> MEM/WB
		.WriteData_OUT(WriteData_MEMtoMEMWB)	
);

MEMWB MEMWB(

	//MODULE INPUTS
	
		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		.STALL(STALL_toMEMWB),
		.FLUSH(FLUSH_toMEMWB),
		//INFORMATION FOR WB STAGE
		.WriteData_IN(WriteData_MEMtoMEMWB),
		.WriteRegister_IN(WriteRegister_EXEMEMtoMEMWB),
		.WriteEnable_IN(WriteEnable_EXEMEMtoMEMWB),

	//MODULE OUTPUTS

		//INFORMATION FOR WB STAGE
		.WriteData_OUT(WriteData_MEMWBtoID),
		.WriteRegister_OUT(WriteRegister_MEMWBtoID),
		.WriteEnable_OUT(WriteEnable_MEMWBtoID)

);


Hazard Hazard(

	//MODULE INPUTS
	
		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		//ID -->HAZARD
		.Syscall_IN(b_SYS),

		//FORWARD --> HAZARD
		.STALL_IN(b_STALL),
		
	//MODULE OUTPUTS

		//HAZARD --> IF/ID
		.STALL_IFID(STALL_toIFID),
		.FLUSH_IFID(FLUSH_toIFID),

		//HAZARD --> ID/EXE
		.STALL_IDEXE(STALL_toIDEXE),
		.FLUSH_IDEXE(FLUSH_toIDEXE),

		//HAZARD --> EXE/MEM
		.STALL_EXEMEM(STALL_toEXEMEM),
		.FLUSH_EXEMEM(FLUSH_toEXEMEM),

		//HAZARD --> MEM/WB
		.STALL_MEMWB(STALL_toMEMWB),
		.FLUSH_MEMWB(FLUSH_toMEMWB),
		.Syscall_OUT(SYS)

);

Forward Forward(

	//MODULE INPUTS
	.CLOCK(CLOCK),
	.RESET(RESET),

	//ID --> FORWARDjump_RegisterID_IN
	.if_jump_RegisterID_IN(b_jump_IDtoFOR),
	.jump_RegisterID_IN(b_RegisterRS_IDtoIDEXE),
	.if_branchID_IN(b_branchID),
    .RegisterRSID_IN(b_RegisterRS_IDtoIDEXE),
    .RegisterRTID_IN(b_RegisterRT_IDtoIDEXE),
	.branch_operandA_IN(OperandA_IDtoIDEXE),
	.branch_operandB_IN(OperandB_IDtoIDEXE),

	//ID/EXE --> FORWARD
	._operandA_IN(OperandA_IDEXEtoEXE),
	._operandB_IN(OperandB_IDEXEtoEXE),
	
	._RegisterRS_IN(b_RegisterRS_IDEXEtoFORWARD),
	._RegisterRT_IN(b_RegisterRT_IDEXEtoFORWARD),
	.writeRegister_IN(WriteRegister_IDEXEtoEXEMEM),

	.if_immediateIDEXE_IN(b_immed_IDEXEtoFOR),
	.if_JumpRegisterIDEXE_IN(b_jump_IDEXEtoFOR),
	.if_JumpIDEXE_IN(b_jump_FOR),
	.if_memWriteIDEXE_IN(MemWrite_IDEXEtoEXEMEM),
	.if_memReadIDEXE_IN(MemRead_IDEXEtoEXEMEM),

	.memWriteDataIDEXE_IN(MemWriteData_IDEXEtoEXEMEM),
	.WritEnableIDEXE_IN(WriteEnable_IDEXEtoEXEMEM),
	
	//EXE --> FORWARD
	.AluResultEXE_IN(ALUResult_EXEtoEXEMEM),
	//EXE/MEM --> FORWARD
	.RegvalueEXEMEM_IN(ALUResult_EXEMEMtoMEM),
	.RegisterEXEMEM_IN(WriteRegister_EXEMEMtoMEMWB),

	.if_memReadEXEMEM_IN(MemRead_EXEMEMtoMEM), //relates to .MEMREAD_IN(WriteData_MEMtoMEMWB),
	.if_memWriteEXEMEM_IN(MemWrite_EXEMEMtoDM),
	.memWriteDataEXEMEM_IN(MemWriteData_EXEMEMtoMEM),
	.WriteEnableEXEMEM_IN(WriteEnable_EXEMEMtoMEMWB),
	
	//MEM/WB --> FORWARD
	.RegvalueMEMWB_IN(WriteData_MEMWBtoID),
	.RegisterMEMWB_IN(WriteRegister_MEMWBtoID),

	.WriteEnableMEMWB_IN(WriteEnable_MEMWBtoID),

	//MEM --> FORWARD
	.MEMREADDATA_IN(WriteData_MEMtoMEMWB),

	//RegFile/WB (ID) --> FORWARD
	._RegisterValue_IN(b_regvalueRegfile_IDtoFOR),		
	._Register_IN(b_regRegfile_IDtoFOR),
	.write_IN(b_writeEnable_IDtoFOR),

	//MODULE OUTPUTS
	//FORWARD --> IF
	.jump_Register(b_jump_Register),
	._forwardIF(b_forwardIF),

	//FORWARD --> ID
	.branch_operandA_OUT(b_branch_operandA),
    .branch_operandB_OUT(b_branch_operandB),
    .branch_Forward(b_branch),

	//FORWARD --> EXE
	._operandA_OUT(b_operandA_OUT),
	._operandB_OUT(b_operandB_OUT),
	._forward(b_forward),
	.S_operandA_OUT(sb_operandA_OUT),
	.S_operandB_OUT(sb_operandB_OUT),

	//FORWARD --> MEM
	.mem_forward(b_mem_forward),
	.memWriteData_OUT(b_mem_write_data),

	//FORWARD --> HAZARD
	.STALL_OUT(b_STALL)
	

);

endmodule
