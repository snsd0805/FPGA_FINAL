
module FPGA_FINAL(
	input CLK,
	output reg [0:27] led,
	input left, right
);

	reg [2:0]plat_position; // 板子位置
	reg [2:0]ball_position;	// 球  位置
	
	reg upPosition;
	integer horizonPosition;

	reg handsOn; 				// bool，紀錄球現在丟出去了沒


	
	initial
	begin
		// 歸零，重製 8x8 LED
		led[0:23] = 23'b11111111111111111111;
		led[27] = 1;
		led[24:26] = 3'b000;
		
		plat_position = 3'b010;		// 預設在 x=2 的位置
		ball_position = 3'b011;		// 預設在 x=3 的位置
		handsOn = 1;					// 預設為 為丟出狀態
		
		upPosition = 1;				// 預設為 向上
		horizonPosition = 0;			// 預設為 正中間方向
	end
	

	divfreq F(CLK, divclk);
	buttondivfreq B(CLK, buttonclk);
	
	always @(posedge buttonclk)
	begin
		if(left)
			if(plat_position>0)
				plat_position <= plat_position-1;
		
		if(right)
			if(plat_position<5)
				plat_position <= plat_position+1;
	end
	
	
	// 顯示用
	always @(posedge divclk)
	begin
		reg [0:2]row;
		
		// 跑 0~7 行
		if(row>=7)
			row <= 3'b000;
		else
			row <= row + 1'b1;
		
		// 設定這次要畫第 n 行
		led[24:26] = row;
		
		// 開始畫板子 ( R )
		if(row==plat_position || row==plat_position+1 || row==plat_position+2)
			led[0:7] = 8'b11111110;
		else
			led[0:7] = 8'b11111111;
			
			
		// 開始畫球 ( G )
		if(handsOn)
			if(row==plat_position+1)		// 放在正中間
				led[8:15] = 8'b11111101;
			else
				led[8:15] = 8'b11111111;
	end
endmodule


// 顯示用的除頻器
module divfreq(input CLK, output reg CLK_div);
	reg[24:0] Count;
	always @(posedge CLK)
	begin
		if(Count>25000)
			begin
				Count <= 25'b0;
				CLK_div <= ~CLK_div;
			end
		else
			Count <= Count + 1'b1;
	end
endmodule


// 按鈕用的除頻器
module buttondivfreq(input CLK, output reg CLK_div);
	reg[24:0] Count;
	always @(posedge CLK)
	begin
		if(Count>2500000)
			begin
				Count <= 25'b0;
				CLK_div <= ~CLK_div;
			end
		else
			Count <= Count + 1'b1;
	end
endmodule