module Forward(

        //MODULE INPUTS
        input CLOCK,                                                                       
        input RESET,

        //ID --> FORWARD
        input       if_jump_RegisterID_IN,
        input [4:0] jump_RegisterID_IN,
        input       if_branchID_IN,
        input  [4:0] RegisterRSID_IN,
        input  [4:0] RegisterRTID_IN,
        input   [31:0] branch_operandA_IN,
        input   [31:0] branch_operandB_IN,
        
        //ID/EXE --> FORWARD
        input   [31:0] _operandA_IN,
        input   [31:0] _operandB_IN,

        input   [4:0] _RegisterRS_IN,
        input   [4:0] _RegisterRT_IN,

        input       if_immediateIDEXE_IN,

        input   if_JumpRegisterIDEXE_IN,
        input   if_JumpIDEXE_IN,

        input   [4:0] writeRegister_IN,
        input   WritEnableIDEXE_IN,

        input   if_memWriteIDEXE_IN,
        input   [31:0] memWriteDataIDEXE_IN,

        input   if_memReadIDEXE_IN,

        //EXE --> FORWARD
        input   [31:0] AluResultEXE_IN,

        //EXE/MEM --> FORWARD
        input   [31:0] RegvalueEXEMEM_IN,
        input   [4:0] RegisterEXEMEM_IN,
        input       if_memReadEXEMEM_IN,
        input       if_memWriteEXEMEM_IN,
	    input [31:0] memWriteDataEXEMEM_IN,
        input       WriteEnableEXEMEM_IN,

        //MEM --> FORWARD
        input  [31:0] MEMREADDATA_IN,
        
        //MEM/WB --> FORWARD
        input   [31:0] RegvalueMEMWB_IN,
        input   [4:0] RegisterMEMWB_IN,
        input       WriteEnableMEMWB_IN,

		//Regfile WB --> FORWARD
        input [31:0] _RegisterValue_IN,		
		input [4:0] _Register_IN,
        input       write_IN,
		/******************************/
        //MODULE OUTPUTS
        //FORWARD --> EXE
        output  [31:0] _operandA_OUT,
        output  [31:0] _operandB_OUT,
        output _forward,
        output  [31:0] S_operandA_OUT,
        output  [31:0] S_operandB_OUT,

        //FORWARD --> IF
        output [31:0]  jump_Register,
        output  _forwardIF,

        //FORWARD --> ID
        output [31:0] branch_operandA_OUT,
        output [31:0] branch_operandB_OUT,
        output  branch_Forward,

        //FORWARD --> MEM
        //connect to exemem and exe
        output mem_forward,
        output [31:0] memWriteData_OUT,

        //FORWARD --> HAZARD
        output STALL_OUT


);
  
wire [4:0] RegDEXE;
wire [4:0] RegDMEM;
wire [4:0] RegS;
wire [4:0] RegT;
wire [4:0]	RegWB;


reg     [31:0] _operandA;
reg     [31:0] _operandB;
reg             _forward_;
reg             _forward2;
reg     [31:0] _jump_Register;
/************************/
reg [31:0] branch_operandA;
reg [31:0] branch_operandB;
reg _forward3;
/***********************/

reg [31:0]  S_operandA;
reg [31:0]  S_operandB;
reg [31:0] memdata;
reg _forward4;
reg Stall;

assign RegS = _RegisterRS_IN;
assign RegT = _RegisterRT_IN;

assign RegDEXE = RegisterEXEMEM_IN;
assign RegDMEM = RegisterMEMWB_IN;
assign RegWB  = _Register_IN;

assign _operandA_OUT = _operandA;
assign _operandB_OUT = _operandB;
assign jump_Register = _jump_Register;

assign branch_operandA_OUT = branch_operandA;
assign branch_operandB_OUT = branch_operandB;
assign branch_Forward = _forward3;

assign S_operandA_OUT   = S_operandA;
assign S_operandB_OUT   = S_operandB;
assign mem_forward = _forward4;
assign memWriteData_OUT = memdata;

assign _forward = _forward_;
assign _forwardIF = _forward2;

assign STALL_OUT = Stall;

/******************************************************/
/******************************************************/
// 1st always
/*forwarding for ALU operations(register).
It makes sure that immediates are not overwritten if instruction
has an immediate that coincides with register number
It does not forward for jumps, branches, loads and stores
*/
always @(negedge CLOCK or negedge RESET) begin
    if(!RESET)begin
        _operandA <= 0;
        _operandB <= 0;
        _forward_ <= 1'b0;
       
    end
    
    if(!CLOCK)begin
        /******************************************************/
        // if(!if_memWriteIDEXE_IN && !if_memReadIDEXE_IN)begin    //makes sure this unit does not forward for loads and stores
            if((RegS == RegDEXE) && WriteEnableEXEMEM_IN && !if_JumpRegisterIDEXE_IN && !if_JumpIDEXE_IN)begin //if RS at IDEXE == dest reg at EXEMEM and dest reg is written to and instr is not a jump
                _operandA <= RegvalueEXEMEM_IN;
                
                if((RegT == RegDEXE) && WriteEnableEXEMEM_IN/*&& !if_immediateIDEXE_IN*/)begin //if RT == dest reg at EXEMEM and dest reg is written to
                    if(!if_immediateIDEXE_IN)begin                                          //forward if not immediate
                        _operandB <= RegvalueEXEMEM_IN;
                    end
                    else begin                                                              //do not forward if immediate
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end

                else if((RegT == RegDMEM) && WriteEnableMEMWB_IN/*&& !if_immediateIDEXE_IN*/)begin  //if RT == dest reg at MEMWB and dest reg is written to
                    if(!if_immediateIDEXE_IN)begin
                        _operandB <= RegvalueMEMWB_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end

                else if((RegT == RegWB)&&write_IN /*&& !if_immediateIDEXE_IN*/)begin    //if RT == dest reg at RegFile and dest reg is written to
                    if(!if_immediateIDEXE_IN)begin
                        _operandB <= _RegisterValue_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end

                else begin      //else do not forward for second operand
                    _operandB <= _operandB_IN;
                    _forward_ <= 1'b1;
                    
                end
            end

            /******************************************************/
            else if ((RegS ==RegDMEM) && WriteEnableMEMWB_IN && !if_JumpRegisterIDEXE_IN && !if_JumpIDEXE_IN/*(RegT || RegS)*/)begin    //if RS at IDEXE == dest reg at MEMWB and dest reg is written to and instr is not a jump
                _operandA <= RegvalueMEMWB_IN;
                if((RegT == RegDEXE) && WriteEnableEXEMEM_IN/*&& !if_immediateIDEXE_IN*/)begin
                    if(!if_immediateIDEXE_IN)begin
                        _operandB <= RegvalueEXEMEM_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end

                else if((RegT == RegDMEM) && WriteEnableMEMWB_IN/*&& !if_immediateIDEXE_IN*/)begin
                    if(!if_immediateIDEXE_IN)begin
                        _operandB <= RegvalueMEMWB_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end

                else if((RegT == RegWB)&&write_IN /*&& !if_immediateIDEXE_IN*/)begin
                    if(!if_immediateIDEXE_IN)begin
                        _operandB <= _RegisterValue_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end

                else begin
                   
                    _operandB <= _operandB_IN;
                    _forward_ <= 1'b1;
                end
            end
            
            /******************************************************/
            else if((RegS == RegWB)&& write_IN && /*(RegT || RegS)*/!if_JumpRegisterIDEXE_IN && !if_JumpIDEXE_IN)begin  //if RS at IDEXE == dest reg at Regfile and dest reg is written to and instr is not a jump
                _operandA <= _RegisterValue_IN;

                if((RegT == RegDEXE) && WriteEnableEXEMEM_IN/*&& !if_immediateIDEXE_IN*/)begin
                   _operandA <= _RegisterValue_IN;
                    if(!if_immediateIDEXE_IN) begin
                        _operandB <= RegvalueEXEMEM_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end

                else if((RegT == RegDMEM) && WriteEnableMEMWB_IN/*&& !if_immediateIDEXE_IN*/)begin
                    if(!if_immediateIDEXE_IN)begin
                        _operandB <= RegvalueMEMWB_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end

                else if((RegT == RegWB)&& write_IN/*&& !if_immediateIDEXE_IN*/)begin
                    if(!if_immediateIDEXE_IN) begin
                        _operandB <= _RegisterValue_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end

                else begin
                    _operandB <= _operandB_IN;
                    _forward_ <= 1'b1;
                end
            end

            /******************************************************/
            else begin      //else do not forward for first operand
                _operandA <= _operandA_IN;

                if((RegT == RegDEXE) && WriteEnableEXEMEM_IN/*&& !if_immediateIDEXE_IN&& (RegT || RegS)*/ && !if_JumpRegisterIDEXE_IN && !if_JumpIDEXE_IN)begin
                    if(!if_immediateIDEXE_IN)begin
                        _operandB <= RegvalueEXEMEM_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end
                else if((RegT == RegDMEM)/*&& !if_immediateIDEXE_IN && (RegT || RegS)*/ && !if_JumpRegisterIDEXE_IN && !if_JumpIDEXE_IN && WriteEnableMEMWB_IN)begin
                    if(!if_immediateIDEXE_IN)begin
                        _operandB <= RegvalueMEMWB_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end
                else if((RegT == RegWB)&& write_IN /*&& !if_immediateIDEXE_IN && (RegT || RegS)*/ && !if_JumpRegisterIDEXE_IN && !if_JumpIDEXE_IN)begin
                    if(!if_immediateIDEXE_IN)begin
                        _operandB <= _RegisterValue_IN;
                    end
                    else begin
                        _operandB <= _operandB_IN;
                    end
                    _forward_ <= 1'b1;
                end
                else begin
                    _forward_ <= 1'b0;
                end
            end  
        
        end
    // end
    
end //1st always end

/******************************************************/
/******************************************************/
//2nd always
/*forwarding for jump register
It does not forward for jump, branch, ALU, load/store operation
*/

always begin
    if(if_jump_RegisterID_IN)begin      //if it is a jump register

        if((jump_RegisterID_IN == writeRegister_IN) && WritEnableIDEXE_IN)begin //if jump register == dest reg at IDEXE and dest reg is written to
            Stall = 1'b1;
        end
        else if((jump_RegisterID_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin //if jump register == dest reg at EXEMEM and dest reg is written to

            if(!if_memReadEXEMEM_IN)begin                               
                _jump_Register = RegvalueEXEMEM_IN;
            end
            else if(if_memReadEXEMEM_IN)begin
                _jump_Register = MEMREADDATA_IN;
            end

            _forward2 = 1'b1;
        end

        else if((jump_RegisterID_IN == RegDMEM) && WriteEnableMEMWB_IN)begin

            _jump_Register = RegvalueMEMWB_IN;
            _forward2 = 1'b1;

        end

        else if((jump_RegisterID_IN==RegWB) && write_IN) begin
            _jump_Register = _RegisterValue_IN;
            _forward2 = 1'b1;
        end

        else begin
            _forward2 = 1'b0;
        end
    end

end //2nd always ends




/******************************************************/
/******************************************************/
//3rd always
/*forwarding for branches
*/
always begin
    if(if_branchID_IN )begin
        if((RegisterRSID_IN ==writeRegister_IN) && WritEnableIDEXE_IN)begin
            Stall = 1'b1;
            //RT
            if((RegisterRTID_IN == writeRegister_IN) && WritEnableIDEXE_IN)begin
                Stall = 1'b1;
            end
            else if((RegisterRTID_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
                if(!if_memReadEXEMEM_IN)begin
                    branch_operandB = RegvalueEXEMEM_IN;
                end
                else if(if_memReadEXEMEM_IN)begin
                    branch_operandB = MEMREADDATA_IN;
                end
                _forward3 = 1'b1;
            end
            else if((RegisterRTID_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
                    branch_operandB = RegvalueMEMWB_IN;
                _forward3 = 1'b1;
            end
            else if((RegisterRTID_IN == RegWB) && write_IN)begin
                    branch_operandB = _RegisterValue_IN;
                _forward3 = 1'b1;
            end
            else begin
                branch_operandB = branch_operandB_IN;
                _forward3 = 1'b1; 
            end
    
        end
        else if((RegisterRSID_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
            if(!if_memReadEXEMEM_IN)begin
                branch_operandA = RegvalueEXEMEM_IN;
            end
            else if(if_memReadEXEMEM_IN)begin
                branch_operandA = MEMREADDATA_IN;
            end

            //RT
            if((RegisterRTID_IN == writeRegister_IN) && WritEnableIDEXE_IN)begin
                Stall = 1'b1;
                
            end
            else if((RegisterRTID_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
                if(!if_memReadEXEMEM_IN)begin
                    branch_operandB = RegvalueEXEMEM_IN;
                end
                else if(if_memReadEXEMEM_IN)begin
                    branch_operandB = MEMREADDATA_IN;
                end

                _forward3 = 1'b1;
            end
            else if((RegisterRTID_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
                    branch_operandB = RegvalueMEMWB_IN;
                _forward3 = 1'b1;
            end
            else if((RegisterRTID_IN == RegWB) && write_IN)begin
                    branch_operandB = _RegisterValue_IN;
                _forward3 = 1'b1;
            end
            else begin
                branch_operandB = branch_operandB_IN;
                _forward3 = 1'b1; 
            end
        end


        else if((RegisterRSID_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
                branch_operandA = RegvalueMEMWB_IN;
            
           //RT
            if((RegisterRTID_IN == writeRegister_IN) && WritEnableIDEXE_IN)begin
                // if(!if_memReadIDEXE_IN)begin
                Stall = 1'b1;
                
            end
            else if((RegisterRTID_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
                if(!if_memReadEXEMEM_IN)begin
                    branch_operandB = RegvalueEXEMEM_IN;
                end
                else if(if_memReadEXEMEM_IN)begin
                    branch_operandB = MEMREADDATA_IN;
                end

                _forward3 = 1'b1;
            end
            else if((RegisterRTID_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
                    branch_operandB = RegvalueMEMWB_IN;
                _forward3 = 1'b1;
            end
            else if((RegisterRTID_IN == RegWB) && write_IN)begin
                    branch_operandB = _RegisterValue_IN;
                _forward3 = 1'b1;
            end
            else begin
                branch_operandB = branch_operandB_IN;
                _forward3 = 1'b1; 
            end
        end

        
        else if((RegisterRSID_IN == RegWB) && write_IN)begin
                branch_operandA = _RegisterValue_IN;

           //RT
            if((RegisterRTID_IN == writeRegister_IN) && WritEnableIDEXE_IN)begin
                Stall = 1'b1;
                
            end
            else if((RegisterRTID_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
                if(!if_memReadEXEMEM_IN)begin
                    branch_operandB = RegvalueEXEMEM_IN;
                end
                else if(if_memReadEXEMEM_IN)begin
                    branch_operandB = MEMREADDATA_IN;
                end
                _forward3 = 1'b1;
            end
            else if((RegisterRTID_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
                    branch_operandB = RegvalueMEMWB_IN;
                _forward3 = 1'b1;
            end
            else if((RegisterRTID_IN == RegWB) && write_IN)begin
                    branch_operandB = _RegisterValue_IN;
                _forward3 = 1'b1;
            end
            else begin
                branch_operandB = branch_operandB_IN;
                _forward3 = 1'b1; 
            end
        end

        //else
        else begin
            branch_operandA = branch_operandA_IN;
            if((RegisterRTID_IN == writeRegister_IN) && WritEnableIDEXE_IN)begin
                Stall = 1'b1;
                
            end
            else if((RegisterRTID_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
                if(!if_memReadEXEMEM_IN)begin
                    branch_operandB = RegvalueEXEMEM_IN;
                end
                else if(if_memReadEXEMEM_IN)begin
                    branch_operandB = MEMREADDATA_IN;
                end

                _forward3 = 1'b1;
            end
            else if((RegisterRTID_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
                    branch_operandB = RegvalueMEMWB_IN;
                _forward3 = 1'b1;
            end
            else if((RegisterRTID_IN == RegWB) && write_IN)begin
                    branch_operandB = _RegisterValue_IN;
                _forward3 = 1'b1;
            end
            else begin
                branch_operandB = branch_operandB_IN;
                _forward3 = 1'b0; 
            end
        end
    end
end //3rd always ends

/******************************************************/
/******************************************************/
//4th always
/*this for when stores follow an instruction
*/
always @(negedge CLOCK) begin
    if(if_memWriteIDEXE_IN)begin
        S_operandB <= _operandB_IN;
        //RS
        if((_RegisterRS_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
            if(if_memReadEXEMEM_IN)begin
                S_operandA <= MEMREADDATA_IN;
            end
            
            else if(!if_memReadEXEMEM_IN && !if_memWriteEXEMEM_IN) begin
                _operandA <= RegvalueEXEMEM_IN;
            end
            //RT
            if((_RegisterRT_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
                if(if_memReadEXEMEM_IN)begin
                    memdata <= MEMREADDATA_IN;
                end
              
                else if(!if_memReadEXEMEM_IN && !if_memWriteEXEMEM_IN) begin
                    memdata <= RegvalueEXEMEM_IN;
                end
            end

            else if((_RegisterRT_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
                memdata <= RegvalueMEMWB_IN;
            end

            else if((_RegisterRT_IN == RegWB) && write_IN)begin
                memdata <= _RegisterValue_IN;
            end

            else begin
                memdata <= memWriteDataIDEXE_IN;
            end
            _forward4 <= 1'b1;
        end

        //RS
        else if((_RegisterRS_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
            S_operandA <= RegvalueMEMWB_IN;
            //RT
            if((_RegisterRT_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
                if(if_memReadEXEMEM_IN)begin
                    memdata <= MEMREADDATA_IN;
                end
               
                else if(!if_memReadEXEMEM_IN && !if_memWriteEXEMEM_IN)begin
                    memdata <= RegvalueEXEMEM_IN;
                end
            end

            else if((_RegisterRT_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
                memdata <= RegvalueMEMWB_IN;
            end

            else if((_RegisterRT_IN == RegWB) && write_IN)begin
                memdata <= _RegisterValue_IN;
            end

            else begin
                memdata <= memWriteDataIDEXE_IN;
            end
            _forward4 <= 1'b1;
        end
        //RS
        else if((_RegisterRS_IN == RegWB) && write_IN)begin
            S_operandA <= _RegisterValue_IN;
            //RT
           if((_RegisterRT_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
                if(if_memReadEXEMEM_IN)begin
                    memdata <= MEMREADDATA_IN;
                end
                
                else if(!if_memReadEXEMEM_IN && !if_memWriteEXEMEM_IN)begin
                    memdata <= RegvalueEXEMEM_IN;
                end
            end

            else if((_RegisterRT_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
                memdata <= RegvalueMEMWB_IN;
            end

            else if((_RegisterRT_IN == RegWB) && write_IN)begin
                memdata <= _RegisterValue_IN;
            end

            else begin
                memdata <= memWriteDataIDEXE_IN;
            end
            _forward4 <= 1'b1;
        end

        else begin
            S_operandA <= _operandA_IN;
            if((_RegisterRT_IN == RegDEXE) && WriteEnableEXEMEM_IN)begin
                if(if_memReadEXEMEM_IN)begin
                    memdata <= MEMREADDATA_IN;
                end
                
                else if(!if_memReadEXEMEM_IN && !if_memWriteEXEMEM_IN)begin
                    memdata <= RegvalueEXEMEM_IN;
                end
                _forward4 <= 1'b1;
            end

            else if((_RegisterRT_IN == RegDMEM) && WriteEnableMEMWB_IN)begin
                memdata <= RegvalueMEMWB_IN;
                _forward4 <= 1'b1;
            end

            else if((_RegisterRT_IN == RegWB) && write_IN)begin
                memdata <= _RegisterValue_IN;
                _forward4 <= 1'b1;
            end

            else begin
                memdata <= memWriteDataIDEXE_IN;
                _forward4 <= 1'b0;
            end
        end

    end
end //4th always end

/******************************************************/
/******************************************************/

//5th always
/*forwarding for loads
*/
always @(negedge CLOCK)begin
    if(if_memReadIDEXE_IN) begin
        S_operandB <= _operandB_IN;
        if((_RegisterRS_IN == RegDEXE)&& WriteEnableEXEMEM_IN)begin  //if regs in ID/EXE == EXE/MEM
            if(if_memReadEXEMEM_IN)begin // if EXE/MEM is reading from memory
                S_operandA <= MEMREADDATA_IN; // data read into MEM put into operand
            end
          
            else if (!if_memReadEXEMEM_IN && !if_memWriteEXEMEM_IN)begin
                S_operandA <= RegvalueEXEMEM_IN; // reg value from EXEMEM
            end
            _forward4 <= 1'b1;
        end
        // _RegisterRT_IN will be replaced with data, so no need to forward to it
        
        else if((_RegisterRS_IN == RegDMEM) && WriteEnableMEMWB_IN)begin // if regs in ID/EXE == MEM/WB
            S_operandA <= RegvalueMEMWB_IN;
            _forward4 <= 1'b1;
        end

        else if((_RegisterRS_IN == RegWB) && write_IN)begin
            S_operandA <= _RegisterValue_IN;
            _forward4 <= 1'b1;
        end

        else begin
            S_operandA <= _operandA_IN;
            _forward4 <= 1'b0;
        end
    end
end //5th always ends

/******************************************************/
/******************************************************/
//6th always
/*this sets the forwarding bit for jump register and branch to zero after it has been forwarded
*/
always @(posedge CLOCK)begin
    _forward_ <= 1'b0;
    _forward4 <= 1'b0;
    _forward2 = 1'b0;
    _forward3 = 1'b0;
    Stall = 1'b0;
end //6th always ends

endmodule
