module Hazard(

	//MODULE INPUTS
	
		//CONTROL SIGNALS
		input	CLOCK,
		input 	RESET,
	//	input	_jump_IDEXE,
		input	Syscall_IN,
		
		//FORWARD --> HAZARD
		input	STALL_IN,

	//MODULE OUTPUTS

		output 	STALL_IFID,
		output 	FLUSH_IFID,
	
		output 	STALL_IDEXE,
		output 	FLUSH_IDEXE,
	
		output 	STALL_EXEMEM,
		output 	FLUSH_EXEMEM,
	
		output 	STALL_MEMWB,
		output 	FLUSH_MEMWB,
		output	Syscall_OUT

);

reg [4:0] MultiCycleRing;
reg [3:0] MultiCycleRing2;
reg [1:0] MultiCycleRing3;

reg		  STALL;
reg		  FLUSHIDEXE;
reg		  FLUSHEXEMEM;
reg		  FLUSHMEMWB;
reg		  FLUSHIFID;
reg		syscall;
	
/*********************************/
assign FLUSH_MEMWB = FLUSHMEMWB;
assign STALL_MEMWB = 1'b0;

assign FLUSH_EXEMEM = FLUSHEXEMEM;
assign STALL_EXEMEM = 1'b0;

assign FLUSH_IDEXE = FLUSHIDEXE;
assign STALL_IDEXE = STALL;

assign FLUSH_IFID = FLUSHIFID;
assign STALL_IFID = STALL;

assign Syscall_OUT = syscall;


/***************for jump register and branch****************/
always @(negedge CLOCK)begin
	if(STALL_IN)begin
		MultiCycleRing3 = 2'b01;
		FLUSHIDEXE <= 1'b1;
		STALL	<= 1'b1;
	end
	if(MultiCycleRing3[1]) begin
		MultiCycleRing3 = 2'b0;
		FLUSHIDEXE <= 1'b0;
		STALL	<= 1'b0;
	end
end

/***************for jump register and branch****************/
always @(posedge CLOCK) begin
	MultiCycleRing3 = {{MultiCycleRing3[0], MultiCycleRing3[1]}};
end

/***************for Syscalls****************/
always @(negedge CLOCK) begin
	if(Syscall_IN)begin
		MultiCycleRing2 = 4'b0001;
		STALL	<= 1'b1;
		FLUSHIFID <= 1'b1;
		FLUSHIDEXE <= 1'b1;
	end
	else if(MultiCycleRing2[3])begin 
		MultiCycleRing2 = 4'b0000;
		STALL	<= 1'b0;
		FLUSHIFID <= 1'b0;
		FLUSHIDEXE <= 1'b0;
		syscall <= 1'b0;
	end

end

/***************for Syscalls****************/
always @(posedge CLOCK)begin
	MultiCycleRing2 = {{MultiCycleRing2[2:0], MultiCycleRing2[3]}};

	if(MultiCycleRing2[3])begin
		syscall <= 1;
	end

	if(MultiCycleRing2[1])begin
		FLUSHEXEMEM <= 1'b1;
	end
	else begin
		FLUSHEXEMEM <= 1'b0;
	end

	if(MultiCycleRing2[2])begin
		FLUSHMEMWB <= 1'b1;
	end
	else begin
		FLUSHMEMWB <= 1'b0;
	end	

end

always @(posedge CLOCK or negedge RESET) begin

	if(!RESET) begin

		MultiCycleRing <= 5'b00001;

	end else if(CLOCK) begin

		$display("");
		$display("----- HAZARD UNIT -----");
		$display("Multicycle Ring: %b", MultiCycleRing);

		MultiCycleRing <= {{MultiCycleRing[3:0],MultiCycleRing[4]}};

	end

end

endmodule


