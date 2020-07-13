//============================================================================
// 
//  SystemVerilog implementation of the 74LS669 synchronous 4-bit up/down
//  counter
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
u_d     |_|1          16|_| VCC
         _|             |_                     
clk     |_|2          15|_| n_rco
         _|             |_
d_in(0) |_|3          14|_| d_out(0)
         _|             |_
d_in(1) |_|4          13|_| d_out(1)
         _|             |_
d_in(2) |_|5          12|_| d_out(2)
         _|             |_
d_in(3) |_|6          11|_| d_out(3)
         _|             |_
n_en_p  |_|7          10|_| n_en_t
         _|             |_
GND     |_|8           9|_| load
          |_____________|
*/

module ls669
(
	input  [3:0] d_in,
	input        clk,
	input        load,
	input        n_en_p,
	input        n_en_t,
	input        u_d,
	output [3:0] d_out,
	output       n_rco
);

reg [3:0] count;

always_ff @(posedge clk) begin
	if(!load)
		count <= d_in;
	else
		if(!n_en_p && !n_en_t)
			count <= u_d ? (count + 4'd1) : (count - 4'd1);
end

assign d_out = count;
assign n_rco = ~((~n_en_t & u_d & count[0] & count[1] & count[2] & count[3]) | (~n_en_t & ~u_d & ~count[0] & ~count[1] & ~count[2] & ~count[3]));

endmodule
