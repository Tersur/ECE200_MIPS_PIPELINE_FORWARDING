module Forward(

        //MODULE INPUTS
        input CLOCK,                                                                       
        input RESET,

        //ID/EXE --> FORWARD
        input   [31:0] _operandA_IN,
        input   [31:0] _operandB_IN,

        input   [4:0] _RegisterRS_IN,
        input   [4:0] _RegisterRT_IN,

        //EXE/MEM --> FORWARD
        input   [31:0] RegvalueEXEMEM_IN,
        input   [4:0] RegisterEXEMEM_IN,

        //MEM/WB --> FORWARD
        input   [31:0] RegvalueMEMWB_IN,
        input   [4:0] RegisterMEMWB_IN,

		//ID --> FORWARD
		input [31:0] _RegisterValue_IN,		
		input [4:0] _Register_IN,
		/******************************/
        //MODULE OUTPUTS
        //FORWARD --> EXE
        output  [31:0] _operandA_OUT,
        output  [31:0] _operandB_OUT,
        output _forward
        //output _forwardMEM


);
  
wire [4:0] RegDEXE;
wire [4:0] RegDMEM;
wire [4:0] RegS;
wire [4:0] RegT;
wire [4:0]	RegWB;

// wire         [31:0] _operandA_;
// wire         [31:0] _operandB_;

reg     [31:0] _operandA;
reg     [31:0] _operandB;
reg             _forward_;
//reg             _forward2_;

assign RegS = _RegisterRS_IN;
assign RegT = _RegisterRT_IN;

assign RegDEXE = RegisterEXEMEM_IN;
assign RegDMEM = RegisterMEMWB_IN;
assign RegWB  = _Register_IN;

assign _operandA_OUT = _operandA;
assign _operandB_OUT = _operandB;


// initial begin
//      _forward_ = 1'b0;
// end

assign _forward = _forward_;
//assign _forwardMEM = _forward2_;

always @(negedge CLOCK or negedge RESET) begin
    if(!RESET)begin
        _operandA <= 0;
        _operandB <= 0;
        _forward_ <= 1'b0;
        // _forward2_ <= 1'b0;
    end

    if(!CLOCK)begin
        case (RegDEXE)
            RegS: begin/*
            _operandA <= RegvalueEXEMEM_IN;
            _operandB <= _operandB_IN;
            _forward1_ <= 1'b1*/
            
                case(RegDEXE)
                    RegT:begin
                        _operandA <= RegvalueEXEMEM_IN;
                        _operandB <= RegvalueEXEMEM_IN;
                        _forward_ <= 1'b1;
                    end
                    default:begin
                        /*****************/
                        case (RegDMEM)
                            RegT:begin
                                _operandA <= RegvalueEXEMEM_IN;
                                _operandB <= RegvalueMEMWB_IN;
                                _forward_ <= 1'b1;
                            end
                        /*****************/
                            default:begin
                                case(RegWB)

                                    RegT:begin
                                        _operandA <= RegvalueEXEMEM_IN;
                                        _operandB <= _RegisterValue_IN;
                                        _forward_ <= 1'b1;
                                    end

                                    default:begin
                                        _operandA <= RegvalueEXEMEM_IN;
                                        _operandB <= _operandB_IN;
                                        _forward_ <= 1'b1;
                                    end
                                endcase
                            end

                        endcase
                    end
                endcase
            end
                    /**************
                    case (RegDMEM)
                        RegT:begin
                        _operandA <= RegvalueEXEMEM_IN;
                        _operandB <= RegvalueMEMWB_IN;
                        _forward1_ <= 1'b1;
                        end
                    endcase
                    end
                    /*****************/

            RegT: begin
            /******************/
                case(RegDMEM)
                    RegS:begin
                        _operandB <= RegvalueEXEMEM_IN;
                        _operandA <= RegvalueMEMWB_IN;
                        _forward_ <= 1'b1;
                    end
                    // endcase
                    /******************/
                    default:begin
                        case(RegWB)
                            RegS:begin
                                _operandB <= RegvalueEXEMEM_IN;
                                _operandA <= _RegisterValue_IN;
                                _forward_ <= 1'b1;
                            end
                            default:begin
                                _operandB <= RegvalueEXEMEM_IN;
                                _operandA <= _operandA_IN;
                                _forward_ <= 1'b1;
                            end
                        endcase
                    end
                endcase
            end

            default: begin

                case (RegDMEM)
                    RegS: begin
                    case(RegDMEM)
                        RegT:begin
                        _operandA <= RegvalueMEMWB_IN;
                        _operandB <= RegvalueMEMWB_IN;                                                    
                        _forward_ <= 1'b1;
                        end
                        default:begin
                            case(RegWB)
                                RegT:begin
                                _operandA <= RegvalueMEMWB_IN;
                                _operandB <= _RegisterValue_IN;
                                _forward_ <= 1'b1;
                                end
                                default:begin
                                _operandA <= RegvalueMEMWB_IN;
                                _operandB <= _operandB_IN;
                                _forward_ <= 1'b1;
                                end
                            endcase
                        end
                    endcase
                    end

                    RegT: begin
                    case(RegWB)
                        RegS:begin
                        _operandB <= RegvalueMEMWB_IN;
                        _operandA <= _RegisterValue_IN;
                        _forward_ <= 1'b1;
                        end
                        default:begin
                        _operandB <= RegvalueMEMWB_IN;
                        _operandA <= _operandA_IN;
                        _forward_ <= 1'b1;
                        end	
                        // end
                        // _forward_ <= 1'b0;
                    //end
                    endcase
                    end
                    default: begin
                        _forward_ <= 1'b0;
                    end
                endcase

            end
        endcase
    end
end

endmodule
