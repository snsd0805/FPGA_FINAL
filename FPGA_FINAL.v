
module FPGA_FINAL(
	input CLK,
	output reg [0:27] led,		// 8x8(RGB s2 s1 s0 COM)
	input left, right,
	input throw,				// 丟球
);



	reg [2:0]plat_position; // 板子位置
	reg [2:0]ball_position;	// 球  位置
	reg [2:0]ball_y_position; // 球 y 座標
	
	reg upPosition;				// 垂直方向
	integer horizonPosition;	// 水平方向(-1左 0中 1右)

	reg handsOn; 				// bool，紀錄球現在丟出去了沒


	
	initial
	begin
		// 歸零，重製 8x8 LED
		led[0:23] = 23'b11111111111111111111;
		led[27] = 1;
		led[24:26] = 3'b000;
		
		plat_position = 3'b010;		// 預設在 x=2 的位置
		ball_position = 3'b011;		// 預設在 x=3 的位置
		ball_y_position = 3'b010;	// 預設在 y=1 的位置
		handsOn = 1;					// 預設為 為丟出狀態
		
		upPosition = 1;				// 預設為 向上
		horizonPosition = 0;			// 預設為 正中間方向
	end
	
	

	// 開始所有除頻器
	divfreq F(CLK, divclk);				// 顯示用除頻器
	buttondivfreq BT(CLK, buttonclk);
	balldivfreq BA(CLK, ballclk);
	
	
	// 判斷 球 移動
	always @(posedge ballclk)
	begin
		if(handsOn==0)	// 如果是丟出去的狀態才移動
		begin
			// 先判斷垂直方向
			// 方向向上
			if(upPosition)
				if(ball_y_position<7)	// 還沒到頂端
					ball_y_position <= ball_y_position+1;
				else
				begin
					ball_y_position <= ball_y_position-1;	// 到頂端就開始往下
					upPosition = 0;
				end
			// 方向向下
			else
				if(ball_y_position>1)
					ball_y_position <= ball_y_position-1;
			

			// 判斷水平方向
			// 向右移動
			if(horizonPosition==1)
				if(ball_position<7)
					ball_position <= ball_position+1;	// 範圍內右移
				else	
					horizonPosition = -1;				// 超過範圍就轉向左邊
			// 向左移動
			else if(horizonPosition==-1)
				// 範圍內
				if(ball_position>0)
					ball_position <= ball_position-1;	// 範圍內左移
				else
					horizonPosition = 1;					// 超過範圍就轉向右邊
		end
	end
	
	
	// 判斷 所有按鈕
	always @(posedge buttonclk)
	begin
		// 判斷 向左
		if(left)
			if(plat_position>0)
				plat_position <= plat_position-1;
		
		// 判斷 向右
		if(right)
			if(plat_position<5)
				plat_position <= plat_position+1;
				
		// 判斷 丟出球
		if(throw)
			if(handsOn)
			begin
				handsOn = 0;
			end
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

		// 在板子上的狀況
		if(handsOn)
			if(row==plat_position+1)		// 放在正中間
				led[8:15] = 8'b11111101;
			else
				led[8:15] = 8'b11111111;
		
		// 丟出球後的狀況
		else
			if(row==ball_position)
			begin
				reg [7:0] map;
				// 轉成 one-hot encode
				case(ball_y_position)
					3'b000: map = 8'b11111110 ;
					3'b001: map = 8'b11111101 ;
					3'b010: map = 8'b11111011 ;
					3'b011: map = 8'b11110111 ;
					3'b100: map = 8'b11101111 ;
					3'b101: map = 8'b11011111 ;
					3'b110: map = 8'b10111111 ;
					3'b111: map = 8'b01111111 ; 
				endcase
				led[8:15] = map;
			end
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


// 球 飛行用的除頻器
module balldivfreq(input CLK, output reg CLK_div);
	reg[26:0] Count;
	always @(posedge CLK)
	begin
		if(Count>10000000)
			begin
				Count <= 27'b0;
				CLK_div <= ~CLK_div;
			end
		else
			Count <= Count + 1'b1;
	end
endmodule
	