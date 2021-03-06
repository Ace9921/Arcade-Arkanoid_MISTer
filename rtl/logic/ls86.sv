//============================================================================
// 
//  SystemVerilog implementation of the 74LS86 quad XOR gate
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
/*     _____________
     _|             |_
a1  |_|1          14|_| VCC
     _|             |_                     
b1  |_|2          13|_| a4
     _|             |_
y1  |_|3          12|_| b4
     _|             |_
a2  |_|4          11|_| y4
     _|             |_
b2  |_|5          10|_| a3
     _|             |_
y2  |_|6           9|_| b3
     _|             |_
GND |_|7           8|_| y3
      |_____________|
*/

module ls86
(
	input  a1, a2, a3, a4,
	input  b1, b2, b3, b4,
	output y1, y2, y3, y4
);

assign y1 = a1 ^ b1;
assign y2 = a2 ^ b2;
assign y3 = a3 ^ b3;
assign y4 = a4 ^ b4;
	
endmodule
