//============================================================================
// 
//  SystemVerilog implementation of the 74LS155 dual 2-to-4 address decoder
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
/*         _____________
         _|             |_
n_ea(0) |_|1          16|_| VCC
         _|             |_                     
n_ea(1) |_|2          15|_| n_eb(0)
         _|             |_
a1      |_|3          14|_| n_eb(1)
         _|             |_
o0(3)   |_|4          13|_| a0
         _|             |_
o0(2)   |_|5          12|_| o1(3)
         _|             |_
o0(1)   |_|6          11|_| o1(2)
         _|             |_
o0(0)   |_|7          10|_| o1(1)
         _|             |_
GND     |_|8           9|_| o1(0)
          |_____________|
*/

module ls155
(
	input        a0, a1,
	input  [1:0] n_ea,	//n_ea[0] active high, n_ea[1] active low
	input  [1:0] n_eb,
	output [3:0] o0,
	output [3:0] o1
);

assign o0 = (n_ea[0] && !n_ea[1] && !a0 && !a1) ? 4'b1110:
	(n_ea[0] && !n_ea[1] && a0 && !a1)  ? 4'b1101:
	(n_ea[0] && !n_ea[1] && !a0 && a1)  ? 4'b1011:
	(n_ea[0] && !n_ea[1] && a0 && a1)   ? 4'b0111:
	4'b1111;
assign o1 = (!n_eb[0] && !n_eb[1] && !a0 && !a1) ? 4'b1110:
	(!n_eb[0] && !n_eb[1] && a0 && !a1)  ? 4'b1101:
	(!n_eb[0] && !n_eb[1] && !a0 && a1)  ? 4'b1011:
	(!n_eb[0] && !n_eb[1] && a0 && a1)   ? 4'b0111:
	4'b1111;

endmodule
