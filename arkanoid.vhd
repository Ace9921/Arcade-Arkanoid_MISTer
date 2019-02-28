--============================================================================
-- 
--  Arkanoid top-level module
--  Copyright (C) 2018, 2019 Ace, Enforcer, Ash Evans (aka ElectronAsh/OzOnE)
--  and Kitrinx (aka Rysha)
--
--  Permission is hereby granted, free of charge, to any person obtaining a
--  copy of this software and associated documentation files (the "Software"),
--  to deal in the Software without restriction, including without limitation
--	 the rights to use, copy, modify, merge, publish, distribute, sublicense,
--	 and/or sell copies of the Software, and to permit persons to whom the 
--	 Software is furnished to do so, subject to the following conditions:
--
--  The above copyright notice and this permission notice shall be included in
--	 all copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--	 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--	 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--	 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--	 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
--	 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
--	 DEALINGS IN THE SOFTWARE.
--
--============================================================================

library IEEE;
use IEEE.std_logic_1164.all;

--Entity declaration, I/O ports
entity arkanoid is
port
(
	reset									: in std_logic;
	spinner								: in std_logic_vector(1 downto 0);	--1 = left, 0 = right
	coin1, coin2						: in std_logic;
	btn_shot, btn_service, tilt	: in std_logic;
	btn_1p_start, btn_2p_start		: in std_logic;
	
	clk_24m								: in std_logic;
	clk_12m								: in std_logic;
	ym2149_clk_div						: in std_logic;
	dip_sw								: in std_logic_vector(7 downto 0);
	
	sound									: out std_logic_vector(7 downto 0);
	video_hsync, video_vsync		: out std_logic;
	video_csync							: out std_logic;
	video_vblank, video_hblank		: out std_logic;
	video_r								: out std_logic_vector(3 downto 0);
	video_g								: out std_logic_vector(3 downto 0);
	video_b								: out std_logic_vector(3 downto 0);

	ioctl_addr							: in std_logic_vector(24 downto 0);
	ioctl_download						: in std_logic;
	ioctl_data							: in std_logic_vector(7 downto 0);
	ioctl_wr								: in std_logic
);
end arkanoid;

architecture virt_pcb of arkanoid is
--CPU (Zilog Z80)
component T80s
port
(
	RESET_n		: in std_logic;
	CLK			: in std_logic;
	CEN			: in std_logic;
	WAIT_n		: in std_logic;
	INT_n			: in std_logic;
	NMI_n			: in std_logic;
	BUSRQ_n		: in std_logic;
	M1_n			: out std_logic;
	MREQ_n		: out std_logic;
	IORQ_n		: out std_logic;
	RD_n			: out std_logic;
	WR_n			: out std_logic;
	RFSH_n		: out std_logic;
	HALT_n		: out std_logic;
	BUSAK_n		: out std_logic;
	A				: out std_logic_vector(15 downto 0);
	DI				: in std_logic_vector(7 downto 0);
	DO				: out std_logic_vector(7 downto 0)
);
end component;

--ROM
component selector
port
(
	ioctl_addr	: in std_logic_vector(24 downto 0);
	ep1_cs		: out std_logic;
	ep2_cs		: out std_logic;
	ep3_cs		: out std_logic;
	ep4_cs		: out std_logic;
	ep5_cs		: out std_logic;
	cp1_cs		: out std_logic;
	cp2_cs		: out std_logic;
	cp3_cs		: out std_logic
);
end component;

component eprom_1
port
(
	addr		: in std_logic_vector(14 downto 0);
	clk		: in std_logic;
	data		: out std_logic_vector(7 downto 0);
	clk_dl	: in std_logic;
	addr_dl	: in std_logic_vector(24 downto 0);
	cs_dl		: in std_logic;
	data_in	: in std_logic_vector(7 downto 0);
	wr			: in std_logic
);
end component;

component eprom_2
port
(
	addr		: in std_logic_vector(14 downto 0);
	clk		: in std_logic;
	data		: out std_logic_vector(7 downto 0);
	clk_dl	: in std_logic;
	addr_dl	: in std_logic_vector(24 downto 0);
	cs_dl		: in std_logic;
	data_in	: in std_logic_vector(7 downto 0);
	wr			: in std_logic
);
end component;

component eprom_3
port
(
	clk		: in std_logic;
	ena		: in std_logic;
	addr		: in std_logic_vector(14 downto 0);
	data		: out std_logic_vector(7 downto 0);
	clk_dl	: in std_logic;
	addr_dl	: in std_logic_vector(24 downto 0);
	cs_dl		: in std_logic;
	data_in	: in std_logic_vector(7 downto 0);
	wr			: in std_logic
);
end component;

component eprom_4
port
(
	clk		: in std_logic;
	ena		: in std_logic;
	addr		: in std_logic_vector(14 downto 0);
	data		: out std_logic_vector(7 downto 0);
	clk_dl	: in std_logic;
	addr_dl	: in std_logic_vector(24 downto 0);
	cs_dl		: in std_logic;
	data_in	: in std_logic_vector(7 downto 0);
	wr			: in std_logic
);
end component;

component eprom_5
port
(
	clk		: in std_logic;
	ena		: in std_logic;
	addr		: in std_logic_vector(14 downto 0);
	data		: out std_logic_vector(7 downto 0);
	clk_dl	: in std_logic;
	addr_dl	: in std_logic_vector(24 downto 0);
	cs_dl		: in std_logic;
	data_in	: in std_logic_vector(7 downto 0);
	wr			: in std_logic
);
end component;

--Color PROMs
component color_prom_1
port
(
	clk		: in std_logic;
	addr		: in std_logic_vector(8 downto 0);
	data		: out std_logic_vector(3 downto 0);
	clk_dl	: in std_logic;
	addr_dl	: in std_logic_vector(24 downto 0);
	cs_dl		: in std_logic;
	data_in	: in std_logic_vector(7 downto 0);
	wr			: in std_logic
);
end component;

component color_prom_2
port
(
	clk		: in std_logic;
	addr		: in std_logic_vector(8 downto 0);
	data		: out std_logic_vector(3 downto 0);
	clk_dl	: in std_logic;
	addr_dl	: in std_logic_vector(24 downto 0);
	cs_dl		: in std_logic;
	data_in	: in std_logic_vector(7 downto 0);
	wr			: in std_logic
);
end component;

component color_prom_3
port
(
	clk		: in std_logic;
	addr		: in std_logic_vector(8 downto 0);
	data		: out std_logic_vector(3 downto 0);
	clk_dl	: in std_logic;
	addr_dl	: in std_logic_vector(24 downto 0);
	cs_dl		: in std_logic;
	data_in	: in std_logic_vector(7 downto 0);
	wr			: in std_logic
);
end component;

--Custom chips
component mb112s146
port
(
	n_clr, shift_ld				: in std_logic;
	sel								: in std_logic;
	clk								: in std_logic;
	s_in								: in std_logic_vector(1 downto 0);
	d1_in, d2_in					: in std_logic_vector(7 downto 0);
	shift_out						: out std_logic_vector(1 downto 0)
);
end component;
--See mb112s146.vhd for chip pinout

--Sound chip (Yamaha YM2149)
component ym2149
port
(
	I_DA			: in std_logic_vector(7 downto 0);
	O_DA			: out std_logic_vector(7 downto 0);
	O_DA_OE_L	: out std_logic;
	I_A9_L		: in std_logic;
	I_A8			: in std_logic;
	I_BDIR		: in std_logic;
	I_BC2			: in std_logic;
	I_BC1			: in std_logic;
	I_SEL_L		: in std_logic;
	O_AUDIO		: out std_logic_vector(7 downto 0);
	I_IOA			: in std_logic_vector(7 downto 0);
	O_IOA			: out std_logic_vector(7 downto 0);
	O_IOA_OE_L	: out std_logic;
	I_IOB			: in std_logic_vector(7 downto 0);
	O_IOB			: out std_logic_vector(7 downto 0);
	O_IOB_OE_L	: out std_logic;
	ENA			: in std_logic;
	RESET_L		: in std_logic;
	CLK			: in std_logic
);
end component;

--Discrete logic
component ls00
port
(
	a1, a2, a3, a4	: in std_logic;
	b1, b2, b3, b4	: in std_logic;
	y1, y2, y3, y4	: out std_logic
);
end component;
--See ls00.vhd for chip pinout

component ls04
port
(
	a1, a2, a3, a4, a5, a6	: in std_logic;
	y1, y2, y3, y4, y5, y6	: out std_logic
);
end component;
--See ls04.vhd for chip pinout

component ls08
port
(
	a1, a2, a3, a4	: in std_logic;
	b1, b2, b3, b4	: in std_logic;
	y1, y2, y3, y4	: out std_logic
);
end component;
--See ls08.vhd for chip pinout

component ls17
port
(
	a1, a2, a3, a4, a5, a6	: in std_logic;
	y1, y2, y3, y4, y5, y6	: out std_logic
);
end component;
--See ls17.vhd for chip pinout

component ls20
port
(
	a1, b1, c1, d1	: in std_logic;
	a2, b2, c2, d2	: in std_logic;
	y1, y2			: out std_logic
);
end component;
--See ls20.vhd for chip pinout

component ls27
port
(
	a1, a2, a3	: in std_logic;
	b1, b2, b3	: in std_logic;
	c1, c2, c3	: in std_logic;
	y1, y2, y3	: out std_logic
);
end component;
--See ls27.vhd for chip pinout

component ls32
port
(
	a1, a2, a3, a4	: in std_logic;
	b1, b2, b3, b4	: in std_logic;
	y1, y2, y3, y4	: out std_logic	
);
end component;
--See ls32.vhd for chip pinout

component ls74
port
(
	n_pre1, n_pre2			: in std_logic;
	n_clr1, n_clr2			: in std_logic;
	clk1, clk2				: in std_logic;
	d1, d2					: in std_logic;
	q1, n_q1, q2, n_q2	: out std_logic
);
end component;
--See ls74.vhd for chip pinout

component ls86
port
(
	a1, a2, a3, a4	: in std_logic;
	b1, b2, b3, b4	: in std_logic;
	y1, y2, y3, y4	: out std_logic
);
end component;
--See ls86.vhd for chip pinout

component ls139
port
(
	a0		: in std_logic_vector(1 downto 0);
	a1		: in std_logic_vector(1 downto 0);
	n_e	: in std_logic_vector(1 downto 0);
	o0		: out std_logic_vector(3 downto 0);
	o1		: out std_logic_vector(3 downto 0)
);
end component;
--See ls139.vhd for chip pinout

component ls155
port
(
	a0, a1	: in std_logic;
	n_ea		: in std_logic_vector(1 downto 0);	--n_ea(0) active high, n_ea(1) active low
	n_eb		: in std_logic_vector(1 downto 0);
	o0			: out std_logic_vector(3 downto 0);
	o1			: out std_logic_vector(3 downto 0)
);
end component;
--See ls155.vhd for chip pinout

component ls157
port
(
	i0		: in std_logic_vector(3 downto 0);
	i1		: in std_logic_vector(3 downto 0);
	n_e	: in std_logic;
	s		: in std_logic;
	z		: out std_logic_vector(3 downto 0)
);
end component;
--See ls157.vhd for chip pinout

component ls161
port
(
	n_clr		: in std_logic;
	clk		: in std_logic;
	din		: in std_logic_vector(3 downto 0);
	enp, ent	: in std_logic;
	n_load	: in std_logic;
	q			: out std_logic_vector(3 downto 0);
	rco		: out std_logic
);
end component;
--See ls161.vhd for chip pinout

component ls174
port
(
	d		: in std_logic_vector(5 downto 0);
	clk	: in std_logic;
	mr		: in std_logic;
	q		: out std_logic_vector(5 downto 0)
);
end component;
--See ls174.vhd for chip pinout

component ls244
port
(
	n_g1, n_g2	: in std_logic;
	a1				: in std_logic_vector(3 downto 0);
	a2				: in std_logic_vector(3 downto 0);
	y1				: out std_logic_vector(3 downto 0);
	y2				: out std_logic_vector(3 downto 0)
);
end component;
--See ls244.vhd for chip pinout

component ls257
port
(
	a			: in std_logic_vector(3 downto 0);
	b			: in std_logic_vector(3 downto 0);
	out_ctl	: in std_logic;
	sel		: in std_logic;
	y			: out std_logic_vector(3 downto 0)
);
end component;
--See ls257.vhd for chip pinout

component ls273
port
(
	d		: in std_logic_vector(7 downto 0);
	clk	: in std_logic;
	res	: in std_logic;
	q		: out std_logic_vector(7 downto 0)
);
end component;
--See ls273.vhd for chip pinout

component ls283
port
(
	a		: in std_logic_vector(3 downto 0);
	b		: in std_logic_vector(3 downto 0);
	c_in	: in std_logic;
	sum	: out std_logic_vector(3 downto 0);
	c_out	: out std_logic
);
end component;
--See ls283.vhd for chip pinout

component ls298
port
(
	i0		: in std_logic_vector(3 downto 0);
	i1		: in std_logic_vector(3 downto 0);
	clk	: in std_logic;
	s		: in std_logic;
	q		: out std_logic_vector(3 downto 0)
);
end component;
--See ls298.vhd for chip pinout

component ls373
port
(
	d			: in std_logic_vector(7 downto 0);
	g			: in std_logic;
	out_ctl	: in std_logic;
	q			: out std_logic_vector(7 downto 0)
);
end component;
--See ls373.vhd for chip pinout

component ls374
port
(
	d			: in std_logic_vector(7 downto 0);
	clk		: in std_logic;
	out_ctl	: in std_logic;
	q			: out std_logic_vector(7 downto 0)
);
end component;
--See ls374.vhd for chip pinout

component ls393
port
(
	clk1, clk2	: in std_logic;
	clr1, clr2	: in std_logic;
	q1, q2		: out std_logic_vector(3 downto 0)
);
end component;
--See ls393.vhd for chip pinout

component ls669
port
(
	d_in		: in std_logic_vector(3 downto 0);
	clk		: in std_logic;
	load		: in std_logic;
	n_en_p	: in std_logic;
	n_en_t	: in std_logic;
	u_d		: in std_logic;
	d_out		: out std_logic_vector(3 downto 0);
	n_rco		: out std_logic
);
end component;
--See ls669.vhd for chip pinout

component cmos_4584
port
(
	in1, in2, in3, in4, in5, in6			: in std_logic;
	out1, out2, out3, out4, out5, out6	: out std_logic
);
end component;
--See cmos_4584.vhd for chip pinout

--Z80 signals
signal z80_n_reset, z80_n_wait, z80_n_int, z80_n_m1,
		z80_n_mreq, z80_n_iorq, z80_n_rd, z80_n_wr			: std_logic;
signal z80_A															: std_logic_vector(15 downto 0);
signal z80_Din, z80_Dout, z80_ram_D								: std_logic_vector(7 downto 0);

--Tile ROM signals
signal tilerom_A														: std_logic_vector(14 downto 0);
signal eprom1_D, eprom2_D, eprom3_D, eprom4_D, eprom5_D	: std_logic_vector(7 downto 0);

--Color PROM signals
signal prom_addr														: std_logic_vector(8 downto 0);
signal prom1_data, prom2_data, prom3_data						: std_logic_vector(3 downto 0);

--ROM loader signals for MISTer (loads ROMs from SD card)
signal ep1_cs_i, ep2_cs_i, ep3_cs_i, ep4_cs_i, ep5_cs_i	: std_logic;
signal cp1_cs_i, cp2_cs_i, cp3_cs_i								: std_logic;
signal ioctl_wr_in													: std_logic;
signal ioctl_addr_in													: std_logic_vector(24 downto 0);
signal ioctl_data_in													: std_logic_vector(7 downto 0);

--VRAM signals
signal vram_A, vram_mux_A, vram_Z80_A							: std_logic_vector(10 downto 0);
signal vram_D															: std_logic_vector(15 downto 0);
signal vram_l_n_ce, vram_h_n_ce, vram_n_oe, vram_n_we		: std_logic;

--Sprite RAM signals
signal spr_ram_A														: std_logic_vector(8 downto 0);
signal spr_ram_Din, spr_ram_Dout									: std_logic_vector(7 downto 0);

--YM2149 signals
signal ym2149_data, dipsw_in										: std_logic_vector(7 downto 0);
signal ym2149_bc1, ym2149_bdir									: std_logic;

--Clocks
signal clk_3m, n_clk_3m, clk_6m, n_clk_6m						: std_logic;

--Horizontal/vertical counters
signal h_cnt, v_cnt													: std_logic_vector(7 downto 0);
signal h_cnt_cascade, h_cnt_carry, h_cnt_upper_n_ld		: std_logic;
signal v_cnt_clk, v_cnt_carry, v_cnt_cascade					: std_logic;

--User inputs
signal buttons1														: std_logic_vector(3 downto 0);
signal buttons2														: std_logic_vector(7 downto 0);
signal n_spinner1, n_spinner2										: std_logic_vector(1 downto 0);

--Video sync/blanking (VSync is the most significant bit of the vertical
--counter, not explicitly defined within this section)
signal vb_in															: std_logic;
signal hs_in, hsync													: std_logic;
signal n_hblank, n_vblank, n_blank								: std_logic;
signal hblank_out, vblank_out										: std_logic;

--Internal linking signals (signal names may not be entirely accurate)
signal eprom3_shift, eprom4_shift, eprom5_shift,
		flip_sel															: std_logic;
signal vcnt0_xor, vcnt1_xor, vcnt2_xor, vcnt3_xor,
		vcnt4_xor, vcnt5_xor, vcnt6_xor, vcnt_en_xor			: std_logic;
signal v_cnt_en, n_v_cnt_en, v_cnt_n_ld						: std_logic;
signal hcnt2_xor, hcnt3_xor, hcnt4_xor, hcnt5_xor,
		hcnt6_xor, n_hcnt5											: std_logic;
signal a_0x1000, a_0x1000_2, a_0x2000							: std_logic;
signal z80_n_A0, n_z80_A0, n_z80_A15, n_z80_A14_A15,
		z80_ram_n_ce													: std_logic;
signal eprom2_a15														: std_logic;
signal spr_ram_u_d, vram_n_rd, vram_we							: std_logic;
signal tilerom_shift_ld												: std_logic;
signal prom_addr_sel													: std_logic;
signal watchdog_clk, watchdog, n_watchdog, watchdog_clr,
		n_watchdog_clr													: std_logic;
signal spr_ram_rd, spr_ram_n_rd									: std_logic;
signal n_reset, reset2												: std_logic;
signal n_ym2149_bc1, n_ym2149_bdir								: std_logic;
signal h_inv															: std_logic;
signal z80_rd															: std_logic;
signal spin_cnt_clk, spin_cnt_u_d, spin_cnt_carry			: std_logic;
signal eprom2_n_ce, tilerom_n_ce									: std_logic;
signal z80_D1_latched, z80_D_latch_clk, mcu_data_clk		: std_logic;
signal spr_ram_cnt_carry, spr_ram_cnt_load					: std_logic;
signal inre, n_inre													: std_logic;
signal hblk_0, hblk_1												: std_logic;
signal dot1, dot2, dot3, n_dot123, n_dot						: std_logic;
signal sr_carry														: std_logic;
signal h256, n_h256, h_active										: std_logic;
signal n_sccs, sccs0, n_sccs0										: std_logic;
signal wait_pre, n_wait, n_sccs_wait							: std_logic;
signal buttons1_n_en, buttons2_n_en, spinner_n_en			: std_logic;
signal spinner_sel, spin_cnt_n_en								: std_logic;
signal spin_cnt_h, spin_cnt_l										: std_logic_vector(3 downto 0);
signal bg																: std_logic_vector(4 downto 0);
signal sr, h_pos, h_pos_mux, bg_data, scr, obj, 
		spinner_data													: std_logic_vector(7 downto 0);

begin
	--Reverse DIP switch order
	dipsw_in <= dip_sw(0) & dip_sw(1) & dip_sw(2) & dip_sw(3) & dip_sw(4) & dip_sw(5) & dip_sw(6) & dip_sw(7);

	--Video sync & blanking
	video_hsync <= hsync;
	video_vsync <= v_cnt(7);
	hblank_out <= n_hblank;
	vblank_out <= n_vblank;
	video_vblank <= vblank_out;
	video_hblank <= hblank_out;
	
	--Direct modelling of data inputs to the Z80
	z80_Din <= eprom1_D when (not z80_A(15) and not z80_n_rd)
			else eprom2_D when (not eprom2_n_ce and not z80_n_rd)
			else z80_ram_D when (not z80_ram_n_ce and not z80_n_rd)
			else ym2149_data when (not ym2149_bdir and z80_A(0) and ym2149_bc1)
			else vram_D(7 downto 0) when (not vram_n_oe and not vram_h_n_ce and z80_rd and not z80_n_A0 and not vram_n_rd)
			else vram_D(15 downto 8) when (not vram_n_oe and not vram_l_n_ce and z80_n_A0 and not vram_n_rd)
			else ("1111" & buttons1) when not buttons1_n_en
			else buttons2 when not buttons2_n_en
			else spinner_data(7 downto 4) & spinner_data(0) & spinner_data(1) & spinner_data(2) & spinner_data(3) when not spinner_n_en
			else (others => '1');
	
	--MiSTer data write selector
	DLSEL: selector
	port map
	(
		ioctl_addr => ioctl_addr,
		ep1_cs => ep1_cs_i,
		ep2_cs => ep2_cs_i,
		ep3_cs => ep3_cs_i,
		ep4_cs => ep4_cs_i,
		ep5_cs => ep5_cs_i,
		cp1_cs => cp1_cs_i,
		cp2_cs => cp2_cs_i,
		cp3_cs => cp3_cs_i
	);

	----------------------------------------------------Chip-level logic modelling----------------------------------------------------
	
	--IC1 is a Fujitsu MB3731 audio power amp - omit
	
	--Sound chip - Yamaha YM2149 (implementation by MikeJ)
	--Implements volume table to simulate mixing of the three analog outputs
	--directly at the chip as per the original Arkanoid PCB
	IC2: ym2149
	port map
	(
		I_DA => z80_Dout,
		O_DA => ym2149_data,
		I_A9_L => '0',
		I_A8 => '1',
		I_BDIR => ym2149_bdir,
		I_BC2 => z80_A(0),
		I_BC1 => ym2149_bc1,
		I_SEL_L => ym2149_clk_div,
		O_AUDIO => sound,
		I_IOA => (others => '0'),
		O_IOA => open,
		I_IOB => dipsw_in,
		O_IOB => open,
		ENA => '1',
		RESET_L => z80_n_reset,
		CLK => clk_3m
	);
	--Latch data from blue color PROM for blue video output
	IC3: ls273
	port map
	(
		d(7 downto 4) => prom3_data,
		d(3 downto 0) => (others => '0'),
		clk => n_clk_6m,
		res => n_blank,
		q(7 downto 4) => video_b
		--q(3 downto 0) unused
	);
	
	--IC4 is a custom Taito PC030CM SIP package for inverting coin inputs and working the
	--coin counter - omit, coin inputs are directly set active high and coin counter is
	--unnecessary
	
	--Lower 4-bit counter for spinner inputs
	IC5: ls669
	port map
	(
		d_in => (others => '0'),
		clk => spin_cnt_clk,
		load => '1',
		n_en_p => spin_cnt_n_en,
		n_en_t => spin_cnt_n_en,
		u_d => spin_cnt_u_d,
		d_out => spin_cnt_l, --Normally routed to MCU, currently unimplemented
		n_rco => spin_cnt_carry
	);
	--Upper 4-bit counter for spinner inputs
	IC6: ls669
	port map
	(
		d_in => (others => '0'),
		clk => spin_cnt_clk,
		load => '1',
		n_en_p => spin_cnt_carry,
		n_en_t => spin_cnt_carry,
		u_d => spin_cnt_u_d,
		d_out => spin_cnt_h --Normally routed to MCU, currently unimplemented
		--n_rco unused
	);
	--Select which spinner inputs to send to counters defined above
	IC7: ls157
	port map
	(
		i0(3 downto 2) => (others => '0'), --Inputs unused, pull low
		i0(1) => n_spinner2(1),
		i0(0) => n_spinner1(0),
		i1(3 downto 2) => (others => '0'), --Inputs unused, pull low
		i1(1) => n_spinner1(1),
		i1(0) => n_spinner2(0),
		n_e => '0',
		s => spinner_sel,
		--z(3 downto 2) unused
		z(1) => spin_cnt_u_d,
		z(0) => spin_cnt_clk
	);
	--Invert spinner inputs (also inverts reset line twice - redundant but kept to match the PCB)
	IC8: cmos_4584
	port map
	(
		in1 => spinner(0),
		in2 => reset,
		in3 => spinner(1),
		in4 => n_reset,
		in5 => spinner(1),
		in6 => spinner(0),
		out1 => n_spinner1(0),
		out2 => n_reset,
		out3 => n_spinner1(1),
		out4 => reset2,
		out5 => n_spinner2(1),
		out6 => n_spinner2(0)
	);
	--Multiplex button inputs
	IC9: ls257
	port map
	(
		a => (others => '1'), --Unused inputs from edge connector, pull high
		b(0) => coin1, --Normally inverted with PC030 custom module, directly set as active high
		b(1) => coin2, --Normally inverted with PC030 custom module, directly set as active high
		b(2) => '1', --Signal should be stat0 for MCU
		b(3) => '0', --Signal should be stat1 for MCU
		out_ctl => '0', --Directly modelled, keep permanently enabled
		sel => z80_A(2),
		y => buttons2(7 downto 4)
	);
	--Multiplex button inputs
	IC10: ls257
	port map
	(
		a => (others => '1'), --Unused inputs from edge connector, pull high
		b(0) => btn_1p_start,
		b(1) => btn_2p_start,
		b(2) => btn_service,
		b(3) => tilt,
		out_ctl => '0', --Directly modelled, keep permanently enabled
		sel => z80_A(2),
		y => buttons2(3 downto 0)
	);
	
	--IC11 is a 7407 buffer for composite sync and Z80 CLK - redundant in this implementaiton,
	--omit
	
	--Main CPU - Zilog Z80 (uses T80s variant of the T80 soft core)
	--NMI, BUSRQ unused, pull high
	IC12: T80s
	port map
	(
		RESET_n => z80_n_reset,
		CLK => n_clk_6m,
		CEN => '1',
		WAIT_n => z80_n_wait,
		INT_n => z80_n_int,
		NMI_n => '1',
		BUSRQ_n => '1',
		MREQ_n => z80_n_mreq,
		IORQ_n => z80_n_iorq,
		RD_n => z80_n_rd,
		WR_n => z80_n_wr,
		--M1_n, RFSH_n, HALT_n, BUSAK_n unused
		A => z80_A,
		DI => z80_Din,
		DO => z80_Dout
	);
	--Latch data from green and red color PROMs for green and red video outputs
	IC13: ls273
	port map
	(
		d(7 downto 4) => prom1_data,
		d(3) => prom2_data(0),
		d(2) => prom2_data(1),
		d(1) => prom2_data(2),
		d(0) => prom2_data(3),
		clk => n_clk_6m,
		res => n_blank,
		q(7 downto 4) => video_r,
		q(3) => video_g(0),
		q(2) => video_g(1),
		q(1) => video_g(2),
		q(0) => video_g(3)
	);
	
	--IC14 is an MC68705 microcontroller - currently unimplemented
	
	--Z80 work RAM
	IC15: entity work.spram
	generic map
	(
		DATA_WIDTH => 8,
		ADDR_WIDTH => 11
	)
	port map
	(
		clk => n_clk_6m,
		we => not z80_n_wr and not z80_ram_n_ce,
		addr => z80_A(10 downto 0),
		data => z80_Dout,
		q => z80_ram_D
	);
	--Secondary game ROM
	IC16: eprom_2
	port map
	(
		addr => eprom2_a15 & z80_A(13 downto 0),
		clk => n_clk_6m,
		data => eprom2_D,
		addr_dl => ioctl_addr,
		clk_dl => clk_12m,
		data_in => ioctl_data,
		cs_dl => ep2_cs_i,
		WR => ioctl_wr
	);
	--Primary game ROM
	IC17: eprom_1
	port map
	(
		addr => z80_A(14 downto 0),
		clk => n_clk_6m,
		data => eprom1_D,
		addr_dl => ioctl_addr,
		clk_dl => clk_12m,
		data_in => ioctl_data,
		cs_dl => ep1_cs_i,
		wr => ioctl_wr
	);
	
	--IC18 is a TL7700 reset IC - unnecessary for this implementation, omit
	
	--Generate the following signals:
	--Sprite RAM read enable/address A8, Z80 reset, input for HSync circuit
	IC19: ls08
	port map
	(
		a1 => h256,
		a2 => n_h256,
		a3 => watchdog,
		a4 => h_cnt(4),
		b1 => n_clk_6m,
		b2 => n_dot123,
		b3 => reset2,
		b4 => n_hcnt5,
		y1 => spr_ram_rd,
		y2 => spr_ram_A(8),
		y3 => z80_n_reset,
		y4 => hs_in
	);
	--Invert the following signals:
	--Horizontal counter bit 5, sprite RAM read enable, YM2149 BC1 and BDIR,
	--watchdog output, watchdog clear
	IC20: ls04
	port map
	(
		a1 => h_cnt(5),
		a2 => spr_ram_rd,
		a3 => n_ym2149_bc1,
		a4 => n_watchdog,
		a5 => n_ym2149_bdir,
		a6 => n_watchdog_clr,
		y1 => n_hcnt5,
		y2 => spr_ram_n_rd,
		y3 => ym2149_bc1,
		y4 => watchdog,
		y5 => ym2149_bdir,
		y6 => watchdog_clr
	);
	--Watchdog
	IC21: ls393
	port map
	(
		clk1 => n_vblank,
		clr1 => watchdog_clr,
		q1(3) => watchdog_clk,
		--q1(2 downto 0) unused
		clk2 => watchdog_clk,
		clr2 => watchdog_clr,
		q2(3) => n_watchdog
		--q2(2 downto 0) unused
	);
	--Blue color PROM
	IC22: color_prom_3
	port map
	(
		addr => prom_addr,
		clk => clk_24m,
		data => prom3_data,
		addr_dl => ioctl_addr,
		clk_dl => clk_12m,
		data_in => ioctl_data,
		cs_dl => cp3_cs_i,
		wr => ioctl_wr
	);
	--Green color PROM
	IC23: color_prom_2
	port map
	(
		addr => prom_addr,
		clk => clk_24m,
		data => prom2_data,
		addr_dl => ioctl_addr,
		clk_dl => clk_12m,
		data_in => ioctl_data,
		cs_dl => cp2_cs_i,
		wr => ioctl_wr
	);
	--Red color PROM
	IC24: color_prom_1
	port map
	(
		addr => prom_addr,
		clk => clk_24m,
		data => prom1_data,
		addr_dl => ioctl_addr,
		clk_dl => clk_12m,
		data_in => ioctl_data,
		cs_dl => cp1_cs_i,
		wr => ioctl_wr
	);
	--Address decoding based on Z80 address lines A3 and A4, active-high Z80 read, Z80 !WR
	--and Z80 A12 high (generated by 74LS139)
	IC25: ls155
	port map
	(
		a0 => z80_A(3),
		a1 => z80_A(4),
		n_ea(0) => z80_rd,
		n_ea(1) => a_0x1000,
		n_eb(0) => a_0x1000,
		n_eb(1) => z80_n_wr,
		o0(3) => spinner_n_en,
		o0(2) => buttons1_n_en,
		o0(1) => buttons2_n_en,
		o0(0) => n_ym2149_bc1,
		o1(3) => mcu_data_clk,
		o1(2) => n_watchdog_clr,
		o1(1) => z80_D_latch_clk,
		o1(0) => n_ym2149_bdir
	);
	
	--The 74LS74 at IC26 is not present on bootlegs without an MCU - omit for now
	
	--Latch spinner counter values to the Z80 (permanently enabled as data input to Z80
	--is directly modelled) - this is normally done through the MCU, though bootlegs
	--directly latch the spinner counters to the Z80 as a workaround
	IC27: ls374
	port map
	(
		d => spin_cnt_h & spin_cnt_l,
		clk => clk_3m,
		out_ctl => '0', --Directly modelled, keep permanently enabled
		q(7 downto 4) => spinner_data(7 downto 4),
		q(3) => spinner_data(0),
		q(2) => spinner_data(1),
		q(1) => spinner_data(2),
		q(0) => spinner_data(3)
	);
	
	--The 74LS374 at IC28 is unnecessary on bootlegs without an MCU, omit for now
	
	--Generate the following signals:
	--HBlank, Z80 EPROM 2 chip enable, load input for sprite RAM counter
	--Gate 1 unused, pull inputs low
	IC29: ls32
	port map
	(
		a1 => '0',
		a2 => hblk_0,
		a3 => n_z80_A15,
		a4 => tilerom_shift_ld,
		b1 => '0',
		b2 => hblk_1,
		b3 => z80_A(14),
		b4	=> h_active,
		y1 => open,
		y2 => n_hblank,
		y3 => eprom2_n_ce,
		y4 => spr_ram_cnt_load
	);
	--Invert the following signals:
	--Z80 address line A0, Z80 !RD, Z80 address line A15, bit 1 of horizontal counter
	--(chip enable for tile ROMs)
	--Inverters 3 and 5 unused, pull inputs low
	IC30: ls04
	port map
	(
		a1 => z80_A(0),
		y1 => n_z80_A0,
		a2 => z80_n_rd,
		y2 => z80_rd,
		a3 => '0',
		--y3 unused
		a4 => z80_A(15),
		y4 => n_z80_A15,
		a5 => '0',
		--y5 unused
		a6 => h_cnt(1),
		y6 => tilerom_n_ce
	);
	--Generate the following signals:
	--Second part of HBlank, Z80 !INT input
	IC31: ls74
	port map
	(
		n_pre1 => '1',
		n_clr1 => '1',
		clk1 => clk_6m,
		d1 => hblk_0,
		q1 => hblk_1,
		--n_q1 unused
		n_pre2 => '1',
		n_clr2 => z80_n_iorq,
		clk2 => n_vblank,
		d2	=> '1',
		--q2 unused
		n_q2 => z80_n_int
	);
	--Latch Z80 data bus
	IC32: ls273
	port map
	(
		d(7) => z80_Dout(1),
		d(6) => z80_Dout(0),
		d(5) => z80_Dout(2),
		d(4) => z80_Dout(3),
		d(3 downto 0) => z80_Dout(7 downto 4),
		clk => z80_D_latch_clk,
		res => z80_n_reset,
		q(7) => z80_D1_latched,
		q(6) => h_inv,
		q(5) => spinner_sel,
		q(4) => open, --Signal output for PC030CM, unused here
		q(3) => open, --Signal for MCU, not implemented yet
		q(2) => prom_addr(8),
		q(1) => tilerom_A(14),
		q(0) => eprom2_a15
	);
	--Send Z80 addresses A0 inverted (determine which 8-bit VRAM chip sends its data to
	--the Z80), A9 - A11 to VRAM address lines when 3MHz clock is low, else Z
	--Second buffer sends shot button input when button inputs are read into the Z80
	IC33: ls244
	port map
	(
		n_g1 => '0', --Directly modelled, keep permanently enabled
		a1(3 downto 2) => z80_A(10 downto 9),
		a1(1) => z80_A(11),
		a1(0) => n_z80_A0,
		y1(3 downto 2) => vram_Z80_A(9 downto 8),
		y1(1) => vram_Z80_A(10),
		y1(0) => z80_n_A0,
		n_g2 => '0', --Directly modelled, keep permanently enabled
		a2(3) => '1', --Unused input on edge connector, pull high
		a2(2) => btn_shot,
		a2(1) => btn_shot,
		a2(0) => '1', --Unused input on edge connector, pull high
		y2(3 downto 2) => buttons1(1 downto 0),
		y2(1) => buttons1(2),
		y2(0) => buttons1(3)
	);
	--Write data into sprite RAM
	IC34: ls244
	port map
	(
		n_g1 => spr_ram_rd,
		a1(3) => bg(3),
		a1(2) => dot3,
		a1(1) => dot1,
		a1(0) => bg(4),
		y1(3) => spr_ram_Din(6),
		y1(2) => spr_ram_Din(1),
		y1(1) => spr_ram_Din(0),
		y1(0) => spr_ram_Din(3),
		n_g2 => spr_ram_rd,
		a2(3) => bg(0),
		a2(2) => bg(1),
		a2(1) => bg(2),
		a2(0) => dot2,
		y2(3) => spr_ram_Din(7),
		y2(2) => spr_ram_Din(4),
		y2(1) => spr_ram_Din(5),
		y2(0) => spr_ram_Din(2)
	);
	--Latch background data
	IC35: ls174
	port map
	(
		d(5) => vram_D(11),
		d(4) => '0',
		d(3 downto 1) => vram_D(14 downto 12),
		d(0) => vram_D(15),
		clk => tilerom_n_ce,
		mr => '1',
		q(5) => bg(4),
		q(3 downto 0) => bg(3 downto 0)
	);
	--Latch horizontal position data from VRAM
	IC36: ls374
	port map
	(
		d(7) => vram_D(8),
		d(6) => vram_D(15),
		d(5) => vram_D(10),
		d(4) => vram_D(13),
		d(3) => vram_D(14),
		d(2 downto 1) => vram_D(12 downto 11),
		d(0) => vram_D(9),
		clk => h_cnt(1),
		out_ctl => '0',
		q => h_pos
	);
	--Latch object data from sprite RAM
	IC37: ls374
	port map
	(
		d(7) => spr_ram_Dout(3),
		d(6) => spr_ram_Dout(0),
		d(5) => spr_ram_Dout(1),
		d(4) => spr_ram_Dout(6),
		d(3) => spr_ram_Dout(2),
		d(2 downto 1) => spr_ram_Dout(5 downto 4),
		d(0) => spr_ram_Dout(7),
		clk => clk_6m,
		out_ctl => '0',
		q => obj
	);
	--Multiplex objects and backgrounds to color PROM addresses (A0 - A3)
	IC38: ls298
	port map
	(
		i0(3) => obj(7),
		i0(2) => obj(3),
		i0(1) => obj(5),
		i0(0) => obj(6),
		i1(3) => scr(5),
		i1(2) => scr(6),
		i1(1) => scr(4),
		i1(0) => scr(7),
		clk => clk_6m,
		s => prom_addr_sel,
		q => prom_addr(3 downto 0)
	);
	--Multiplex objects and backgrounds to color PROM addresses (A4 - A7)
	IC39: ls298
	port map
	(
		i0(3) => obj(0),
		i0(2) => obj(4),
		i0(1) => obj(2),
		i0(0) => obj(1),
		i1(3) => scr(2),
		i1(2) => scr(1),
		i1(1) => scr(3),
		i1(0) => scr(0),
		clk => clk_6m,
		s => prom_addr_sel,
		q => prom_addr(7 downto 4)
	);
	--Latch background layer for sprite RAM
	IC40: ls374
	port map
	(
		d(7) => eprom3_shift,
		d(6) => eprom5_shift,
		d(5) => bg(4),
		d(4) => eprom4_shift,
		d(3) => bg(2),
		d(2) => bg(0),
		d(1) => bg(3),
		d(0) => bg(1),
		clk => clk_6m,
		out_ctl => '0',
		q => scr
	);
	--Buffer Z80 address lines 1 - 8 and send to VRAM address lines 0 to 7 when 3MHz clock is high (Z otherwise)
	IC41: ls244
	port map
	(
		n_g1 => '0', --Directly modelled, keep permanently enabled
		a1 => z80_A(4 downto 1),
		y1(3) => vram_Z80_A(3),
		y1(2) => vram_Z80_A(2),
		y1(1) => vram_Z80_A(1),
		y1(0) => vram_Z80_A(0),
		n_g2 => '0', --Directly modelled, keep permanently enabled
		a2(3) => z80_A(5),
		a2(2) => z80_A(6),
		a2(1) => z80_A(7),
		a2(0) => z80_A(8),
		y2(3) => vram_Z80_A(4),
		y2(2) => vram_Z80_A(5),
		y2(1) => vram_Z80_A(6),
		y2(0) => vram_Z80_A(7)
	);
	
	--IC42 is a 74LS245 used for transferring data between VRAM chips - omitted in favor of direct modeling of the
	--multiplexed VRAM data bus
	
	--Generate the following signals:
	--VRAM H/L chip enable/output enable/write enable (all active low)
	IC43: ls157
	port map
	(
		i0(3) => z80_rd,
		i0(2) => z80_n_rd,
		i0(1) => sccs0,
		i0(0) => n_sccs0,
		i1 => "1000",
		n_e => '0',
		s => clk_3m,
		z(3) => vram_we,
		z(2) => vram_n_oe,
		z(1) => vram_l_n_ce,
		z(0) => vram_h_n_ce
	);
	--Generate the following signals:
	--VRAM read to Z80, sccs, (inverted) sccs0
	IC44: ls32
	port map
	(
		a1 => z80_n_rd,
		b1 => n_sccs,
		y1 => vram_n_rd,
		a2 => n_z80_A0,
		b2 => n_sccs,
		y2 => n_sccs0,
		a3 => z80_A(0),
		b3 => n_sccs,
		y3 => sccs0,
		a4 => a_0x2000,
		b4	=> z80_n_mreq,
		y4 => n_sccs
	);
	--Generate the following signals
	--h256, first part of HBlank
	IC45: ls74
	port map
	(
		n_pre1 => '1',
		n_clr1 => '1',
		clk1 => h_cnt(2),
		d1 => h_cnt(7),
		q1 => h256,
		n_q1 => n_h256,
		n_pre2 => '1',
		n_clr2 => '1',
		clk2 => clk_3m,
		d2	=> h256,
		q2 => hblk_0
		--n_q2 unused
	);
	--Generate the following signals
	--Combined blank, active frame
	--Gates 1 and 3 unused, pull inputs low
	IC46: ls08
	port map
	(
		a1 => '0',
		b1 => '0',
		--y1 unused
		a2 => n_vblank,
		b2 => n_hblank,
		y2 => n_blank,
		a3 => '0',
		b3 => '0',
		--y3 unused
		a4 => h_cnt(7),
		b4 => h256,
		y4 => h_active
	);
	--Multiplex data from VRAM to be used as addresses for the tile ROMs (A0 - A3)
	IC47: ls298
	port map
	(
		i0 => sr(3 downto 0),
		i1(3) => vram_D(0),
		i1(2) => vcnt1_xor,
		i1(1) => vcnt0_xor,
		i1(0) => vcnt_en_xor,
		clk => clk_3m,
		s => h_cnt(7),
		q => tilerom_A(3 downto 0)
	);
	--Multiplex data from VRAM to be used as addresses for the tile ROMs (A4 - A7)
	IC48: ls298
	port map
	(
		i0 => vram_D(3 downto 0),
		i1 => vram_D(4 downto 1),
		clk => clk_3m,
		s => h_cnt(7),
		q => tilerom_A(7 downto 4)
	);
	--Multiplex data from VRAM to be used as addresses for the tile ROMs (A8 - A11)
	IC49: ls298
	port map
	(
		i0 => vram_D(7 downto 4),
		i1 => vram_D(8 downto 5),
		clk => clk_3m,
		s => h_cnt(7),
		q => tilerom_A(11 downto 8)
	);
	--Multiplex data from VRAM to be used as addresses for the tile ROMs (A12 & A13)
	--Also pass through INRE
	IC50: ls298
	port map
	(
		i0(3) => '0',
		i0(2) => inre,
		i0(1 downto 0) => vram_D(9 downto 8),
		i1(3 downto 2) => "01",
		i1(1 downto 0) => vram_D(10 downto 9),
		clk => clk_3m,
		s => h_cnt(7),
		--q(3) unused
		q(2) => n_inre,
		q(1 downto 0) => tilerom_A(13 downto 12)
	);
	--Sprite RAM
	IC51: entity work.spram_en
	generic map
	(
		DATA_WIDTH => 8,
		ADDR_WIDTH => 11
	)
	port map
	(
		clk => clk_12m,
		we => not n_clk_6m,
		re => not spr_ram_n_rd,
		addr(10 downto 9) => "00",
		addr(8 downto 0) => spr_ram_A,
		data => spr_ram_Din,
		q => spr_ram_Dout
	);
	--Generate sprite RAM addresses (A0 - A3)
	IC52: ls669
	port map
	(
		d_in(3) => h_pos_mux(2),
		d_in(2) => h_pos_mux(3),
		d_in(1 downto 0) => h_pos_mux(1 downto 0),
		clk => n_clk_6m,
		load => spr_ram_cnt_load,
		n_en_p => '0',
		n_en_t => '0',
		u_d => spr_ram_u_d,
		d_out => spr_ram_A(3 downto 0),
		n_rco => spr_ram_cnt_carry
	);
	--Multiplex horizontal position
	IC53: ls157
	port map
	(
		i0(3) => h_pos(5),
		i0(2) => h_pos(1),
		i0(1) => h_pos(0),
		i0(0) => h_pos(7),
		i1(3) => h_inv,
		i1(2) => h_inv,
		i1(1) => h_inv,
		i1(0) => h_inv,
		n_e => '0',
		s => h_cnt(7),
		z => h_pos_mux(3 downto 0)
	);
	--Generate the following signals:
	--NOR of dot signals, enable for spinner counters, select line for sprite/background addresses
	--to sprite RAM
	IC54: ls27
	port map
	(
		a1 => dot2,
		b1 => dot1,
		c1 => dot3,
		y1 => n_dot123,
		a2 => z80_A(2),
		b2 => buttons2_n_en,
		c2 => '0',
		y2 => spin_cnt_n_en,
		a3 => obj(6),
		b3 => obj(5),
		c3 => obj(3),
		y3 => prom_addr_sel
	);
	
	--IC55 is a 74LS373 used to send data from VRAM to the Z80 - omitted in favor of a direct connection
	--IC56 is a 74LS244 that sends data from the Z80 to VRAM - omitted in favor of a direct connection
	
	--Multiplex VRAM address lines based on 3MHz clock logic level
	vram_A <= vram_Z80_A when not clk_3m
			else vram_mux_A;
	
	--VRAM (upper 8 bits)
	IC57: entity work.spram
	generic map
	(
		DATA_WIDTH => 8,
		ADDR_WIDTH => 11
	)
	port map
	(
		clk => clk_12m,
		we => not vram_l_n_ce and not vram_n_we,
		addr => vram_A,
		data => z80_Dout,
		q => vram_D(15 downto 8)
	);
	--VRAM (lower 8 bits)
	IC58: entity work.spram
	generic map
	(
		DATA_WIDTH => 8,
		ADDR_WIDTH => 11
	)
	port map
	(
		clk => clk_12m,
		we => not vram_h_n_ce and not vram_n_we,
		addr => vram_A,
		data => z80_Dout,
		q => vram_D(7 downto 0)
	);
	--Latch background data from VRAM based on bit 1 of the horizontal counter
	IC59: ls374
	port map
	(
		d(7) => vram_D(6),
		d(6 downto 5) => vram_D(4 downto 3),
		d(4) => vram_D(1),
		d(3) => vram_D(2),
		d(2) => vram_D(0),
		d(1) => vram_D(7),
		d(0) => vram_D(5),
		clk => h_cnt(1),
		out_ctl => '0',
		q => bg_data
	);
	--Sum background and sprite graphics (upper 8 bits)
	IC60: ls283
	port map
	(
		a(3) => bg_data(1),
		a(2) => bg_data(7),
		a(1) => bg_data(0),
		a(0) => bg_data(6),
		b(3) => vcnt6_xor,
		b(2) => vcnt5_xor,
		b(1) => vcnt4_xor,
		b(0) => vcnt3_xor,
		c_in => sr_carry,
		sum => sr(7 downto 4)
		--c_out unused
	);
	--Sum background and sprite graphics (lower 4 bits)
	IC61: ls283
	port map
	(
		a(3) => bg_data(5),
		a(2) => bg_data(3),
		a(1) => bg_data(4),
		a(0) => bg_data(2),
		b(3) => vcnt2_xor,
		b(2) => vcnt1_xor,
		b(1) => vcnt0_xor,
		b(0) => vcnt_en_xor,
		c_in => '0',
		sum => sr(3 downto 0),
		c_out => sr_carry
	);
	--Tile ROMs
	IC62: eprom_5
	port map
	(
		addr => tilerom_A,
		clk => clk_12m,
		ena => tilerom_n_ce,
		data => eprom5_D,
		addr_dl => ioctl_addr,
		clk_dl => clk_12m,
		data_in => ioctl_data,
		cs_dl => ep5_cs_i,
		wr => ioctl_wr
	);
	IC63: eprom_4
	port map
	(
		addr => tilerom_A,
		clk => clk_12m,
		ena => tilerom_n_ce,
		data => eprom4_D,
		addr_dl => ioctl_addr,
		clk_dl => clk_12m,
		data_in => ioctl_data,
		cs_dl => ep4_cs_i,
		wr => ioctl_wr
	);
	IC64: eprom_3
	port map
	(
		addr => tilerom_A,
		clk => clk_12m,
		ena => tilerom_n_ce,
		data => eprom3_D,
		addr_dl => ioctl_addr,
		clk_dl => clk_12m,
		data_in => ioctl_data,
		cs_dl => ep3_cs_i,
		wr => ioctl_wr
	);
	--Generate sprite RAM addresses (A4 - A7)
	IC65: ls669
	port map
	(
		d_in(3) => h_pos_mux(6),
		d_in(2) => h_pos_mux(7),
		d_in(1 downto 0) => h_pos_mux(5 downto 4),
		clk => n_clk_6m,
		load => spr_ram_cnt_load,
		n_en_p => spr_ram_cnt_carry,
		n_en_t => spr_ram_cnt_carry,
		u_d => spr_ram_u_d,
		d_out => spr_ram_A(7 downto 4)
		--n_rco unused
	);
	--Horizontal position of sprites
	IC66: ls157
	port map
	(
		i0(3) => h_pos(3),
		i0(2) => h_pos(6),
		i0(1) => h_pos(4),
		i0(0) => h_pos(2),
		i1(3) => h_inv,
		i1(2) => h_inv,
		i1(1) => h_inv,
		i1(0) => h_inv,
		n_e => '0',
		s => h_cnt(7),
		z => h_pos_mux(7 downto 4)
	);
	--Horizontal counter (upper 4 bits)
	IC67: ls161
	port map
	(
		n_clr => '1',
		clk => n_clk_6m,
		din => "0100",
		enp => h_cnt_cascade,
		ent => h_cnt_cascade,
		n_load => h_cnt_upper_n_ld,
		q => h_cnt(7 downto 4),
		rco => h_cnt_carry
	);
	--Horizontal counter (lower 4 bits)
	IC68: ls161
	port map
	(
		n_clr => '1',
		clk => n_clk_6m,
		din => (others => '0'),
		enp => clk_3m,
		ent => clk_3m,
		n_load => '1',
		q => h_cnt(3 downto 0),
		rco => h_cnt_cascade
	);
	--NAND gate for tile ROM shift registers (generates shift/load input)
	IC69: ls20
	port map
	(
		a1 => '1',
		b1 => h_cnt(0),
		c1 => h_cnt(1),
		d1 => clk_3m,
		y1 => tilerom_shift_ld,
		a2 => '0',
		b2 => '0',
		c2 => '0',
		d2 => '0'
		--y2 unused
	);
	--Multiplex background and sprite tile addresses for VRAM (A0 - A3)
	IC70: ls257
	port map
	(
		a => h_cnt(4 downto 1),
		b(3) => hcnt5_xor,
		b(2) => hcnt4_xor,
		b(1) => hcnt3_xor,
		b(0) => hcnt2_xor,
		out_ctl => '0', --Directly modelled, keep permanently enabled
		sel => h_cnt(7),
		y => vram_mux_A(3 downto 0)
	);
	--Multiplex background and sprite tile addresses for VRAM (A4 - A7)
	IC71: ls257
	port map
	(
		a(3 downto 1) => (others => '0'),
		a(0) => h_cnt(5),
		b(3) => vcnt4_xor,
		b(2) => vcnt3_xor,
		b(1) => vcnt2_xor,
		b(0) => hcnt6_xor,
		out_ctl => '0', --Directly modelled, keep permanently enabled
		sel => h_cnt(7),
		y => vram_mux_A(7 downto 4)
	);
	--Multiplex background and sprite tile addresses for VRAM (A8 - A10)
	IC72: ls257
	port map
	(	
		a => "0100",
		b(3 downto 2) => (others => '0'),
		b(1) => vcnt6_xor,
		b(0) => vcnt5_xor,
		out_ctl => '0', --Directly modelled, keep permanently enabled
		sel => h_cnt(7),
		--y(3) unused
		y(2 downto 0) => vram_mux_A(10 downto 8)
	);
	--Vertical counter (lower 4 bits)
	IC73: ls161
	port map
	(
		n_clr => '1',
		clk => v_cnt_clk,
		din => "1100",
		enp => v_cnt_en,
		ent => v_cnt_en,
		n_load => v_cnt_n_ld,
		q => v_cnt(3 downto 0),
		rco => v_cnt_cascade
	);
	--Vertical counter (upper 4 bits)
	IC74: ls161
	port map
	(
		n_clr => '1',
		clk => v_cnt_clk,
		din => "0111",
		enp => v_cnt_cascade,
		ent => v_cnt_cascade,
		n_load => v_cnt_n_ld,
		q => v_cnt(7 downto 4),
		rco => v_cnt_carry
	);
	--Generate the following signals:
	--Input for VBlank flip-flop, INRE
	IC75: ls20
	port map
	(
		a1 => '1',
		b1 => v_cnt(4),
		c1 => v_cnt(5),
		d1 => v_cnt(6),
		y1 => vb_in,
		a2 => sr(7),
		b2 => sr(6),
		c2 => sr(4),
		d2 => sr(5),
		y2 => inre
	);
	--Generate the following signals:
	--Dot clock, (inverted) 6MHz clock
	IC76: ls74
	port map
	(
		n_pre1 => '1',
		n_clr1 => '1',
		clk1 => tilerom_n_ce,
		d1 => n_inre,
		q1 => open,
		n_q1 => n_dot,
		n_pre2 => '1',
		n_clr2 => '1',
		clk2 => clk_12m,
		d2	=> n_clk_6m,
		q2 => clk_6m,
		n_q2 => n_clk_6m
	);
	--Left/right shift data from 3rd tile ROM
	IC77: mb112s146
	port map
	(
		n_clr => '1',
		shift_ld => tilerom_shift_ld,
		sel => flip_sel,
		clk => n_clk_6m,
		s_in => (others => '0'),
		d2_in => (others => '0'), --This shift register is unused, pull inputs low
		d1_in => eprom5_D,
		shift_out(0) => eprom5_shift
	);
	--Left/right shift data from 1st and 2nd tile ROM
	IC78: mb112s146
	port map
	(
		n_clr => '1',
		shift_ld => tilerom_shift_ld,
		sel => flip_sel,
		clk => n_clk_6m,
		s_in => (others => '0'),
		d2_in => eprom3_D,
		d1_in => eprom4_D,
		shift_out(1) => eprom3_shift,
		shift_out(0) => eprom4_shift
	);
	--Generate the following signals:
	--Up/down for counters generating sprite RAM addresses, load input for vertical counter,
	--NAND of Z80 address lines A14 and A15 (output 0 when both are 0)
	--Gate 1 unused, pull inputs low
	IC79: ls00
	port map
	(
		a1 => '0',
		b1 => '0',
		--y1 unused
		a2 => h_inv,
		b2 => h256,
		y2 => spr_ram_u_d,
		a3 => '1',
		b3 => v_cnt_carry,
		y3 => v_cnt_n_ld,
		a4 => z80_A(15),
		b4	=> z80_A(14),
		y4 => n_z80_A14_A15
	);
	--Address decoding based on the following address lines from the Z80:
	--A3, A4, A12 - A15
	IC80: ls139
	port map
	(
		n_e(0) => n_z80_A14_A15,
		a0(0) => z80_A(12),
		a1(0) => z80_A(13),
		o0(0) => z80_ram_n_ce,
		o0(1) => a_0x1000,
		o0(2) => a_0x2000,
		--o0(3) unused
		n_e(1) => a_0x1000,
		a0(1) => z80_A(3),
		a1(1) => z80_A(4),
		o1(0) => a_0x1000_2
		--o1(3 downto 1) unused
	);
	--Generate the following signals:
	--HSync, (inverted) 3MHz clock
	IC81: ls74
	port map
	(
		n_pre1 => '1',
		n_clr1 => v_cnt_clk,
		clk1 => h_cnt(3),
		d1 => hs_in,
		q1 => hsync,
		--n_q1 unused
		n_pre2 => '1',
		n_clr2 => '1',
		clk2 => n_clk_6m,
		d2 => n_clk_3m,
		q2 => clk_3m, --Connect to MCU when implemented
		n_q2 => n_clk_3m
	);
	--Generate the following signals:
	--XOR horizontal counter bits 4 - 6, load for upper 4-bit horizontal counter
	IC82: ls86
	port map
	(
		a1 => h_cnt(5),
		b1 => h_inv,
		y1 => hcnt5_xor,
		a2 => h_cnt(6),
		b2 => h_inv,
		y2 => hcnt6_xor,
		a3 => h_cnt(4),
		b3 => h_inv,
		y3 => hcnt4_xor,
		a4	=> h_cnt_carry,
		b4	=> '1',
		y4 => h_cnt_upper_n_ld
	);
	--Generate the following signals:
	--clock for vertical counter based on most significant bit of horizontal counter,
	--composite sync (unused for MISTer), XOR horizontal counter bits 2 and 3
	IC83: ls86
	port map
	(
		a1 => '1',
		b1 => h_cnt(7),
		y1 => v_cnt_clk,
		a2 => v_cnt(7),
		b2 => hsync,
		y2 => video_csync,
		a3 => h_cnt(2),
		b3 => h_inv,
		y3 => hcnt2_xor,
		a4	=> h_inv,
		b4	=> h_cnt(3),
		y4 => hcnt3_xor
	);
	--Generate the following signals:
	--SCCS for WAIT signal, VRAM write enable (active low) based on inverted 6MHz clock
	--Gates 1 and 2 unused, pull inputs low
	IC84: ls32
	port map
	(
		a1 => '0',
		b1 => '0',
		--y1 unused
		a2 => '0',
		b2 => '0',
		--y2 unused
		a3 => n_sccs,
		b3 => n_clk_3m,
		y3 => n_sccs_wait,
		a4 => vram_we,
		b4	=> n_clk_6m,
		y4 => vram_n_we
	);
	--Generate Z80 !WAIT signal
	--Only gate 3 used, pull all other inputs low
	IC85: ls08
	port map
	(
		a1 => '0',
		b1 => '0',
		--y1 unused
		a2 => '0',
		b2 => '0',
		--y2 unused
		a3 => n_sccs_wait,
		b3 => n_wait,
		y3 => z80_n_wait,
		a4 => '0',
		b4 => '0'
		--y4 unused
	);
	--Generate the following signals:
	--WAIT signal, PRE for WAIT signal
	IC86: ls74
	port map
	(
		n_pre1 => wait_pre,
		n_clr1 => '1',
		clk1 => n_clk_6m,
		d1 => a_0x1000_2,
		q1 => n_wait,
		--n_q1 unused
		n_pre2 => '1',
		n_clr2 => '1',
		clk2 => n_clk_6m,
		d2	=> n_wait,
		q2 => wait_pre
		--n_q2 unused
	);
	--Generate the following signals:
	--Enable for vertical counter (normal and inverted), VBlank
	IC87: ls74
	port map
	(
		n_pre1 => '1',
		n_clr1 => '1',
		clk1 => v_cnt_clk,
		d1 => n_v_cnt_en,
		q1 => v_cnt_en,
		n_q1 => n_v_cnt_en,
		n_pre2 => '1',
		n_clr2 => '1',
		clk2 => v_cnt(3),
		d2	=> vb_in,
		q2 => n_vblank --Connect to MCU when implemented
		--n_q2 unused
	);
	--XOR vertical counter bits 0 - 2 and enable with latched Z80 D1 data line
	IC88: ls86
	port map
	(
		a1 => v_cnt(2),
		b1 => z80_D1_latched,
		y1 => vcnt2_xor,
		a2 => v_cnt_en,
		b2 => z80_D1_latched,
		y2 => vcnt_en_xor,
		a3 => v_cnt(0),
		b3 => z80_D1_latched,
		y3 => vcnt0_xor,
		a4	=> v_cnt(1),
		b4	=> z80_D1_latched,
		y4 => vcnt1_xor
	);
	--XOR vertical counter bits 3 - 6 with latched Z80 D1 data line
	IC89: ls86
	port map
	(
		a1 => v_cnt(3),
		b1 => z80_D1_latched,
		y1 => vcnt3_xor,
		a2 => v_cnt(4),
		b2 => z80_D1_latched,
		y2 => vcnt4_xor,
		a3 => v_cnt(5),
		b3 => z80_D1_latched,
		y3 => vcnt5_xor,
		a4	=> v_cnt(6),
		b4	=> z80_D1_latched,
		y4 => vcnt6_xor
	);
	--Generate the following signals:
	--Select line for screen flipping, dot signals
	IC90: ls08
	port map
	(
		a1 => h_inv,
		b1 => h256,
		y1 => flip_sel,
		a2 => eprom3_shift,
		b2 => n_dot,
		y2 => dot1,
		a3 => eprom5_shift,
		b3 => n_dot,
		y3 => dot2,
		a4 => n_dot,
		b4 => eprom4_shift,
		y4 => dot3
	);
end virt_pcb;