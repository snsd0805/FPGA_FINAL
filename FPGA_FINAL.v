
module FPGA_FINAL(
	input CLK, reset, start,
	output reg [0:27] led,
	output reg [2:0] life,
	input left, right,
	input throw,
	output testLED,
	output reg a,b,c,d,e,f,g,
	output reg [0:1] COM
);

	reg [7:0]blockFirst =  8'b11111111;
	reg [7:0]blockSecond = 8'b11111111;

	reg [2:0]plat_position; // 板子位置
	reg [2:0]ball_position;	// 球  位置
	reg [2:0]ball_y_position; // 球 y 座標

	reg [3:0]count_digit;	//個位數分數
	reg count_ten;			//十位數分數
	
	reg upPosition;
	integer horizonPosition;

	reg handsOn; 				// bool，紀錄球現在丟出去了沒
	reg gameOverFlag;
	
	reg showBonus;         // bool 顯示額外球
	reg [2:0] Bonus_x;  // 額外球的位子x
	reg [2:0] Bonus_y;  // 額外球的位子x
	
	reg ball_is_on_the_gronud; // 檢查球是否沒被盤子接住
	
	initial
	begin
		// 歸零，重製 8x8 LED
		led[0:23] = 23'b11111111111111111111;
		led[27] = 1;
		led[24:26] = 3'b000;

		life = 3'b111;
		
		plat_position = 3'b010;		// 預設在 x=2 的位置
		ball_position = 3'b011;		// 預設在 x=3 的位置
		ball_y_position = 3'b010;	// 預設在 y=1 的位置
		handsOn = 1;					// 預設為 為丟出狀態
		count_digit = 4'b0;               // 分數預設0
		count_ten = 0;
		
		upPosition = 1;				// 預設為 向上
		horizonPosition = 0;			// 預設為 正中間方向
		
		gameOverFlag = 0;
		
		showBonus = 0;
		ball_is_on_the_gronud = 0;
	end
	
	

	// 開始所有除頻器
	divfreq F(CLK, divclk);
	buttondivfreq BT(CLK, buttonclk);

	
	
	integer ballTime;
	integer doubleTime;
	// 判斷 所有操作
	always @(posedge buttonclk)
	begin
		if(start)
		begin
			
			
			if(reset)
			begin
				if(life==3'b000)
				begin
					blockFirst =  8'b11111111;
					blockSecond = 8'b11111111;

					life = 3'b111;
					gameOverFlag = 0;

				end
				
				plat_position <= 3'b010;		// 預設在 x=2 的位置
				ball_position <= 3'b011;		// 預設在 x=3 的位置
				ball_y_position <= 3'b010;	// 預設在 y=1 的位置
				handsOn = 1;				// 預設為 為丟出狀態
				
				upPosition = 1;				// 預設為 向上
				horizonPosition = 0;		// 預設為 正中間方向
				
				showBonus = 0;
				ball_is_on_the_gronud = 0;
			end


			// 判斷 向左
			if(left)
				if(plat_position>0)
				begin
					plat_position <= plat_position-1;
					if(handsOn==1)ball_position <= ball_position-1;
				end
			
			// 判斷 向右
			if(right)
				if(plat_position<5)
				begin
					plat_position <= plat_position+1;
					if(handsOn==1)ball_position <= ball_position+1;
				end
					
			// 判斷 丟出球
			if(throw)
				if(handsOn)
				begin
					handsOn = 0;
				end
				
		

				
			
			// 下方操作球的運 行
			// 除頻用
			if(ballTime<2)
				ballTime <= ballTime+1;
			else
			//開始判斷球的行進
			begin
				ballTime <= 0;
				if(handsOn==0)	// 如果是丟出去的狀態才移動
				begin
					// 先判斷垂直方向
					if(upPosition)
						if(ball_y_position<7)	// 還沒到頂端
							ball_y_position <= ball_y_position+1;
						else
						begin
							ball_y_position <= ball_y_position-1;	// 到頂端就開始往下
							upPosition = 0;
						end
					else
						if(ball_y_position>1)
							ball_y_position <= ball_y_position-1;

					

					// 判斷水平方向
					if(horizonPosition==1)
						if(ball_position<7)
							ball_position <= ball_position+1;	// 範圍內右移
						else
						begin
							horizonPosition = -1;				// 超過範圍就轉向左邊
							ball_position <= ball_position-1;
						end
					else if(horizonPosition==-1)
						if(ball_position>0)
							ball_position <= ball_position-1;	// 範圍內左移
						else
						begin
							horizonPosition = 1;					// 超過範圍就轉向右邊
							ball_position <= ball_position+1;
						end
						
					// 判斷特殊狀況(碰到板子)
					if(ball_y_position==1)
						if(ball_position==plat_position)
						begin
							if(horizonPosition==0) horizonPosition = -1;
							else ball_y_position <= ball_y_position+1;
							upPosition = 1;
						end 
						else if(ball_position==plat_position+1)
						begin
							upPosition = 1;
							ball_y_position <= ball_y_position+1;
						end
						else if(ball_position==plat_position+2)
						begin
							if(horizonPosition==0) horizonPosition = 1;
							else ball_y_position <= ball_y_position+1;
							upPosition = 1;
						end
						else if(ball_position==plat_position-1 && horizonPosition==1)
						begin
							horizonPosition = -1;
							ball_position <= ball_position-1;
							ball_y_position <= ball_y_position+1;
							upPosition = 1;
						end
						else if(ball_position==plat_position+3 && horizonPosition==-1)
						begin
							horizonPosition = 1;
							ball_position <= ball_position+1;
							ball_y_position <= ball_y_position+1;
							upPosition = 1;
						end
						else
						begin
							horizonPosition = 0;
							ball_y_position <= ball_y_position-1;
							showBonus = 0;
							ball_is_on_the_gronud = 1;
							
							life = life*2;		// 扣除生命值
							if(life==3'b000)
								gameOverFlag = 1;
							
						end




					// // 判斷特殊狀態 ， 撞到第一排磚塊
					if(ball_y_position==6)
						if(blockSecond[ball_position]==1)
						begin
							count_digit <= count_digit + 1'b1;
							if(count_digit == 4'b1001)
							begin
								count_digit <= 4'b0;
								count_ten = 1;
							end
							blockSecond[ball_position] = 0;

							if(upPosition) upPosition = 0;
							else begin
								horizonPosition = -horizonPosition;
								upPosition = 1;
							end
							if(ball_position==0) horizonPosition = 1;
							if(ball_position==7) horizonPosition = -1;

							ball_position <= ball_position + horizonPosition;
							if(upPosition) ball_y_position <= ball_y_position +1;
							else ball_y_position <= ball_y_position -1;
						end
					// // 判斷特殊狀態 ， 撞到第二排磚塊
					if(ball_y_position==7)
						if(blockFirst[ball_position]==1)
						begin
							count_digit <= count_digit + 1'b1;
							if(count_digit == 4'b1001)
							begin
								count_digit <= 4'b0;
								count_ten = 1;
							end
							blockFirst[ball_position] = 0;

							upPosition = 0;
							
							if(ball_position==0) horizonPosition = 1;
							if(ball_position==7) horizonPosition = -1;

							ball_position <= ball_position + horizonPosition;
							ball_y_position <= ball_y_position -1;
						end
				end
			end
			
			// Bonus ball 除頻 ， 每五秒從左邊射一發
			if(doubleTime<50 && showBonus == 0 && handsOn == 0 && ball_is_on_the_gronud == 0)
			begin
				doubleTime <= doubleTime+1;
				Bonus_x = plat_position ;
				Bonus_y = 1;
			end
			else
			begin
				if(handsOn == 0)
				begin
					doubleTime <= 0;
					showBonus = 1;
					if(Bonus_y == 7)
					begin
						showBonus = 0;
					end
					if(Bonus_y < 7)
					begin
						Bonus_y = Bonus_y + 1;
					end
						
					// Bonus ball 撞到第一排磚塊
					if((Bonus_y == 6 && blockSecond[Bonus_x] == 1))
					begin
						count_digit <= count_digit + 1'b1;
						if(count_digit == 4'b1001)
						begin
							count_digit <= 4'b0;
							count_ten = 1;
						end
						blockSecond[Bonus_x] = 0;
						showBonus = 0;
					end
					
					// Bonus ball 撞到第二排磚塊
					if((Bonus_y == 7 && blockFirst[Bonus_x] == 1))
					begin
						count_digit <= count_digit + 1'b1;
						if(count_digit == 4'b1001)
						begin
							count_digit <= 4'b0;
							count_ten = 1;
						end
						blockFirst[Bonus_x] = 0;
						showBonus = 0;
					end
				end
				// Bonus ball
			end
		end
	end
	
	
	// 顯示用
	always @(posedge divclk)
	begin
		reg [0:2]row;
		reg count_digit_enable;
		
		// 跑 0~7 行
		if(row>=7)
			row <= 3'b000;
		else
			row <= row + 1'b1;
		
		// 設定這次要畫第 n 行
		led[24:26] = row;
		
		
		// 如果 gameOverFlag ==1就畫圖
		if(gameOverFlag)
		begin
			led[0:23] = 24'b111111111111111111111111;
			if(row==0 || row==7) led[0:7] 		= 8'b01111110;
			else if(row==1 || row==6) led[0:7]	= 8'b10111101;
			else if(row==2 || row==5) led[0:7]	= 8'b11011011;
			else if(row==3 || row==4) led[0:7]	= 8'b11100111;
			else led[0:7]	= 8'b11111111;
		end
		else
		begin
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
			else
				if(row==ball_position)
				begin
					reg [7:0] map;
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

			//開始畫磚塊
			led[16:23] = {~blockFirst[row], ~blockSecond[row], 6'b111111};
			
			// 畫 Bonus ball
			if(showBonus == 1)
				if(row==Bonus_x)
				begin
					reg [7:0] map;
					case(Bonus_y)
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

			// 顯示分數
			if(count_digit_enable == 0)
			begin
				count_digit_enable = 1;
				COM = 2'b01;
			end
			else
			begin
				count_digit_enable = 0;
				COM = 2'b10;
			end
		end

		
		// 顯示個位
		if(count_digit_enable == 0)
		begin
			case(count_digit)
				4'b0000:{a,b,c,d,e,f,g}=7'b0000001;
				4'b0001:{a,b,c,d,e,f,g}=7'b1001111;
				4'b0010:{a,b,c,d,e,f,g}=7'b0010010;
				4'b0011:{a,b,c,d,e,f,g}=7'b0000110;
				4'b0100:{a,b,c,d,e,f,g}=7'b1001100;
				4'b0101:{a,b,c,d,e,f,g}=7'b0100100;
				4'b0110:{a,b,c,d,e,f,g}=7'b0100000;
				4'b0111:{a,b,c,d,e,f,g}=7'b0001111;
				4'b1000:{a,b,c,d,e,f,g}=7'b0000000;
				4'b1001:{a,b,c,d,e,f,g}=7'b0000100;
			endcase
		end
		// 顯示十位
		else
		begin
			case(count_ten)
				1'b0:{a,b,c,d,e,f,g}=7'b0000001;
				1'b1:{a,b,c,d,e,f,g}=7'b1001111;
			endcase
		end
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
		if(Count>2500000)			// 20 Hz
			begin
				Count <= 25'b0;
				CLK_div <= ~CLK_div;
			end
		else
			Count <= Count + 1'b1;
	end
endmodule