//============================================================================
// 
//  SystemVerilog implementation of the CD4584 hex inverter
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

module cmos_4584
(
	input  in1, in2, in3, in4, in5, in6,
	output out1, out2, out3, out4, out5, out6
);

assign out1 = ~in1;
assign out2 = ~in2;
assign out3 = ~in3;
assign out4 = ~in4;
assign out5 = ~in5;
assign out6 = ~in6;
	
endmodule
