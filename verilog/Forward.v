module Forward(

        //MODULE INPUTS
        input CLOCK,                                                                       
        input RESET,

        //ID --> FORWARD
        input       _jump_IN,
        input [4:0] jump_RegisterID,
        input       if_branchID,
        input  [4:0] RegisterRSID_IN,
        input  [4:0] RegisterRTID_IN,
        input   [31:0] branch_operandA_IN,
        input   [31:0] branch_operandB_IN,
        
        //ID/EXE --> FORWARD
        input   [31:0] _operandA_IN,
        input   [31:0] _operandB_IN,

        input   [4:0] _RegisterRS_IN,
        input   [4:0] _RegisterRT_IN,
        input       Fimmed,
        input   jumpIDEXEtoFOR,
        input   jumpFOR,
        input   [4:0] writeRegister_IN,
        input   mem_write_IN,
        input   [31:0] mem_read_data,

        //EXE --> FORWARD
        input   [31:0] aluResult_IN,

        //EXE/MEM --> FORWARD
        input   [31:0] RegvalueEXEMEM_IN,
        input   [4:0] RegisterEXEMEM_IN,
        input       mem_read_IN,
        input [31:0] MemWrite_IN,
	    input [31:0] MemWriteData_IN,

        //MEM --> FORWARD
        input  [31:0] MEMREAD_IN,
        
        //MEM/WB --> FORWARD
        input   [31:0] RegvalueMEMWB_IN,
        input   [4:0] RegisterMEMWB_IN,

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
        output [31:0] mem_write_data


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
assign mem_write_data = memdata;

assign _forward = _forward_;
assign _forwardIF = _forward2;


/******************************************************/
/******************************************************/
// 1st always
/*forwarding for register operations(ALU).
It makes sure that immediates are 
not overwritten if instruction has an immediate
It also make sure that a jump and link register does not
forward an operand to be added to register 31
*/
always @(negedge CLOCK or negedge RESET) begin
    if(!RESET)begin
        _operandA <= 0;
        _operandB <= 0;
        _forward_ <= 1'b0;
       
    end
    
    if(!CLOCK)begin
        /******************************************************/
        //if(!mem_write_IN)begin
        if((RegS == RegDEXE) && (RegT || RegS))begin
            if((RegT == RegDEXE)/*&& !Fimmed*/)begin

                if(!jumpIDEXEtoFOR || !jumpFOR)begin
                    _operandA <= RegvalueEXEMEM_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end

                if(!Fimmed)begin
                    _operandB <= RegvalueEXEMEM_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end

            else if((RegT == RegDMEM)/*&& !Fimmed*/)begin

                if(!jumpIDEXEtoFOR || !jumpFOR)begin
                    _operandA <= RegvalueEXEMEM_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end

                if(!Fimmed)begin
                    _operandB <= RegvalueMEMWB_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end

            else if((RegT == RegWB)&&write_IN /*&& !Fimmed*/)begin

                if(!jumpIDEXEtoFOR || !jumpFOR)begin
                    _operandA <= RegvalueEXEMEM_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end
                
                if(!Fimmed)begin
                    _operandB <= _RegisterValue_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end

            else begin

                if((RegS != 0) && (!jumpIDEXEtoFOR || !jumpFOR))begin
                    _operandA <= RegvalueEXEMEM_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end
                if(!Fimmed)begin
                    _operandB <= _operandB_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
                
            end
        end

        /******************************************************/
        else if ((RegS ==RegDMEM)&& (RegT || RegS))begin

            if((RegT == RegDEXE)/*&& !Fimmed*/)begin
                if(!jumpIDEXEtoFOR || !jumpFOR)begin
                    _operandA <= RegvalueMEMWB_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end
                if(!Fimmed)begin
                    _operandB <= RegvalueEXEMEM_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end

            else if((RegT == RegDMEM)/*&& !Fimmed*/)begin
                if(!jumpIDEXEtoFOR || !jumpFOR)begin
                    _operandA <= RegvalueMEMWB_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end
                
                if(!Fimmed)begin
                    _operandB <= RegvalueMEMWB_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end

            else if((RegT == RegWB)&&write_IN /*&& !Fimmed*/)begin
                if(!jumpIDEXEtoFOR || !jumpFOR)begin
                    _operandA <= RegvalueMEMWB_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end

                if(!Fimmed)begin
                    _operandB <= _RegisterValue_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end

            else begin
                if((RegS != 0)&&(!jumpIDEXEtoFOR|| !jumpFOR))begin
                    _operandA <= RegvalueMEMWB_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end
                if(!Fimmed)begin
                    _operandB <= _operandB_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
                // end
            end
        end
        
        /******************************************************/
        else if((RegS == RegWB)&&write_IN && (RegT || RegS))begin

            if((RegT == RegDEXE)/*&& !Fimmed*/)begin
                if((RegS != 0) && (!jumpIDEXEtoFOR|| !jumpFOR))begin
                    _operandA <= _RegisterValue_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end// _operandA <= _RegisterValue_IN;
                if(!Fimmed) begin
                    _operandB <= RegvalueEXEMEM_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end

            else if((RegT == RegDMEM)/*&& !Fimmed*/)begin
                if((RegS != 0) && (!jumpIDEXEtoFOR|| !jumpFOR))begin
                    _operandA <= _RegisterValue_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end

                if(!Fimmed)begin
                    _operandB <= RegvalueMEMWB_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end

            else if((RegT == RegWB)&&write_IN/*&& !Fimmed*/)begin

                if((RegS != 0) && (!jumpIDEXEtoFOR || !jumpFOR))begin
                    _operandA <= _RegisterValue_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end

                if(!Fimmed) begin
                    _operandB <= _RegisterValue_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end

            else begin
                if((RegS != 0) && (!jumpIDEXEtoFOR || !jumpFOR))begin
                    _operandA <= _RegisterValue_IN;
                end
                else begin
                    _operandA <= _operandA_IN;
                end
                if(!Fimmed)begin
                    _operandB <= _operandB_IN;
                end
                else begin
                _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end
        end

        /******************************************************/
        else begin
            if((RegT == RegDEXE)/*&& !Fimmed*/&& (RegT || RegS))begin
                _operandA <= _operandA_IN;
                if(!Fimmed)begin
                    _operandB <= RegvalueEXEMEM_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end
            else if((RegT == RegDMEM)&& !Fimmed && (RegT || RegS))begin
                _operandA <= _operandA_IN;
                if(!Fimmed)begin
                    _operandB <= RegvalueMEMWB_IN;
                end
                else begin
                    _operandB <= _operandB_IN;
                end
                _forward_ <= 1'b1;
            end
            else if((RegT == RegWB)&&write_IN /*&& !Fimmed*/&& (RegT || RegS))begin
                _operandA <= _operandA_IN;
                if(!Fimmed)begin
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
    
    //end
    end
    
end //1st always end

/******************************************************/
/******************************************************/
//2nd always
/*forwarding for jump register
*/
always begin
    if(_jump_IN)begin

        if(jump_RegisterID == writeRegister_IN)begin
            if(_RegisterRT_IN != 0)begin
                _jump_Register = aluResult_IN;
            end
            else begin
                _jump_Register = _operandA_IN;
            end
            _forward2 = 1'b1;
        end
        else if(jump_RegisterID == RegDEXE)begin

            if(!mem_read_IN)begin
                _jump_Register = RegvalueEXEMEM_IN;
            end
            else if(mem_read_IN)begin
                _jump_Register = MEMREAD_IN;
            end

            _forward2 = 1'b1;
        end

        else if(jump_RegisterID == RegDMEM)begin

            _jump_Register = RegvalueMEMWB_IN;
            _forward2 = 1'b1;

        end

        else if(jump_RegisterID==RegWB) begin
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
    if(if_branchID)begin
        if(RegisterRSID_IN ==writeRegister_IN)begin
            //RS
            if(RegisterRSID_IN)begin
                branch_operandA = aluResult_IN;
            end
            else if(!RegisterRSID_IN)begin
                branch_operandA = branch_operandA_IN;
            end
            //RT
            if(RegisterRTID_IN == writeRegister_IN)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = aluResult_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
                
            end
            else if(RegisterRTID_IN == RegDEXE)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = RegvalueEXEMEM_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else if(RegisterRTID_IN == RegDMEM)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = RegvalueMEMWB_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else if(RegisterRTID_IN == RegWB)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = _RegisterValue_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else begin
                branch_operandB = branch_operandB_IN;
                _forward3 = 1'b1; 
            end
    
        end
        else if(RegisterRSID_IN == RegDEXE)begin
            if(RegisterRSID_IN)begin
                branch_operandA = RegvalueEXEMEM_IN;
            end
            else if(!RegisterRSID_IN)begin
                branch_operandA = branch_operandA_IN;
            end

            //RT
            if(RegisterRTID_IN == writeRegister_IN)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = aluResult_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
                
            end
            else if(RegisterRTID_IN == RegDEXE)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = RegvalueEXEMEM_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else if(RegisterRTID_IN == RegDMEM)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = RegvalueMEMWB_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else if(RegisterRTID_IN == RegWB)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = _RegisterValue_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else begin
                branch_operandB = branch_operandB_IN;
                _forward3 = 1'b1; 
            end
        end


        else if(RegisterRSID_IN == RegDMEM)begin
            if(RegisterRSID_IN)begin
                branch_operandA = RegvalueMEMWB_IN;
            end
            else if(!RegisterRSID_IN)begin
                branch_operandA = branch_operandA_IN;
            end

           //RT
            if(RegisterRTID_IN == writeRegister_IN)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = aluResult_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
                
            end
            else if(RegisterRTID_IN == RegDEXE)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = RegvalueEXEMEM_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else if(RegisterRTID_IN == RegDMEM)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = RegvalueMEMWB_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else if(RegisterRTID_IN == RegWB)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = _RegisterValue_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else begin
                branch_operandB = branch_operandB_IN;
                _forward3 = 1'b1; 
            end
        end

        
        else if(RegisterRSID_IN == RegWB)begin
            if(RegisterRSID_IN)begin
                branch_operandA = _RegisterValue_IN;
            end
            else if(!RegisterRSID_IN)begin
                branch_operandA = branch_operandA_IN;
            end

           //RT
            if(RegisterRTID_IN == writeRegister_IN)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = aluResult_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
                
            end
            else if(RegisterRTID_IN == RegDEXE)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = RegvalueEXEMEM_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else if(RegisterRTID_IN == RegDMEM)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = RegvalueMEMWB_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end
            else if(RegisterRTID_IN == RegWB)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = _RegisterValue_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
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
            if(RegisterRTID_IN == writeRegister_IN)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = aluResult_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end

            else if(RegisterRTID_IN == RegDEXE)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = RegvalueEXEMEM_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end

            else if(RegisterRTID_IN == RegDMEM)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = RegvalueMEMWB_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end

            else if(RegisterRTID_IN == RegWB)begin
                if(RegisterRTID_IN)begin
                    branch_operandB = _RegisterValue_IN;
                end
                else if(!RegisterRTID_IN)begin
                    branch_operandB = branch_operandB_IN;
                end
                _forward3 = 1'b1;
            end

            else begin
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
    if(mem_write_IN)begin
        S_operandB <= _operandB_IN;
        if(_RegisterRS_IN == RegDEXE)begin
            if(mem_read_IN)begin
                S_operandA <= MEMREAD_IN;
            end
            else begin
                _operandA <= RegvalueEXEMEM_IN;
            end

            if(_RegisterRT_IN == RegDEXE)begin
                if(mem_read_IN)begin
                    memdata <= MEMREAD_IN;
                end
                else if(MemWrite_IN)begin
                    memdata <= MemWriteData_IN;
                end
                else begin
                    memdata <= RegvalueEXEMEM_IN;
                end
            end

            else if(_RegisterRT_IN == RegDMEM)begin
                memdata <= RegvalueMEMWB_IN;
            end

            else if(_RegisterRT_IN == RegWB)begin
                memdata <= _RegisterValue_IN;
            end

            else begin
                memdata <= mem_write_data;
            end
            _forward4 <= 1'b1;
        end

        else if(_RegisterRS_IN == RegDMEM)begin
            S_operandA <= RegvalueMEMWB_IN;

            if(_RegisterRT_IN == RegDEXE)begin
                if(mem_read_IN)begin
                    memdata <= MEMREAD_IN;
                end
                else if(MemWrite_IN)begin
                    memdata <= MemWriteData_IN;
                end
                else begin
                    memdata <= RegvalueEXEMEM_IN;
                end
            end

            else if(_RegisterRT_IN == RegDMEM)begin
                memdata <= RegvalueMEMWB_IN;
            end

            else if(_RegisterRT_IN == RegWB)begin
                memdata <= _RegisterValue_IN;
            end

            else begin
                memdata <= mem_write_data;
            end
            _forward4 <= 1'b1;
        end

        else if(_RegisterRS_IN == RegWB)begin
            S_operandA <= _RegisterValue_IN;

           if(_RegisterRT_IN == RegDEXE)begin
                if(mem_read_IN)begin
                    memdata <= MEMREAD_IN;
                end
                else if(MemWrite_IN)begin
                    memdata <= MemWriteData_IN;
                end
                else begin
                    memdata <= RegvalueEXEMEM_IN;
                end
            end

            else if(_RegisterRT_IN == RegDMEM)begin
                memdata <= RegvalueMEMWB_IN;
            end

            else if(_RegisterRT_IN == RegWB)begin
                memdata <= _RegisterValue_IN;
            end

            else begin
                memdata <= mem_write_data;
            end
            _forward4 <= 1'b1;
        end

        else begin
            S_operandA <= _operandA_IN;
            $display("\nrs %d rt  %d rd %d\n",_RegisterRS_IN, _RegisterRT_IN, writeRegister_IN);
            if(_RegisterRT_IN == RegDEXE)begin
                if(mem_read_IN)begin
                    memdata <= MEMREAD_IN;
                end
                else if(MemWrite_IN)begin
                    memdata <= MemWriteData_IN;
                end
                else begin
                    memdata <= RegvalueEXEMEM_IN;
                end
                _forward4 <= 1'b1;
            end

            else if(_RegisterRT_IN == RegDMEM)begin
                memdata <= RegvalueMEMWB_IN;
                _forward4 <= 1'b1;
            end

            else if(_RegisterRT_IN == RegWB)begin
                memdata <= _RegisterValue_IN;
                _forward4 <= 1'b1;
            end

            else begin
                memdata <= mem_write_data;
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
always @(posedge CLOCK)begin
    
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
end //6th always ends

endmodule
