module FPGA_FINAL(

	input [0:6] D,
	input select, CLK,
	
	output reg [0:27] LED,
	output reg [0:3] life,
	output reg beep,
	output reg [0:6] lcd
);

	reg [3:0] Count;
 	reg [3:0] plat_1= 3'b000, plat_2=3'b001, plat_3=3'b010, ball_x=3'b001;
	reg [3:0] kplat_1 = 3'b000, kplat_2 = 3'b001, kplat_3 = 3'b010;
	reg [3:0] plat_pos = 3'b010;
	reg [3:0] last_status_d1 = 1'b0, last_status_d0 = 1'b0;
	reg start = 1'b0;
	reg [10:0] time_pass = 11'b0;
	reg [7:0] ball_y = 8'b00000010;
	reg [15:0] block = 16'b0100001001011010;
	reg up = 1;
	reg [10:0] temp = 11'b0;
	reg [2:0] ball_status;
	reg [1:0] remain_life = 3;
	reg [3:0] last_status_d4 = 1'b0;
	reg [3:0] score = 4'b0;
	reg stage_1 = 1;
	reg a=0, b=0, c=0, d=0;
 
	always @(posedge CLK)
 	begin
		//除頻部分
		time_pass <= time_pass + 1'b1;
		temp <= temp + 1'b1;
		if(Count<8)
			Count <= Count + 1'b1;
		else
			Count <= 3'b000;	

		//顯示一開始的關卡
		//show
	 	LED[24:26] = Count;

	 	if(stage_1 == 0 && score == 0)
	 	begin
			if(Count == 0 || Count == 1 || Count == 6 || Count== 7) LED[8:15]<=8'b10111111;
			else if(Count == 2 || Count == 5) LED[8:15]<=8'b10111000;
			else if(Count == 3 || Count == 4) LED[8:15]<=8'b11111010;
			beep <= 0;
	 	end
	 
	 	else if(remain_life!=0 || ball_y!=8'b00000000)
	 	begin
	 		if(Count==plat_3 || Count==plat_2 ||Count==plat_1) LED[0:7]<=8'b11111110;	
	 		else LED[0:7] = 8'b11111111;
	 
	 		if (Count==ball_x) LED[8:15]<=~ball_y;
	 		else LED[8:15] = 8'b11111111;
	 
	 		if(block[Count]==1 && block[Count+8]==1) LED[16:23] <= 8'b00111111;
	 		else if(block[Count]==1 && block[Count+8]==0) LED[16:23] <= 8'b01111111;
	 		else if(block[Count]==0 && block[Count+8]==0) LED[16:23] <= 8'b11111111;
	 		else if(block[Count]==0 && block[Count+8]==1) LED[16:23] <= 8'b10111111;
	 	end
	 
	 	else
	 	begin
	 		if(Count==0 || Count==7) LED[0:7] = 8'b01111110;
	 		else if(Count==1 || Count==6) LED[0:7] = 8'b10111101;
	 		else if(Count==2 || Count==5) LED[0:7] = 8'b11011011;
	 		else if(Count==3 || Count==4) LED[0:7] = 8'b11100111;
	 	end
	
		//7段顯示器得分的部分
		d <= score[0];
		c <= score[1];
		b <= score[2];
		a <= score[3];
 
		//update status
		plat_1 <= kplat_1 + plat_pos;
		plat_2 <= kplat_2 + plat_pos;
		plat_3 <= kplat_3 + plat_pos;
		if(start==0)
		begin
			ball_x <= plat_2;
			beep <= 0;
		end

		//restart重新開始
		if(D[2]==1'b1)
		begin
			plat_pos <= 3'b010;
			ball_y <= 8'b00000010;
			start <= 0;
			block <= 16'b0100001001011010;
			up <= 1;
			remain_life <= 3;
			beep <= 0;
			score <= 4'b0;
			stage_1 = 1;
		end	
	 
		//Life血量
		if(remain_life==2'b11) life = 4'b1110;
		else if(remain_life==2'b10) life = 4'b1100;
		else if(remain_life==2'b01) life = 4'b1000;
		else life = 4'b0000;
	 
	 
		if(D[6]==0)
		begin
		//復活
			if(D[4]==1 && last_status_d4==0 && remain_life!=0)
	 		begin
				start <= 0;
				ball_x <= plat_2;
				ball_y <= 8'b00000010;
				remain_life <= remain_life - 1;
			end

			//平台左右移動
			//plat right
			else if(D[1]==0 && last_status_d1==1 && plat_pos<5) plat_pos <= plat_pos + 1'b1;
			//plat left
			else if(D[0]==0 && last_status_d0==1 && plat_pos>0) plat_pos <= plat_pos - 1'b1;
			//start game
			else if(D[3]==1) start<=1;
			
			last_status_d1 <= D[1];	 
			last_status_d0 <= D[0];
			last_status_d4 <= D[4];
	  

			//ball status
			if(start==1 && time_pass==11'b11111111111)
			begin
				beep <= 0;
				//ball raising
				if(up==1)
				begin
					if(ball_x == plat_1 && ball_y == 8'b00000010) ball_status=2'b0;
					else if(ball_x == plat_2 && ball_y == 8'b00000010) ball_status=2'b01;
					else if(ball_x == plat_3 && ball_y == 8'b00000010) ball_status=2'b10;
						
						
					if(ball_status==0)
					begin
						if(ball_x == 3'b001 || ball_y == 8'b10000000) ball_status = 2'b10;
						ball_x <= ball_x-1;
						ball_y <= ball_y*2;
					end
					else if(ball_status==1)
					begin
						ball_y <= ball_y*2;
					end
					else if(ball_status==2)
					begin
						if(ball_x==3'b110 || ball_y==8'b10000000) ball_status = 2'b0;
						ball_x <= ball_x+1;
						ball_y <= ball_y*2;
					end
					else if(ball_x==3'b000 && ball_x==plat_1 && ball_y==8'b00000010)
					begin
						ball_x <= ball_x+1;
						ball_y <= ball_y*2;
					end
					else if(ball_x==3'b111 && ball_x==plat_3 && ball_y==8'b00000010)
					begin
						ball_x <= ball_x-1;
						ball_y <= ball_y*2;
					end
				end
				//ball falling
				else 
				begin
				
					if(ball_status==0)
					begin
						if(ball_x==3'b001) ball_status = 2'b10;
						ball_x <= ball_x-1;
						ball_y <= ball_y/2;
					end
					else if(ball_status==1)
						ball_y <= ball_y/2;
						
					else if(ball_status==2)
					begin
						if(ball_x==3'b110) ball_status = 2'b0;
						ball_x <= ball_x+1;
						ball_y <= ball_y/2;
					end
				end
				time_pass <= 11'b0;
			end
		end
	
		//hit detect
		if(ball_y==8'b01000000 && block[ball_x+8]==1)
		begin
				block[ball_x+8]<=0;
				up <= 0;
				beep <= 1;
				if(stage_1 == 1) score <= score + 1'b1;
				else score <= score - 1'b1;
		end
		else if(ball_y==8'b10000000 && block[ball_x]==1)
		begin
			block[ball_x]<=0;
			up <= 0;
			beep <= 1;
			if(stage_1 == 1) score <= score + 1'b1;
			else score <= score - 1'b1;
		end
		else if(ball_y==8'b00000010 && (plat_1==ball_x || plat_2==ball_x || plat_3 == ball_x))
		begin
			up <= 1;
			if(start==1) beep <= 1;
		end
		else if(ball_y==8'b10000000)
		begin
			up<=0;
			beep <= 1;
		end;
	 
	 	if(block == 16'b0 && stage_1 == 1)
	 	begin
			ball_y <= 8'b00000010;
			start <= 0;
			block <= 16'b0101101000011000;
			up <= 1;
			beep <= 0;
			stage_1 = 0;
		end
	 
		lcd[0] = ~((~b & ~c & ~d)|(a & ~b & ~c)|(~a & b & d)|(~a & c));
		lcd[1] = ~((~a & ~b)|(~b & ~c)|(~a & ~c & ~d)|(~a & c & d));
		lcd[2] = ~((~a & b)|(~b & ~c)|(~a & d));
		lcd[3] = ~((a & ~b & ~c)|(~a & ~b & c)|(~a & c & ~d)|(~a & b & ~c & d)|(~b & ~c & ~d));
		lcd[4] = ~((~b & ~c & ~d)|(~a & c & ~d));
		lcd[5] = ~((~a & b & ~c)|(~a & b & ~d)|(a & ~b & ~c)|(~b & ~c & ~d));
		lcd[6] = ~((a & ~b & ~c )|(~a & ~b & c)|(~a & b & ~c)|(~a & c & ~d));
 	end
endmodule