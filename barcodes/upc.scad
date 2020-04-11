/*****************************************************************************
 * UPC-A Symbol Library
 * Generates UPC-A Barcodes
 *****************************************************************************
 * Copyright 2017 Chris Baker
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *****************************************************************************
 * Usage:
 * Include this file with the "use" tag.
 * Depends on bitmap.scad library.
 *
 * API:
 *   UPC_A(string, bar, space, quiet_zone, vector_mode, font, fontsize)
 *     Generates the UPC-A barcode representing string.
 *     The bar, space, and quiet_zone parameters can be used to change the
 *     appearance of the barcode. See the bitmap library for more details.
 *     The vector_mode determines whether to create 2D vector artwork instead
 *     of 3D solid geometry. See notes/caveats in the bitmap library.
 *     The font and fontsize control the font used for drawing the text digits
 *     below each symbol.
 *
 * TODO:
 *   Add EAN-13 support
 *****************************************************************************/
use <../util/compat.scad>
use <../util/bitmap.scad>

/*
 * symbol definitions arranged in a convenient array
 * 1 indicates bar
 * 0 indicates space
 *
 * symbols:
 * 00-09 - numeric digits (odd parity)
 * 10 - quiet zone
 * 11 - start/end marker
 * 12 - middle marker
 */
symbol_vector = [
	[0,0,0,1,1,0,1], // 00 - 0
	[0,0,1,1,0,0,1], // 01 - 1
	[0,0,1,0,0,1,1], // 02 - 2
	[0,1,1,1,1,0,1], // 03 - 3
	[0,1,0,0,0,1,1], // 04 - 4
	[0,1,1,0,0,0,1], // 05 - 5
	[0,1,0,1,1,1,1], // 06 - 6
	[0,1,1,1,0,1,1], // 07 - 7
	[0,1,1,0,1,1,1], // 08 - 8
	[0,0,0,1,0,1,1], // 09 - 9
	[0,0,0,0,0,0,0,0,0], // 10 - quiet zone
	[1,0,1],             // 11 - start/end marker
	[0,1,0,1,0],         // 12 - middle marker
];

/*
 * upc_symbol_len - return length of a given symbol
 *
 * symbol - integer 00-22
 *   00-09 - numeric digits (odd parity)
 *   10 - quiet zone
 *   11 - start/end symbol
 *   12 - middle symbol
 */
function upc_symbol_len(symbol) =
	len(symbol_vector[symbol]);

/*
 * upc_symbol - render a single symbol
 *
 * symbol - integer 00-22
 *   00-09 - numeric digits (odd parity)
 *   10 - quiet zone
 *   11 - start/end symbol
 *   12 - middle symbol
 * 
 * bar - bar representation
 * space - space representation
 * quiet_zone - representation for quiet zone
 * (see documentation in bitmap.scad)
 *
 * vector_mode - create a 2D vector drawing instead of 3D extrusion
 * parity - false for even, true for odd
 * reverse - true to mirror the symbol (EAN use)
 */
module upc_symbol(symbol, bar=1, space=0, quiet_zone=0,
	vector_mode=false,
	parity=true, reverse=false)
{
	B=parity?bar:space;
	S=parity?space:bar;

	vector = [
		for (i=[0:1:upc_symbol_len(symbol)-1])
			let (index=reverse?upc_symbol_len(symbol)-i-1:i)
				(symbol==10)?quiet_zone:
				(symbol_vector[symbol][index])?B:S
	];

	1dbitmap(vector, vector_mode=vector_mode);
}

/*
 * UPC_A - Generate a UPC-A barcode
 *
 * string - UPC digit string to encode
 *   string of digits (only) of length 12
 * 
 * bar - bar representation
 * space - space representation
 * quiet_zone - representation for quiet zone
 * (see documentation in bitmap.scad)
 *
 * vector_mode - create a 2D vector drawing instead of 3D extrusion
 * font - font to use for decimal digits below each symbol
 *   set to undef if you do not want any text
 * fontsize - font size to use
 */
module UPC_A(string, bar=1, space=0, quiet_zone=0,
	vector_mode=false,
	font="Liberation Mono:style=Bold", fontsize=1.5)
{

	if ((len(string)!=11)&&(len(string)!=12))
		echo("WARNING: UPC string must be exactly 11 or 12 digits");

	//translates the numeral 'digit' from
	//character to integer form
	function translate_symbol(digit) =
		(digit=="0")?0:
		(digit=="1")?1:
		(digit=="2")?2:
		(digit=="3")?3:
		(digit=="4")?4:
		(digit=="5")?5:
		(digit=="6")?6:
		(digit=="7")?7:
		(digit=="8")?8:
		(digit=="9")?9: undef;

	//calculates the checkdigit by recursively
	//parsing the 11-numeral string provided
	//i is incremented from 0 to 10
	//i has a special default value of -1 to
	//conduct some final processing on the answer
	function calculate_checkdigit(string, i=-1) =
		(i==10)?
			translate_symbol(string[i])*3:
		(i==-1)?
			(0==calculate_checkdigit(string,i=0)%10)?
				0:(10-calculate_checkdigit(string,i=0)%10)
		:
			((i%2)?1:3)*translate_symbol(string[i])
				+calculate_checkdigit(string, i+1);

	//returns the symbol to draw at position i
	//i ranges from 0 to 16
	function get_symbol(string, i) =
		(i==0)?10:
		(i==1)?11:
		(i<8)?translate_symbol(string[i-2]):
		(i==8)?12:
		(i<14)?translate_symbol(string[i-3]):
		(i==14)?
			(len(string)>11)?
				translate_symbol(string[i-3]):
				calculate_checkdigit(string):
		(i==15)?11:
		(i==16)?10: undef;

	//returns nominal symbol height for the
	//symbol in position i
	//i ranges from 0 to 16
	function get_height(i) =
		(i<3)?27.55:
		(i==8)?27.55:
		(i>13)?27.55: 25.9;

	//returns whether odd or even parity should
	//be used for the symbol in position i
	//i ranges from 0 to 16
	function get_parity(i) = ((i>8)&&(i<15))?false:true;

	//draw individual upc symbol bars based on contents
	//of supplied string
	//string must contain 11 or 12 numerals
	//this module is then called recursively with
	//i incrementing from 0 to 16
	//x is also incremented to translate each symbol
	//along the x-axis
	module draw_symbol(string, bar=1, space=0, quiet_zone=0,
		vector_mode=vector_mode,
		x=0, i=0)
	{
		translate([0,27.55-get_height(i),0])
			scale([0.33, get_height(i), 1])
				translate([x,0,0])
					upc_symbol(symbol=get_symbol(string,i),
						bar=bar, space=space, quiet_zone=quiet_zone,
						vector_mode=vector_mode,
						parity=get_parity(i));
		if (i<16)
			draw_symbol(string, bar, space, quiet_zone,
				vector_mode,
				x+upc_symbol_len(get_symbol(string,i)),
				i+1);
	}

	//returns the position x/y for the text digit in
	//position i ranging from 0 to 11
	function get_text_pos(i) =
	[
		0.33*(
			(i==0)?0:
			(i<6)?(
				upc_symbol_len(10)+upc_symbol_len(11)+
				upc_symbol_len(0)*(i+0.25)
			):
			(i<11)?(
				upc_symbol_len(10)+upc_symbol_len(11)+
				upc_symbol_len(12)+
				upc_symbol_len(0)*(i+0.25)
			):
			(
				upc_symbol_len(10)+upc_symbol_len(11)+
				upc_symbol_len(12)+
				upc_symbol_len(10)+upc_symbol_len(11)+
				upc_symbol_len(0)*(i+0.25)
			)),
		(i==0)?(27.55-25.9):
		(i==11)?(27.55-25.9):0,
		0
	];

	//draw individual text numerals based on contents
	//of supplied string
	//string must contain 11 or 12 numerals
	//this module is then called recursively with
	//i incrementing from 0 to 11
	module draw_text(string, font, fontsize, i=0)
	{
		numeral=string[i]?string[i]:
			str(calculate_checkdigit(string));
		translate(get_text_pos(i))
			text(numeral, font=font, size=fontsize);

		if (i<11)
			draw_text(string, font, fontsize, i+1);
	}

	module extrude_text(vector_mode, height)
	{
		if (vector_mode)
			children();
		else
			linear_extrude(height)
				children();
	}

	draw_symbol(string, bar=bar, space=space, quiet_zone=quiet_zone, vector_mode=vector_mode);
	if (font)
		if (is_indexable(bar))
			color(bar) extrude_text(vector_mode, 1)
				draw_text(string, font, fontsize);
		else
			extrude_text(vector_mode, clamp_nonnum(bar))
				draw_text(string, font, fontsize);
}

/* examples */
//UPC_A("333333333331", bar="blue", font=undef);
//UPC_A("33333333333", bar="black"); //checkdigit 1
//UPC_A("03600029145", bar="black"); //checkdigit 2
//UPC_A("04210000526", bar="black"); //checkdigit 4
//UPC_A("12345678901", bar="black"); //checkdigit 2
UPC_A("01234554321", bar="black"); //checkdigit 0
//UPC_A("012345543210", bar="black", vector_mode=true);
//UPC_A("012345543210", bar=true);
//UPC_A("012345543210", bar=3);
//UPC_A("012345543210", bar=[.5,.8,.9]);
//UPC_A("012345543210", bar=false);
//UPC_A("012345543210", bar=0);
//UPC_A("012345543210");
