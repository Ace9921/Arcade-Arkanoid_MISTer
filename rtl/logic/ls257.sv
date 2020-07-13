//============================================================================
// 
//  SystemVerilog implementation of the 74LS257 quad 2-to-1 multiplexer with
//  tristate outputs
//  Copyright (C) 2019 Ace
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

//Chip pinout:
/*      _____________
      _|             |_
sel  |_|1          16|_| VCC
      _|             |_                     
a(0) |_|2          15|_| out_ctl
      _|             |_
b(0) |_|3          14|_| a(2)
      _|             |_
y(0) |_|4          13|_| b(2)
      _|             |_
a(1) |_|5          12|_| y(2)
      _|             |_
b(1) |_|6          11|_| a(3)
      _|             |_
y(1) |_|7          10|_| b(3)
      _|             |_
GND  |_|8           9|_| y(3)
       |_____________|
*/

module ls257
(
	input  [3:0] a,
	input  [3:0] b,
	input        out_ctl,
	input        sel,
	output [3:0] y
);

assign y = (!out_ctl && !sel) ? a:
	(!out_ctl && sel)     ? b:
	4'hF; //Should be Z when out_ctl is high
		
endmodule
