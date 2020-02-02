//============================================================================
// 
//  SystemVerilog implementation of the 74LS20 dual 4-input NAND gate
//  Copyright (C) 2019 Ace
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

//Chip pinout:
/*     _____________
     _|             |_
a1  |_|1          14|_| VCC
     _|             |_                     
b1  |_|2          13|_| d2
     _|             |_
NC  |_|3          12|_| c2
     _|             |_
c1  |_|4          11|_| NC
     _|             |_
d1  |_|5          10|_| b2
     _|             |_
y1  |_|6           9|_| a2
     _|             |_
GND |_|7           8|_| y2
      |_____________|
*/

module ls20
(
	input a1, b1, c1, d1,
	input a2, b2, c2, d2,
	output y1, y2
);

assign y1 = ~(a1 & b1 & c1 & d1);
assign y2 = ~(a2 & b2 & c2 & d2);
	
endmodule
