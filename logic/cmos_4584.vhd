--============================================================================
-- 
--  VHDL implementation of the CD4584 hex inverter
--  Copyright (C) 2018, 2019 Ace
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

--Chip pinout:
/*      _____________
      _|             |_
in1  |_|1          14|_| VCC
      _|             |_                     
out1 |_|2          13|_| in6
      _|             |_
in2  |_|3          12|_| out6
      _|             |_
out2 |_|4          11|_| in5
      _|             |_
in3  |_|5          10|_| out5
      _|             |_
out3 |_|6           9|_| in4
      _|             |_
GND  |_|7           8|_| out4
       |_____________|
*/

library IEEE;
use IEEE.std_logic_1164.all;

entity cmos_4584 is
port
(
	in1, in2, in3, in4, in5, in6		: in std_logic;
	out1, out2, out3, out4, out5, out6	: out std_logic
);
end cmos_4584;

architecture arch of cmos_4584 is
begin
	out1 <= not in1;
	out2 <= not in2;
	out3 <= not in3;
	out4 <= not in4;
	out5 <= not in5;
	out6 <= not in6;
end arch;