//============================================================================
// 
//  Arkanoid top-level module
//  Copyright (C) 2018, 2020 Ace, Enforcer, Ash Evans (aka ElectronAsh/OzOnE)
//  and Kitrinx (aka Rysha)
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the 
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//============================================================================

//Module declaration, I/O ports
module Arkanoid
(
	input                reset,
	input          [1:0] spinner, //1 = left, 0 = right
	input                coin1, coin2,
	input                btn_shot, btn_service, tilt,
	input                btn_1p_start, btn_2p_start,
	
	input                clk_12m,
	input                ym2149_clk_div,
	input          [7:0] dip_sw,
	
	output signed [15:0] sound,
	output               video_hsync, video_vsync,
	output               video_csync,
	output               video_vblank, video_hblank,
	output         [3:0] video_r, video_g, video_b,

	input         [24:0] ioctl_addr,
	input                ioctl_download,
	input          [7:0] ioctl_data,
	input                ioctl_wr
);

//Z80 signals
wire z80_n_reset, z80_n_wait, z80_n_int, z80_n_m1, z80_n_mreq, z80_n_iorq, z80_n_rd, z80_n_wr;
wire [15:0] z80_A;
wire [7:0] z80_Din, z80_Dout, z80_ram_D;

//Tile ROM signals
wire [14:0] tilerom_A;
wire [7:0] eprom1_D, eprom2_D, eprom3_D, eprom4_D, eprom5_D;

//Color PROM signals
wire [8:0] prom_addr;
wire [3:0] prom1_data, prom2_data, prom3_data;

//ROM loader signals for MISTer (loads ROMs from SD card)
wire ep1_cs_i, ep2_cs_i, ep3_cs_i, ep4_cs_i, ep5_cs_i;
wire cp1_cs_i, cp2_cs_i, cp3_cs_i;
wire ioctl_wr_in;
wire [24:0] ioctl_addr_in;
wire [7:0] ioctl_data_in;

//VRAM signals
wire [10:0] vram_A, vram_mux_A, vram_Z80_A;
wire [15:0] vram_D;
wire vram_l_n_ce, vram_h_n_ce, vram_n_oe, vram_n_we;

//Sprite RAM signals
wire [8:0] spr_ram_A;
wire [7:0] spr_ram_Din, spr_ram_Dout;

//YM2149 signals
wire [7:0] ym2149_data, dipsw_in;
wire ym2149_bc1, ym2149_bdir;

//Clocks
wire clk_3m, n_clk_3m, clk_6m, n_clk_6m;

//Horizontal/vertical counters
wire [7:0] h_cnt, v_cnt;
wire h_cnt_cascade, h_cnt_carry, h_cnt_upper_n_ld;
wire v_cnt_clk, v_cnt_carry, v_cnt_cascade;

//User inputs
wire [3:0] buttons1;
wire [7:0] buttons2;
wire [1:0] n_spinner1, n_spinner2;

//Video sync/blanking (VSync is the most significant bit of the vertical
//counter, not explicitly defined within this section)
wire vb_in;
wire hs_in, hsync;
wire n_hblank, n_vblank, n_blank;

//Internal linking signals (signal names may not be entirely accurate)
wire eprom3_shift, eprom4_shift, eprom5_shift, flip_sel;
wire vcnt0_xor, vcnt1_xor, vcnt2_xor, vcnt3_xor, vcnt4_xor, vcnt5_xor, vcnt6_xor, vcnt_en_xor;
wire v_cnt_en, n_v_cnt_en, v_cnt_n_ld;
wire hcnt2_xor, hcnt3_xor, hcnt4_xor, hcnt5_xor, hcnt6_xor, n_hcnt5;
wire a_0x1000, a_0x1000_2, a_0x2000;
wire z80_n_A0, n_z80_A0, n_z80_A15, n_z80_A14_A15, z80_ram_n_ce;
wire eprom2_a15;
wire spr_ram_u_d, vram_n_rd, vram_we;
wire tilerom_shift_ld;
wire prom_addr_sel;
wire watchdog_clk, watchdog, n_watchdog, watchdog_clr, n_watchdog_clr;
wire spr_ram_rd, spr_ram_n_rd;
wire n_reset, reset2;
wire n_ym2149_bc1, n_ym2149_bdir;
wire h_inv;
wire z80_rd;
wire spin_cnt_clk, spin_cnt_u_d, spin_cnt_carry;
wire eprom2_n_ce, tilerom_n_ce;
wire z80_D1_latched, z80_D_latch_clk, mcu_data_clk;
wire spr_ram_cnt_carry, spr_ram_cnt_load;
wire inre, n_inre;
wire hblk_0, hblk_1;
wire dot1, dot2, dot3, n_dot123, n_dot;
wire sr_carry;
wire h256, n_h256, h_active;
wire n_sccs, sccs0, n_sccs0;
wire wait_pre, n_wait, n_sccs_wait;
wire buttons1_n_en, buttons2_n_en, spinner_n_en;
wire spinner_sel, spin_cnt_n_en;
wire [3:0] spin_cnt_h, spin_cnt_l;
wire [4:0] bg;
wire [7:0] sr, h_pos, h_pos_mux, bg_data, scr, obj, spinner_data;

//Reverse DIP switch order
assign dipsw_in = {dip_sw[0], dip_sw[1], dip_sw[2], dip_sw[3], dip_sw[4], dip_sw[5], dip_sw[6], dip_sw[7]};

//Video sync & blanking
assign video_hsync = hsync;
assign video_vsync = v_cnt[7];
assign video_vblank = ({v_cnt, v_cnt_en} < 271 || {v_cnt, v_cnt_en} > 495);
assign video_hblank = ({h_cnt, clk_3m} > 137 && {h_cnt, clk_3m} < 266);

//Clock division for jt49_dcrm2
wire dcrm_cen;
always_ff @(posedge clk_12m) begin
	reg [6:0] clk_div;
	clk_div <= clk_div + 1'd1;
	dcrm_cen <= !clk_div[6:0];
end

//Remove DC offset from audio output (uses jt49_dcrm2 from JT49 by Jotego)
wire [9:0] sound_raw;

wire signed [15:0] sound_dcrm;
jt49_dcrm2 #(16) dcrm
(
	.clk(clk_12m),
	.cen(dcrm_cen),
	.rst(~reset),
	.din({5'd0, sound_raw}),
	.dout(sound_dcrm)
);

//Low-pass filter the audio output (cutoff frequency ~16.7KHz)
wire signed [15:0] sound_filtered;
arkanoid_lpf lpf
(
	.clk(clk_12m),
	.reset(~reset),
	.in(sound_dcrm),
	.out(sound_filtered)
);

//Apply gain to final audio output
assign sound = sound_filtered * 6'd16;

//Direct modelling of data inputs to the Z80
assign z80_Din = 
	(~z80_A[15] & ~z80_n_rd)                                      ? eprom1_D:
	(~eprom2_n_ce & ~z80_n_rd)                                    ? eprom2_D:
	(~z80_ram_n_ce & ~z80_n_rd)                                   ? z80_ram_D:
	(~ym2149_bdir & z80_A[0] & ym2149_bc1)                        ? ym2149_data:
	(~vram_n_oe & ~vram_h_n_ce & z80_rd & ~z80_n_A0 & ~vram_n_rd) ? vram_D[7:0]:
	(~vram_n_oe & ~vram_l_n_ce & z80_n_A0 & ~vram_n_rd)           ? vram_D[15:8]:
	~buttons1_n_en                                                ? {4'hF, buttons1}:
	~buttons2_n_en                                                ? buttons2:
	~spinner_n_en                                                 ? {spinner_data[7:4], spinner_data[0], spinner_data[1], spinner_data[2], spinner_data[3]}:
	8'hFF;

//MiSTer data write selector
selector DLSEL
(
	.ioctl_addr(ioctl_addr),
	.ep1_cs(ep1_cs_i),
	.ep2_cs(ep2_cs_i),
	.ep3_cs(ep3_cs_i),
	.ep4_cs(ep4_cs_i),
	.ep5_cs(ep5_cs_i),
	.cp1_cs(cp1_cs_i),
	.cp2_cs(cp2_cs_i),
	.cp3_cs(cp3_cs_i)
);

//------------------------------------------------- Chip-level logic modelling -------------------------------------------------//

//IC1 is a Fujitsu MB3731 audio power amp - omit

//Sound chip - Yamaha YM2149 (implementation by MikeJ)
//Implements volume table to simulate mixing of the three analog outputs
//directly at the chip as per the original Arkanoid PCB
ym2149 IC2
(
	.I_DA(z80_Dout),
	.O_DA(ym2149_data),
	.I_A9_L(1'b0),
	.I_A8(1'b1),
	.I_BDIR(ym2149_bdir),
	.I_BC2(z80_A[0]),
	.I_BC1(ym2149_bc1),
	.I_SEL_L(ym2149_clk_div),
	.O_AUDIO(sound_raw),
	.I_IOA(8'h00),
	//O_IOA unused
	.I_IOB(dipsw_in),
	//O_IOB unused
	.ENA(1'b1),
	.RESET_L(z80_n_reset),
	.CLK(clk_3m)
);

//Latch data from blue color PROM for blue video output
ls273 IC3
(
	.d({prom3_data, 4'h0}),
	.clk(n_clk_6m),
	.res(n_blank),
	.q({video_b, 4'h0})
	//q[3:0] unused
);

//IC4 is a custom Taito PC030CM SIP package for inverting coin inputs and working the
//coin counter - omit, coin inputs are directly set active high and coin counter is
//unnecessary

//Lower 4-bit counter for spinner inputs
ls669 IC5
(
	.d_in(4'h0),
	.clk(spin_cnt_clk),
	.load(1'b1),
	.n_en_p(spin_cnt_n_en),
	.n_en_t(spin_cnt_n_en),
	.u_d(spin_cnt_u_d),
	.d_out(spin_cnt_l), //Normally routed to MCU, currently unimplemented
	.n_rco(spin_cnt_carry)
);

//Upper 4-bit counter for spinner inputs
ls669 IC6
(
	.d_in(4'h0),
	.clk(spin_cnt_clk),
	.load(1'b1),
	.n_en_p(spin_cnt_carry),
	.n_en_t(spin_cnt_carry),
	.u_d(spin_cnt_u_d),
	.d_out(spin_cnt_h) //Normally routed to MCU, currently unimplemented
	//n_rco unused
);

//Select which spinner inputs to send to counters defined above
ls157 IC7
(
	.i0({2'b00, n_spinner2[1], n_spinner1[0]}), //i0[3:2] unused, pull low
	.i1({2'b00, n_spinner1[1], n_spinner2[0]}), //i1[3:0] unused, pull low
	.n_e(1'b0),
	.s(spinner_sel),
	.z({2'bZ, spin_cnt_u_d, spin_cnt_clk}) //z[3:2] unused
);

//Invert spinner inputs (also inverts reset line twice - redundant but kept to match the PCB)
cmos_4584 IC8
(
	.in1(spinner[0]),
	.in2(reset),
	.in3(spinner[1]),
	.in4(n_reset),
	.in5(spinner[1]),
	.in6(spinner[0]),
	.out1(n_spinner1[0]),
	.out2(n_reset),
	.out3(n_spinner1[1]),
	.out4(reset2),
	.out5(n_spinner2[1]),
	.out6(n_spinner2[0])
);

//Multiplex button inputs
ls257 IC9
(
	.a(4'hF), //Unused inputs from edge connector, pull high
	.b({2'b01, coin2, coin1}), //Normally inverted with PC030 custom module, directly set as active high
	.out_ctl(1'b0), //Directly modelled, keep permanently enabled
	.sel(z80_A[2]),
	.y(buttons2[7:4])
);
//Multiplex button inputs
ls257 IC10
(
	.a(4'hF), //Unused inputs from edge connector, pull high
	.b({tilt, btn_service, btn_2p_start, btn_1p_start}),
	.out_ctl(1'b0), //Directly modelled, keep permanently enabled
	.sel(z80_A[2]),
	.y(buttons2[3:0])
);

//IC11 is a 7407 buffer for composite sync and Z80 CLK - redundant in this implementaiton,
//omit

//Main CPU - Zilog Z80 (uses T80s variant of the T80 soft core)
//NMI, BUSRQ unused, pull high
T80s IC12
(
	.RESET_n(z80_n_reset),
	.CLK(n_clk_6m),
	.WAIT_n(z80_n_wait),
	.INT_n(z80_n_int),
	.NMI_n(1'b1),
	.BUSRQ_n(1'b1),
	.MREQ_n(z80_n_mreq),
	.IORQ_n(z80_n_iorq),
	.RD_n(z80_n_rd),
	.WR_n(z80_n_wr),
	//M1_n, RFSH_n, HALT_n, BUSAK_n unused
	.A(z80_A),
	.DI(z80_Din),
	.DO(z80_Dout)
);

//Latch data from green and red color PROMs for green and red video outputs
ls273 IC13
(
	.d({prom1_data, prom2_data[0], prom2_data[1], prom2_data[2], prom2_data[3]}),
	.clk(n_clk_6m),
	.res(n_blank),
	.q({video_r, video_g[0], video_g[1], video_g[2], video_g[3]})
);

//IC14 is an MC68705 microcontroller - currently unimplemented

//Z80 work RAM
spram #(8, 11) IC15
(
	.clk(n_clk_6m),
	.we(~z80_n_wr & ~z80_ram_n_ce),
	.addr(z80_A[10:0]),
	.data(z80_Dout),
	.q(z80_ram_D)
);

//Secondary game ROM
eprom_2 IC16
(
	.ADDR({eprom2_a15, z80_A[13:0]}),
	.CLK(n_clk_6m),
	.DATA(eprom2_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_12m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep2_cs_i),
	.WR(ioctl_wr)
);

//Primary game ROM
eprom_1 IC17
(
	.ADDR(z80_A[14:0]),
	.CLK(n_clk_6m),
	.DATA(eprom1_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_12m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep1_cs_i),
	.WR(ioctl_wr)
);

//IC18 is a TL7700 reset IC - unnecessary for this implementation, omit

//Generate the following signals:
//Sprite RAM read enable/address A8, Z80 reset, input for HSync circuit
ls08 IC19
(
	.a1(h256),
	.b1(n_clk_6m),
	.y1(spr_ram_rd),
	.a2(n_h256),
	.b2(n_dot123),
	.y2(spr_ram_A[8]),
	.a3(watchdog),
	.b3(reset2),
	.y3(z80_n_reset),
	.a4(h_cnt[4]),
	.b4(n_hcnt5),
	.y4(hs_in)
);

//Invert the following signals:
//Horizontal counter bit 5, sprite RAM read enable, YM2149 BC1 and BDIR,
//watchdog output, watchdog clear
ls04 IC20
(
	.a1(h_cnt[5]),
	.y1(n_hcnt5),
	.a2(spr_ram_rd),
	.y2(spr_ram_n_rd),
	.a3(n_ym2149_bc1),
	.y3(ym2149_bc1),
	.a4(n_watchdog),
	.y4(watchdog),
	.a5(n_ym2149_bdir),
	.y5(ym2149_bdir),
	.a6(n_watchdog_clr),
	.y6(watchdog_clr)
);

//Watchdog
ls393 IC21
(
	.clk1(n_vblank),
	.clr1(watchdog_clr),
	.q1({watchdog_clk, 3'b000}), //q1[2:0] unused
	.clk2(watchdog_clk),
	.clr2(watchdog_clr),
	.q2({n_watchdog, 3'b000}) //q2[2:0] unused
);

//Blue color PROM
color_prom_3 IC22
(
	.ADDR(prom_addr),
	.CLK(clk_12m),
	.DATA(prom3_data),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_12m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp3_cs_i),
	.WR(ioctl_wr)
);

//Green color PROM
color_prom_2 IC23
(
	.ADDR(prom_addr),
	.CLK(clk_12m),
	.DATA(prom2_data),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_12m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp2_cs_i),
	.WR(ioctl_wr)
);

//Red color PROM
color_prom_1 IC24
(
	.ADDR(prom_addr),
	.CLK(clk_12m),
	.DATA(prom1_data),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_12m),
	.DATA_IN(ioctl_data),
	.CS_DL(cp1_cs_i),
	.WR(ioctl_wr)
);

//Address decoding based on Z80 address lines A3 and A4, active-high Z80 read, Z80 !WR
//and Z80 A12 high (generated by 74LS139)
ls155 IC25
(
	.a0(z80_A[3]),
	.a1(z80_A[4]),
	.n_ea({a_0x1000, z80_rd}),
	.n_eb({z80_n_wr, a_0x1000}),
	.o0({spinner_n_en, buttons1_n_en, buttons2_n_en, n_ym2149_bc1}),
	.o1({mcu_data_clk, n_watchdog_clr, z80_D_latch_clk, n_ym2149_bdir})
);

//The 74LS74 at IC26 is not present on bootlegs without an MCU - omit for now

//Latch spinner counter values to the Z80 (permanently enabled as data input to Z80
//is directly modelled) - this is normally done through the MCU, though bootlegs
//directly latch the spinner counters to the Z80 as a workaround
ls374 IC27
(
	.d({spin_cnt_h, spin_cnt_l}),
	.clk(clk_3m),
	.out_ctl(1'b0), //Directly modelled, keep permanently enabled
	.q({spinner_data[7:4], spinner_data[0], spinner_data[1], spinner_data[2], spinner_data[3]})
);

//The 74LS374 at IC28 is unnecessary on bootlegs without an MCU, omit for now

//Generate the following signals:
//HBlank, Z80 EPROM 2 chip enable, load input for sprite RAM counter
//Gate 1 unused, pull inputs low
ls32 IC29
(
	.a1(1'b0),
	.b1(1'b0),
	//y1 unused
	.a2(hblk_0),
	.b2(hblk_1),
	.y2(n_hblank),
	.a3(n_z80_A15),
	.b3(z80_A[14]),
	.y3(eprom2_n_ce),
	.a4(tilerom_shift_ld),
	.b4(h_active),
	.y4(spr_ram_cnt_load)
);
//Invert the following signals:
//Z80 address line A0, Z80 !RD, Z80 address line A15, bit 1 of horizontal counter
//(chip enable for tile ROMs)
//Inverters 3 and 5 unused, pull inputs low
ls04 IC30
(
	.a1(z80_A[0]),
	.y1(n_z80_A0),
	.a2(z80_n_rd),
	.y2(z80_rd),
	.a3(1'b0),
	//y3 unused
	.a4(z80_A[15]),
	.y4(n_z80_A15),
	.a5(1'b0),
	//y5 unused
	.a6(h_cnt[1]),
	.y6(tilerom_n_ce)
);

//Generate the following signals:
//Second part of HBlank, Z80 !INT input
ls74 IC31
(
	.n_pre1(1'b1),
	.n_clr1(1'b1),
	.clk1(n_clk_6m),
	.d1(hblk_0),
	.q1(hblk_1),
	//n_q1 unused
	.n_pre2(1'b1),
	.n_clr2(z80_n_iorq),
	.clk2(n_vblank),
	.d2(1'b1),
	//q2 unused
	.n_q2(z80_n_int)
);

//Latch Z80 data bus
ls273 IC32
(
	.d({z80_Dout[1], z80_Dout[0], z80_Dout[2], z80_Dout[3], z80_Dout[7:4]}),
	.clk(z80_D_latch_clk),
	.res(z80_n_reset),
	.q({z80_D1_latched, h_inv, spinner_sel, 2'bZZ, prom_addr[8], tilerom_A[14], eprom2_a15})
	//q[4] is the signal output for PC030CM, unused here
	//q[3] is a signal for the MCU, not implemented yet
);

//Send Z80 addresses A0 inverted (determine which 8-bit VRAM chip sends its data to
//the Z80), A9 - A11 to VRAM address lines when 3MHz clock is low, else Z
//Second buffer sends shot button input when button inputs are read into the Z80
ls244 IC33
(
	.n_g1(1'b0), //Directly modelled, keep permanently enabled
	.a1({z80_A[10:9], z80_A[11], n_z80_A0}),
	.y1({vram_Z80_A[9:8], vram_Z80_A[10], z80_n_A0}),
	.n_g2(1'b0), //Directly modelled, keep permanently enabled
	.a2({1'b1, btn_shot, btn_shot, 1'b1}), //a2[3] and a2[0] are unused inputs on the edge connector, pull high
	.y2({buttons1[1:0], buttons1[2], buttons1[3]})
);

//Write data into sprite RAM
ls244 IC34
(
	.n_g1(spr_ram_rd),
	.a1({bg[3], dot3, dot1, bg[4]}),
	.y1({spr_ram_Din[6], spr_ram_Din[1], spr_ram_Din[0], spr_ram_Din[3]}),
	.n_g2(spr_ram_rd),
	.a2({bg[0], bg[1], bg[2], dot2}),
	.y2({spr_ram_Din[7], spr_ram_Din[4], spr_ram_Din[5], spr_ram_Din[2]})
);

//Latch background data
ls174 IC35
(
	.d({vram_D[11], 1'b0, vram_D[14:12], vram_D[15]}),
	.clk(tilerom_n_ce),
	.mr(1'b1),
	.q({bg[4], 1'bZ, bg[3:0]})
);

//Latch horizontal position data from VRAM
ls374 IC36
(
	.d({vram_D[8], vram_D[15], vram_D[10], vram_D[13], vram_D[14], vram_D[12:11], vram_D[9]}),
	.clk(h_cnt[1]),
	.out_ctl(1'b0),
	.q(h_pos)
);

//Latch object data from sprite RAM
ls374 IC37
(
	.d({spr_ram_Dout[3], spr_ram_Dout[0], spr_ram_Dout[1], spr_ram_Dout[6], spr_ram_Dout[2], spr_ram_Dout[5:4], spr_ram_Dout[7]}),
	.clk(clk_6m),
	.out_ctl(1'b0),
	.q(obj)
);
//Multiplex objects and backgrounds to color PROM addresses (A0 - A3)
ls298 IC38
(
	.i0({obj[7], obj[3], obj[5], obj[6]}),
	.i1({scr[5], scr[6], scr[4], scr[7]}),
	.clk(clk_6m),
	.s(prom_addr_sel),
	.q(prom_addr[3:0])
);

//Multiplex objects and backgrounds to color PROM addresses (A4 - A7)
ls298 IC39
(
	.i0({obj[0], obj[4], obj[2], obj[1]}),
	.i1({scr[2], scr[1], scr[3], scr[0]}),
	.clk(clk_6m),
	.s(prom_addr_sel),
	.q(prom_addr[7:4])
);

//Latch background layer for sprite RAM
ls374 IC40
(
	.d({eprom3_shift, eprom5_shift, bg[4], eprom4_shift, bg[2], bg[0], bg[3], bg[1]}),
	.clk(clk_6m),
	.out_ctl(1'b0),
	.q(scr)
);

//Buffer Z80 address lines 1 - 8 and send to VRAM address lines 0 to 7 when 3MHz clock is high (Z otherwise)
ls244 IC41
(
	.n_g1(1'b0), //Directly modelled, keep permanently enabled
	.a1(z80_A[4:1]),
	.y1({vram_Z80_A[3], vram_Z80_A[2], vram_Z80_A[1], vram_Z80_A[0]}),
	.n_g2(1'b0), //Directly modelled, keep permanently enabled
	.a2({z80_A[5], z80_A[6], z80_A[7], z80_A[8]}),
	.y2({vram_Z80_A[4], vram_Z80_A[5], vram_Z80_A[6], vram_Z80_A[7]})
);

//IC42 is a 74LS245 used for transferring data between VRAM chips - omitted in favor of direct modeling of the
//multiplexed VRAM data bus

//Generate the following signals:
//VRAM H/L chip enable/output enable/write enable (all active low)
ls157 IC43
(
	.i0({z80_rd, z80_n_rd, sccs0, n_sccs0}),
	.i1(4'b1000),
	.n_e(1'b0),
	.s(clk_3m),
	.z({vram_we, vram_n_oe, vram_l_n_ce, vram_h_n_ce})
);

//Generate the following signals:
//VRAM read to Z80, sccs, (inverted) sccs0
ls32 IC44
(
	.a1(z80_n_rd),
	.b1(n_sccs),
	.y1(vram_n_rd),
	.a2(n_z80_A0),
	.b2(n_sccs),
	.y2(n_sccs0),
	.a3(z80_A[0]),
	.b3(n_sccs),
	.y3(sccs0),
	.a4(a_0x2000),
	.b4(z80_n_mreq),
	.y4(n_sccs)
);

//Generate the following signals
//h256, first part of HBlank
ls74 IC45
(
	.n_pre1(1'b1),
	.n_clr1(1'b1),
	.clk1(h_cnt[2]),
	.d1(h_cnt[7]),
	.q1(h256),
	.n_q1(n_h256),
	.n_pre2(1'b1),
	.n_clr2(1'b1),
	.clk2(clk_3m),
	.d2(h256),
	.q2(hblk_0)
	//n_q2 unused
);

//Generate the following signals
//Combined blank, active frame
//Gates 1 and 3 unused, pull inputs low
ls08 IC46
(
	.a1(1'b0),
	.b1(1'b0),
	//y1 unused
	.a2(n_vblank),
	.b2(n_hblank),
	.y2(n_blank),
	.a3(1'b0),
	.b3(1'b0),
	//y3 unused
	.a4(h_cnt[7]),
	.b4(h256),
	.y4(h_active)
);

//Multiplex data from VRAM to be used as addresses for the tile ROMs (A0 - A3)
ls298 IC47
(
	.i0(sr[3:0]),
	.i1({vram_D[0], vcnt1_xor, vcnt0_xor, vcnt_en_xor}),
	.clk(clk_3m),
	.s(h_cnt[7]),
	.q(tilerom_A[3:0])
);

//Multiplex data from VRAM to be used as addresses for the tile ROMs (A4 - A7)
ls298 IC48
(
	.i0(vram_D[3:0]),
	.i1(vram_D[4:1]),
	.clk(clk_3m),
	.s(h_cnt[7]),
	.q(tilerom_A[7:4])
);

//Multiplex data from VRAM to be used as addresses for the tile ROMs (A8 - A11)
ls298 IC49
(
	.i0(vram_D[7:4]),
	.i1(vram_D[8:5]),
	.clk(clk_3m),
	.s(h_cnt[7]),
	.q(tilerom_A[11:8])
);

//Multiplex data from VRAM to be used as addresses for the tile ROMs (A12 & A13)
//Also pass through INRE
ls298 IC50
(
	.i0({1'b0, inre, vram_D[9:8]}),
	.i1({2'b01, vram_D[10:9]}),
	.clk(clk_3m),
	.s(h_cnt[7]),
	.q({1'bZ, n_inre, tilerom_A[13:12]}) //q(3) unused
);

//Sprite RAM
spram_en #(8, 11) IC51
(
	.clk(clk_12m),
	.we(clk_6m),
	.re(~spr_ram_n_rd),
	.addr({2'b00, spr_ram_A}),
	.data(spr_ram_Din),
	.q(spr_ram_Dout)
);

//Generate sprite RAM addresses (A0 - A3)
ls669 IC52
(
	.d_in({h_pos_mux[2], h_pos_mux[3], h_pos_mux[1:0]}),
	.clk(n_clk_6m),
	.load(spr_ram_cnt_load),
	.n_en_p(1'b0),
	.n_en_t(1'b0),
	.u_d(spr_ram_u_d),
	.d_out(spr_ram_A[3:0]),
	.n_rco(spr_ram_cnt_carry)
);

//Multiplex horizontal position
ls157 IC53
(
	.i0({h_pos[5], h_pos[1], h_pos[0], h_pos[7]}),
	.i1({h_inv, h_inv, h_inv, h_inv}),
	.n_e(1'b0),
	.s(h_cnt[7]),
	.z(h_pos_mux[3:0])
);

//Generate the following signals:
//NOR of dot signals, enable for spinner counters, select line for sprite/background addresses
//to sprite RAM
ls27 IC54
(
	.a1(dot2),
	.b1(dot1),
	.c1(dot3),
	.y1(n_dot123),
	.a2(z80_A[2]),
	.b2(buttons2_n_en),
	.c2(1'b0),
	.y2(spin_cnt_n_en),
	.a3(obj[6]),
	.b3(obj[5]),
	.c3(obj[3]),
	.y3(prom_addr_sel)
);

//IC55 is a 74LS373 used to send data from VRAM to the Z80 - omitted in favor of a direct connection
//IC56 is a 74LS244 that sends data from the Z80 to VRAM - omitted in favor of a direct connection

//Multiplex VRAM address lines based on 3MHz clock logic level
assign vram_A = !clk_3m ? vram_Z80_A:
					vram_mux_A;

//VRAM (upper 8 bits)
spram #(8, 11) IC57
(
	.clk(clk_12m),
	.we(~vram_l_n_ce & ~vram_n_we),
	.addr(vram_A),
	.data(z80_Dout),
	.q(vram_D[15:8])
);

//VRAM (lower 8 bits)
spram #(8, 11) IC58
(
	.clk(clk_12m),
	.we(~vram_h_n_ce & ~vram_n_we),
	.addr(vram_A),
	.data(z80_Dout),
	.q(vram_D[7:0])
);

//Latch background data from VRAM based on bit 1 of the horizontal counter
ls374 IC59
(
	.d({vram_D[6], vram_D[4:3], vram_D[1], vram_D[2], vram_D[0], vram_D[7], vram_D[5]}),
	.clk(h_cnt[1]),
	.out_ctl(1'b0),
	.q(bg_data)
);

//Sum background and sprite graphics (upper 4 bits)
ls283 IC60
(
	.a({bg_data[1], bg_data[7], bg_data[0], bg_data[6]}),
	.b({vcnt6_xor, vcnt5_xor, vcnt4_xor, vcnt3_xor}),
	.c_in(sr_carry),
	.sum(sr[7:4])
	//c_out unused
);
//Sum background and sprite graphics (lower 4 bits)
ls283 IC61
(
	.a({bg_data[5], bg_data[3], bg_data[4], bg_data[2]}),
	.b({vcnt2_xor, vcnt1_xor, vcnt0_xor, vcnt_en_xor}),
	.c_in(1'b0),
	.sum(sr[3:0]),
	.c_out(sr_carry)
);

//Tile ROMs
eprom_5 IC62
(
	.ADDR(tilerom_A),
	.CLK(clk_12m),
	.ENA(tilerom_n_ce),
	.DATA(eprom5_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_12m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep5_cs_i),
	.WR(ioctl_wr)
);
eprom_4 IC63
(
	.ADDR(tilerom_A),
	.CLK(clk_12m),
	.ENA(tilerom_n_ce),
	.DATA(eprom4_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_12m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep4_cs_i),
	.WR(ioctl_wr)
);
eprom_3 IC64
(
	.ADDR(tilerom_A),
	.CLK(clk_12m),
	.ENA(tilerom_n_ce),
	.DATA(eprom3_D),
	.ADDR_DL(ioctl_addr),
	.CLK_DL(clk_12m),
	.DATA_IN(ioctl_data),
	.CS_DL(ep3_cs_i),
	.WR(ioctl_wr)
);

//Generate sprite RAM addresses (A4 - A7)
ls669 IC65
(
	.d_in({h_pos_mux[6], h_pos_mux[7], h_pos_mux[5:4]}),
	.clk(n_clk_6m),
	.load(spr_ram_cnt_load),
	.n_en_p(spr_ram_cnt_carry),
	.n_en_t(spr_ram_cnt_carry),
	.u_d(spr_ram_u_d),
	.d_out(spr_ram_A[7:4])
	//n_rco unused
);

//Horizontal position of sprites
ls157 IC66
(
	.i0({h_pos[3], h_pos[6], h_pos[4], h_pos[2]}),
	.i1({h_inv, h_inv, h_inv, h_inv}),
	.n_e(1'b0),
	.s(h_cnt[7]),
	.z(h_pos_mux[7:4])
);

//Horizontal counter (upper 4 bits)
ls161 IC67
(
	.n_clr(1'b1),
	.clk(n_clk_6m),
	.din(4'b0100),
	.enp(h_cnt_cascade),
	.ent(h_cnt_cascade),
	.n_load(h_cnt_upper_n_ld),
	.q(h_cnt[7:4]),
	.rco(h_cnt_carry)
);

//Horizontal counter (lower 4 bits)
ls161 IC68
(
	.n_clr(1'b1),
	.clk(n_clk_6m),
	.din(4'h0),
	.enp(clk_3m),
	.ent(clk_3m),
	.n_load(1'b1),
	.q(h_cnt[3:0]),
	.rco(h_cnt_cascade)
);

//NAND gate for tile ROM shift registers (generates shift/load input)
ls20 IC69
(
	.a1(1'b1),
	.b1(h_cnt[0]),
	.c1(h_cnt[1]),
	.d1(clk_3m),
	.y1(tilerom_shift_ld),
	.a2(1'b0),
	.b2(1'b0),
	.c2(1'b0),
	.d2(1'b0)
	//y2 unused
);

//Multiplex background and sprite tile addresses for VRAM (A0 - A3)
ls257 IC70
(
	.a(h_cnt[4:1]),
	.b({hcnt5_xor, hcnt4_xor, hcnt3_xor, hcnt2_xor}),
	.out_ctl(1'b0), //Directly modelled, keep permanently enabled
	.sel(h_cnt[7]),
	.y(vram_mux_A[3:0])
);

//Multiplex background and sprite tile addresses for VRAM (A4 - A7)
ls257 IC71
(
	.a({3'b000, h_cnt[5]}),
	.b({vcnt4_xor, vcnt3_xor, vcnt2_xor, hcnt6_xor}),
	.out_ctl(1'b0), //Directly modelled, keep permanently enabled
	.sel(h_cnt[7]),
	.y(vram_mux_A[7:4])
);

//Multiplex background and sprite tile addresses for VRAM (A8 - A10)
ls257 IC72
(	
	.a(4'b0100),
	.b({2'b0, vcnt6_xor, vcnt5_xor}),
	.out_ctl(1'b0), //Directly modelled, keep permanently enabled
	.sel(h_cnt[7]),
	.y({1'bZ, vram_mux_A[10:8]}) //y(3) unused
);

//Vertical counter (lower 4 bits)
ls161 IC73
(
	.n_clr(1'b1),
	.clk(v_cnt_clk),
	.din(4'b1100),
	.enp(v_cnt_en),
	.ent(v_cnt_en),
	.n_load(v_cnt_n_ld),
	.q(v_cnt[3:0]),
	.rco(v_cnt_cascade)
);

//Vertical counter (upper 4 bits)
ls161 IC74
(
	.n_clr(1'b1),
	.clk(v_cnt_clk),
	.din(4'b0111),
	.enp(v_cnt_cascade),
	.ent(v_cnt_cascade),
	.n_load(v_cnt_n_ld),
	.q(v_cnt[7:4]),
	.rco(v_cnt_carry)
);

//Generate the following signals:
//Input for VBlank flip-flop, INRE
ls20 IC75
(
	.a1(1'b1),
	.b1(v_cnt[4]),
	.c1(v_cnt[5]),
	.d1(v_cnt[6]),
	.y1(vb_in),
	.a2(sr[7]),
	.b2(sr[6]),
	.c2(sr[4]),
	.d2(sr[5]),
	.y2(inre)
);

//Generate the following signals:
//Dot clock, (inverted) 6MHz clock
ls74 IC76
(
	.n_pre1(1'b1),
	.n_clr1(1'b1),
	.clk1(tilerom_n_ce),
	.d1(n_inre),
	//q1 unused
	.n_q1(n_dot),
	.n_pre2(1'b1),
	.n_clr2(1'b1),
	.clk2(clk_12m),
	.d2(n_clk_6m),
	.q2(clk_6m),
	.n_q2(n_clk_6m)
);

//Left/right shift data from 3rd tile ROM
mb112s146 IC77
(
	.n_clr(1'b1),
	.shift_ld(tilerom_shift_ld),
	.sel(flip_sel),
	.clk(n_clk_6m),
	.s_in(2'b00),
	.d2_in(8'h00), //This shift register is unused, pull inputs low
	.d1_in(eprom5_D),
	.shift_out({1'bZ, eprom5_shift}) //Shift register 1 unused
);

//Left/right shift data from 1st and 2nd tile ROM
mb112s146 IC78
(
	.n_clr(1'b1),
	.shift_ld(tilerom_shift_ld),
	.sel(flip_sel),
	.clk(n_clk_6m),
	.s_in(2'b00),
	.d2_in(eprom3_D),
	.d1_in(eprom4_D),
	.shift_out({eprom3_shift, eprom4_shift})
);

//Generate the following signals:
//Up/down for counters generating sprite RAM addresses, load input for vertical counter,
//NAND of Z80 address lines A14 and A15 (output 0 when both are 0)
//Gate 1 unused, pull inputs low
ls00 IC79
(
	.a1(1'b0),
	.b1(1'b0),
	//y1 unused
	.a2(h_inv),
	.b2(h256),
	.y2(spr_ram_u_d),
	.a3(1'b1),
	.b3(v_cnt_carry),
	.y3(v_cnt_n_ld),
	.a4(z80_A[15]),
	.b4(z80_A[14]),
	.y4(n_z80_A14_A15)
);

//Address decoding based on the following address lines from the Z80:
//A3, A4, A12 - A15
ls139 IC80
(
	.n_e({a_0x1000, n_z80_A14_A15}),
	.a0({z80_A[3], z80_A[12]}),
	.a1({z80_A[4],z80_A[13]}),
	.o0({1'bZ, a_0x2000, a_0x1000, z80_ram_n_ce}), //o0[3] unused
	.o1({3'bZZZ, a_0x1000_2}) //o1[3:1] unused
);

//Generate the following signals:
//HSync, (inverted) 3MHz clock
ls74 IC81
(
	.n_pre1(1'b1),
	.n_clr1(v_cnt_clk),
	.clk1(h_cnt[3]),
	.d1(hs_in),
	.q1(hsync),
	//n_q1 unused
	.n_pre2(1'b1),
	.n_clr2(1'b1),
	.clk2(n_clk_6m),
	.d2(n_clk_3m),
	.q2(clk_3m), //Connect to MCU when implemented
	.n_q2(n_clk_3m)
);

//Generate the following signals:
//XOR horizontal counter bits 4 - 6, load for upper 4-bit horizontal counter
ls86 IC82
(
	.a1(h_cnt[5]),
	.b1(h_inv),
	.y1(hcnt5_xor),
	.a2(h_cnt[6]),
	.b2(h_inv),
	.y2(hcnt6_xor),
	.a3(h_cnt[4]),
	.b3(h_inv),
	.y3(hcnt4_xor),
	.a4(h_cnt_carry),
	.b4(1'b1),
	.y4(h_cnt_upper_n_ld)
);

//Generate the following signals:
//clock for vertical counter based on most significant bit of horizontal counter,
//composite sync (unused for MISTer), XOR horizontal counter bits 2 and 3
ls86 IC83
(
	.a1(1'b1),
	.b1(h_cnt[7]),
	.y1(v_cnt_clk),
	.a2(v_cnt[7]),
	.b2(hsync),
	.y2(video_csync),
	.a3(h_cnt[2]),
	.b3(h_inv),
	.y3(hcnt2_xor),
	.a4(h_inv),
	.b4(h_cnt[3]),
	.y4(hcnt3_xor)
);

//Generate the following signals:
//SCCS for WAIT signal, VRAM write enable (active low) based on inverted 6MHz clock
//Gates 1 and 2 unused, pull inputs low
ls32 IC84
(
	.a1('0),
	.b1('0),
	//y1 unused
	.a2('0),
	.b2('0),
	//y2 unused
	.a3(n_sccs),
	.b3(n_clk_3m),
	.y3(n_sccs_wait),
	.a4(vram_we),
	.b4(n_clk_6m),
	.y4(vram_n_we)
);

//Generate Z80 !WAIT signal
//Only gate 3 used, pull all other inputs low
ls08 IC85
(
	.a1(1'b0),
	.b1(1'b0),
	//y1 unused
	.a2(1'b0),
	.b2(1'b0),
	//y2 unused
	.a3(n_sccs_wait),
	.b3(n_wait),
	.y3(z80_n_wait),
	.a4(1'b0),
	.b4(1'b0)
	//y4 unused
);

//Generate the following signals:
//WAIT signal, PRE for WAIT signal
ls74 IC86
(
	.n_pre1(wait_pre),
	.n_clr1(1'b1),
	.clk1(n_clk_6m),
	.d1(a_0x1000_2),
	.q1(n_wait),
	//n_q1 unused
	.n_pre2(1'b1),
	.n_clr2(1'b1),
	.clk2(n_clk_6m),
	.d2(n_wait),
	.q2(wait_pre)
	//n_q2 unused
);

//Generate the following signals:
//Enable for vertical counter (normal and inverted), VBlank
ls74 IC87
(
	.n_pre1(1'b1),
	.n_clr1(1'b1),
	.clk1(v_cnt_clk),
	.d1(n_v_cnt_en),
	.q1(v_cnt_en),
	.n_q1(n_v_cnt_en),
	.n_pre2(1'b1),
	.n_clr2(1'b1),
	.clk2(v_cnt[3]),
	.d2(vb_in),
	.q2(n_vblank) //Connect to MCU when implemented
	//n_q2 unused
);

//XOR vertical counter bits 0 - 2 and enable with latched Z80 D1 data line
ls86 IC88
(
	.a1(v_cnt[2]),
	.b1(z80_D1_latched),
	.y1(vcnt2_xor),
	.a2(v_cnt_en),
	.b2(z80_D1_latched),
	.y2(vcnt_en_xor),
	.a3(v_cnt[0]),
	.b3(z80_D1_latched),
	.y3(vcnt0_xor),
	.a4(v_cnt[1]),
	.b4(z80_D1_latched),
	.y4(vcnt1_xor)
);

//XOR vertical counter bits 3 - 6 with latched Z80 D1 data line
ls86 IC89
(
	.a1(v_cnt[3]),
	.b1(z80_D1_latched),
	.y1(vcnt3_xor),
	.a2(v_cnt[4]),
	.b2(z80_D1_latched),
	.y2(vcnt4_xor),
	.a3(v_cnt[5]),
	.b3(z80_D1_latched),
	.y3(vcnt5_xor),
	.a4(v_cnt[6]),
	.b4(z80_D1_latched),
	.y4(vcnt6_xor)
);

//Generate the following signals:
//Select line for screen flipping, dot signals
ls08 IC90
(
	.a1(h_inv),
	.b1(h256),
	.y1(flip_sel),
	.a2(eprom3_shift),
	.b2(n_dot),
	.y2(dot1),
	.a3(eprom5_shift),
	.b3(n_dot),
	.y3(dot2),
	.a4(n_dot),
	.b4(eprom4_shift),
	.y4(dot3)
);

endmodule
