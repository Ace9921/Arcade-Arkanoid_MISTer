//============================================================================
// 
//  Port to MiSTer.
//  Copyright (C) 2018 Sorgelig
//
//  Arkanoid for MiSTer
//  Copyright (C) 2018, 2019 Ace, Enforcer, Ash Evans (aka ElectronAsh/OzOnE)
//  and Kitrinx (aka Rysha)
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//	 the rights to use, copy, modify, merge, publish, distribute, sublicense,
//	 and/or sell copies of the Software, and to permit persons to whom the 
//	 Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//	 all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//	 DEALINGS IN THE SOFTWARE.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        VGA_CLK,

	//Multiple resolutions are supported using different VGA_CE rates.
	//Must be based on CLK_VIDEO
	output        VGA_CE,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)

	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S    // 1 - signed audio samples, 0 - unsigned
);

assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign HDMI_ARX = status[13] ? 8'd4 : 8'd3;
assign HDMI_ARY = status[13] ? 8'd3 : 8'd4;

`include "build_id.v"
parameter CONF_STR = {
	"A.ARKANOID;;",
	"-;",
	"O12,Credits,1 coin 1 credit,2 coins 1 credit,1 coin 2 credits,1 coin 6 credits;",
	"O3,Lives,3,5;",
	"O4,Bonus,20000/every 60000,20000 only;",
	"O5,Difficulty,Easy,Hard;",
	"O6,Test mode,Off,On;",
	"O7,Flip screen,Off,On;",
	"O8,Continues,On,Off;",
	"OC,Sound chip,YM2149,AY-3-8910;",
	"-;",
	"OD,Orientation,Vert,Horz;",
	"-;",
	"R0,Reset;",
	"J,Fire,Fast,P1 Start,P1 Coin,P2 Start,P2 Coin;",
	"V,v",`BUILD_DATE
};

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire [15:0] joy0;

wire        forced_scandoubler;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(CLK_12M),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joy0),
	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse)
);

////////////////////   CLOCKS   ///////////////////

wire CLK_6M;
wire CLK_12M;
wire CLK_24M;
wire LOCKED;
wire MOUSE_CLK;

pll pll
(
    .refclk(CLK_50M),
    .outclk_0(CLK_6M),
    .outclk_1(CLK_12M),
    .outclk_2(CLK_24M),
    .outclk_5(MOUSE_CLK),
    .locked(LOCKED)
);

wire reset = buttons[1] | status[0] | ioctl_download;

////////////////////   Mouse controls by Enforcer   ///////////////////

logic [1:0] spinner_encoder = 2'b11; //spinner encoder is a standard AB type encoder.  as it spins with will use the pattern 00, 01, 11, 10 and repeat.  when it spins the other way the pattern is reversed.

wire signed [8:0] mouse_x_in = $signed({ps2_mouse[4], ps2_mouse[15:8]});

always_ff @(posedge CLK_6M)
begin
    reg old_state;
    reg old_mouse_clk;
	integer spin_counter;

    reg signed  [8:0] mouse_x = 0;

    logic signed [11:0] position = 0;

    old_state <= ps2_mouse[24];    
    old_mouse_clk <= MOUSE_CLK;
    mouse_x <= mouse_x_in;
    
    if(position != 0) //we need to drive position to 0 still;
    begin
        if(MOUSE_CLK & (old_mouse_clk != MOUSE_CLK))
        begin
            case({position[11] , spinner_encoder})
                {1'b1, 2'b00}: spinner_encoder <= 2'b01;
                {1'b1, 2'b01}: spinner_encoder <= 2'b11;
                {1'b1, 2'b11}: spinner_encoder <= 2'b10;
                {1'b1, 2'b10}: spinner_encoder <= 2'b00;
                {1'b0, 2'b00}: spinner_encoder <= 2'b10;
                {1'b0, 2'b10}: spinner_encoder <= 2'b11;
                {1'b0, 2'b11}: spinner_encoder <= 2'b01;
                {1'b0, 2'b01}: spinner_encoder <= 2'b00;
            endcase
            if(position[11])
            begin
                position = position + 1'b1;
            end
            else 
            begin
                position = position - 1'b1;
            end
        end
    end

    if(ps2_mouse[24] & (old_state != ps2_mouse[24]))
    begin
        if({position[11], mouse_x[8]}) position = position + mouse_x;
        else position = mouse_x;
    end

	if (joy0[0] | joy0[1]) begin // 0.167us per cycle
		if (spin_counter == 'd48000) begin// roughly 8ms to emulate 125hz standard mouse poll rate
			position <= joy0[0] ? (joy0[5] ? 12'd9 : 12'd4) : (joy0[5] ? -12'd9 : -12'd4);
			spin_counter <= 0;
		end else begin
			spin_counter <= spin_counter + 1'b1;
		end
	end else begin
		spin_counter <= 0;
	end
end

///////////////////         Keyboard           //////////////////

wire pressed = ps2_key[9];
wire [8:0] code = ps2_key[8:0];
always @(posedge CLK_12M) begin
	reg old_state;
	old_state <= ps2_key[10];
	if(old_state != ps2_key[10]) begin
		casex(code)
			'h016: btn_1p_start <= ~pressed;	// 1
			'h01E: btn_2p_start <= ~pressed;	// 2
			'h02E: coin1 <= pressed;			// 5
			'h036: coin2 <= pressed;			// 6
			'h046: btn_service <= ~pressed;	// 9
		endcase
	end
end


//////////////////  Arcade Buttons/Interfaces   ///////////////////////////

reg coin1 = 0;							// Active-HIGH.
reg coin2 = 0;							// Active-HIGH.
wire btn_shot = ~ps2_mouse[0];	// Active-LOW.
reg btn_service = 1;					// Active-LOW.
wire tilt = 1'b1;						// Active-LOW.
reg btn_1p_start = 1;				// Active-LOW.
reg btn_2p_start = 1;				// Active-LOW.


wire [7:0] dip_sw = {status[8], ~status[7:1]};	// Active-LOW
/*DIP switches are in reverse order when compared to this table (sourced from MAME Arkanoid driver):
+-----------------------------+--------------------------------+
|FACTORY DEFAULT = *          |  1   2   3   4   5   6   7   8 |
+----------+------------------+----+---------------------------+
|CABINET   | COCKTAIL         | OFF|                           |
|          |*UPRIGHT          | ON |                           |
+----------+------------------+----+---------------------------+
|COINS     |*1 COIN  1 CREDIT |    |OFF|                       |
|          | 1 COIN  2 CREDITS|    |ON |                       |
+----------+------------------+----+---+---+                   |
|LIVES     |*3                |        |OFF|                   |
|          | 5                |        |ON |                   |
+----------+------------------+--------+---+---+               |
|BONUS     |*20000 / 60000    |            |OFF|               |
|1ST/EVERY | 20000 ONLY       |            |ON |               |
+----------+------------------+------------+---+---+           |
|DIFFICULTY|*EASY             |                |OFF|           |
|          | HARD             |                |ON |           |
+----------+------------------+----------------+---+---+       |
|GAME MODE |*GAME             |                    |OFF|       |
|          | TEST             |                    |ON |       |
+----------+------------------+--------------------+---+---+   |
|SCREEN    |*NORMAL           |                        |OFF|   |
|          | INVERT           |                        |ON |   |
+----------+------------------+------------------------+---+---+
|CONTINUE  | WITHOUT          |                            |OFF|
|          |*WITH             |                            |ON |
+----------+------------------+----------------------------+---+
*/


///////////////                 Video                  ////////////////


wire hblank, vblank;
wire hs, vs;
wire [3:0] r,g,b;

arcade_rotate_fx #(258,240,12,0) arcade_video
(
	.*,

	.clk_video(CLK_12M),
	.ce_pix(CLK_6M),

	.RGB_in({r,g,b}),
	.HBlank(~hblank),
	.VBlank(~vblank),
	.HSync(hs),
	.VSync(~vs),
	
	.fx(3'b000),
	.no_rotate(status[13])
);

//Instantiate Arkanoid top-level module
arkanoid arkanoid_inst
(
	.reset(~reset),					// input reset

	.clk_24m(CLK_24M) ,				// input clk_24m
	.clk_12m(CLK_12M),				// input clk_12m

	.spinner(spinner_encoder),		// input [1:0] spinner
	
	.coin1(coin1 | joy0[7]),		// input coin1
	.coin2(coin2 | joy0[9]),		// input coin2
	
	.btn_shot(btn_shot & ~joy0[4]),				// input btn_shot
	.btn_service(btn_service),		// input btn_service
	
	.tilt(tilt),						// input tilt
	
	.btn_1p_start(btn_1p_start & ~joy0[6]),	// input btn_1p_start
	.btn_2p_start(btn_2p_start & ~joy0[8]),	// input btn_2p_start
	
	.dip_sw(dip_sw),					// input [7:0] dip_sw
	
	.sound(audio),						// output [7:0] sound
	
	.video_hsync(hs),					// output video_hsync
	.video_vsync(vs),					// output video_vsync
	.video_vblank(vblank),			// output video_vblank
	.video_hblank(hblank),			// output video_hblank
	
	.video_r(r),						// output [3:0] video_r
	.video_g(g),						// output [3:0] video_g
	.video_b(b), 						// output [3:0] video_b
	
	.ym2149_clk_div(status[12]),	// Easter egg - controls the YM2149 clock divider for bootlegs with overclocked AY-3-8910s (default on)

	.ioctl_addr(ioctl_addr),
	.ioctl_wr(ioctl_wr),
	.ioctl_data(ioctl_dout)
);

wire [7:0] audio;

assign AUDIO_L = {audio, audio};
assign AUDIO_R = {audio, audio};
assign AUDIO_S = 0;

endmodule
