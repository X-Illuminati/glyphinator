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
 *
 * Library Dependencies:
 * - util/compat.scad
 * - util/bitmap.scad
 *   - util/compat.scad
 * - util/stringlib.scad
 *   - util/compat.scad
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
 *   EAN_13(string, bar, space, quiet_zone, vector_mode, font, fontsize)
 *     Generates the EAN-13 barcode representing string.
 *     The bar, space, and quiet_zone parameters can be used to change the
 *     appearance of the barcode. See the bitmap library for more details.
 *     The vector_mode determines whether to create 2D vector artwork instead
 *     of 3D solid geometry. See notes/caveats in the bitmap library.
 *     The font and fontsize control the font used for drawing the text digits
 *     below each symbol.
 *
 *****************************************************************************/
use <../util/compat.scad>
use <../util/bitmap.scad>
use <../util/stringlib.scad>

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
 *   string of digits of length 11 or 12
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
	//calculates the checkdigit by recursively
	//parsing the 11-digit vector provided
	//i is incremented from 0 to 10
	//i has a special default value of -1 to
	//conduct some final processing on the answer
	function calculate_checkdigit(digits, i=-1) =
		(i==10)?digits[i]*3:
		(i==-1)?
			(10-(calculate_checkdigit(digits,i=0)%10))%10
		:
			(((10-i)%2)?1:3)*digits[i]
				+calculate_checkdigit(digits, i+1);

	digits = atoi(string);
	draw_quiet_arrow = false;
	do_assert((len(digits)==11) || (len(digits)==12),
		"UPC string must be exactly 11 or 12 digits");

	checkdigit = calculate_checkdigit(digits);
	if (len(digits)==12 && digits[11] != checkdigit)
		echo(str("WARNING: incorrect check digit supplied ", digits[11], "!=", checkdigit));

	//returns the symbol to draw at position i
	//i ranges from 0 to 16
	function get_symbol(digits, checkdigit, i) =
		(i==0)?10:
		(i==1)?11:
		(i<8)?digits[i-2]:
		(i==8)?12:
		(i<14)?digits[i-3]:
		(i==14)?
			(len(digits)>11)?
				digits[i-3]:
				checkdigit:
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
	function get_parity(digits, i) = ((i>8)&&(i<15))?false:true;

	//returns whether normal or reversed pattern
	//should be used for the symbol in position i
	//i ranges from 0 to 16
	function get_reverse(digits, i) = false;

	//draw individual upc symbol bars based on contents
	//of supplied string
	//digits vector must contain 11 or 12 numerals
	//this module is then called recursively with
	//i incrementing from 0 to 16
	//x is also incremented to translate each symbol
	//along the x-axis
	module draw_symbol(digits, checkdigit,
		bar=1, space=0, quiet_zone=0,
		vector_mode=vector_mode,
		x=0, i=0)
	{
		translate([0,27.55-get_height(i),0])
			scale([0.33, get_height(i), 1])
				translate([x,0,0])
					upc_symbol(
						symbol=get_symbol(digits,checkdigit,i),
						bar=bar, space=space, quiet_zone=quiet_zone,
						vector_mode=vector_mode,
						parity=get_parity(digits, i),
						reverse=get_reverse(digits, i));
		if (i<16)
			draw_symbol(digits, checkdigit,
				bar, space, quiet_zone,
				vector_mode,
				x+upc_symbol_len(get_symbol(digits,checkdigit,i)),
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

	//draw individual text numerals
	//digits must contain 11 or 12 numerals
	//this module is then called recursively with
	//i incrementing from 0 to 12
	module draw_text(digits, checkdigit, draw_quiet_arrow,
		font, fontsize, i=0)
	{
		char = (i==12)?
				(draw_quiet_arrow)?">":"":
				(digits[i]!=undef)?
			str(digits[i]):str(checkdigit);

		translate(get_text_pos(i))
			text(char, font=font, size=fontsize);

		if (i<12)
			draw_text(digits, checkdigit, draw_quiet_arrow,
				font, fontsize, i+1);
	}

	module extrude_text(vector_mode, height)
	{
		if (vector_mode)
			children();
		else
			linear_extrude(height)
				children();
	}

	//preliminaries out of the way
	//invoke the modules to draw the actual symbol
	draw_symbol(digits, checkdigit,
		bar=bar, space=space, quiet_zone=quiet_zone,
		vector_mode=vector_mode);
	if (font)
		if (is_indexable(bar))
			color(bar) extrude_text(vector_mode, 1)
				draw_text(digits, checkdigit, draw_quiet_arrow,
					font, fontsize);
		else
			extrude_text(vector_mode, clamp_nonnum(bar))
				draw_text(digits, checkdigit, draw_quiet_arrow,
					font, fontsize);
}


/*
 * encoding structure for first digit of EAN-13 GTIN
 * 0 indicates normal-odd parity (L)
 * 1 indicates reversed-even parity (G)
 */
ean_13_reverse_vector = [
	[0,0,0,0,0,0], // first digit 0
	[0,0,1,0,1,1], // first digit 1
	[0,0,1,1,0,1], // first digit 2
	[0,0,1,1,1,0], // first digit 3
	[0,1,0,0,1,1], // first digit 4
	[0,1,1,0,0,1], // first digit 5
	[0,1,1,1,0,0], // first digit 6
	[0,1,0,1,0,1], // first digit 7
	[0,1,0,1,1,0], // first digit 8
	[0,1,1,0,1,0], // first digit 9
];

/*
 * EAN_13 - Generate an EAN-13 barcode
 *
 * string - GTIN digit string to encode
 *   string of digits of length 12 or 13
 *   an optional '>' may be appended
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
module EAN_13(string, bar=1, space=0, quiet_zone=0,
	vector_mode=false,
	font="Liberation Mono:style=Bold", fontsize=1.5)
{
	//calculates the checkdigit by recursively
	//parsing the 12-digit vector provided
	//i is incremented from 0 to 11
	//i has a special default value of -1 to
	//conduct some final processing on the answer
	function calculate_checkdigit(digits, i=-1) =
		(i==11)?digits[i]*3:
		(i==-1)?
			(10-(calculate_checkdigit(digits,i=0)%10))%10
		:
			(((11-i)%2)?1:3)*digits[i]
				+calculate_checkdigit(digits, i+1);

	digits = atoi(string);
	draw_quiet_arrow = (string[len(string)-1]==">");
	do_assert((len(digits)==12) || (len(digits)==13),
		"GTIN string must be exactly 12 or 13 digits");

	checkdigit = calculate_checkdigit(digits);
	if (len(digits)==13 && digits[12] != checkdigit)
		echo(str("WARNING: incorrect check digit supplied ", digits[12], "!=", checkdigit));

	//returns the symbol to draw at position i
	//i ranges from 0 to 16
	function get_symbol(digits, checkdigit, i) =
		(i==0)?10:
		(i==1)?11:
		(i<8)?digits[i-1]:
		(i==8)?12:
		(i<14)?digits[i-2]:
		(i==14)?
			(len(digits)>12)?
				digits[i-2]:
				checkdigit:
		(i==15)?11:
		(i==16)?10: undef;

	//returns nominal symbol height for the
	//symbol in position i
	//i ranges from 0 to 16
	function get_height(i) =
		(i<2)?27.55:
		(i==8)?27.55:
		(i>14)?27.55: 25.9;

	//returns whether odd or even parity should
	//be used for the symbol in position i
	//i ranges from 0 to 16
	function get_parity(digits, i) =
		((i>8)&&(i<15))?false:
		((i>1)&&(i<8))?
			ean_13_reverse_vector[digits[0]][i-2]?
				false:
				true:
			true;

	//returns whether normal or reversed pattern
	//should be used for the symbol in position i
	//i ranges from 0 to 16
	function get_reverse(digits, i) =
		((i>8)&&(i<15))?false:
		((i>1)&&(i<8))?
			ean_13_reverse_vector[digits[0]][i-2]?
				true:
				false:
			false;

	//draw individual upc symbol bars based on contents
	//of supplied string
	//digits vector must contain 12 or 13 numerals
	//this module is then called recursively with
	//i incrementing from 0 to 16
	//x is also incremented to translate each symbol
	//along the x-axis
	module draw_symbol(digits, checkdigit,
		bar=1, space=0, quiet_zone=0,
		vector_mode=vector_mode,
		x=0, i=0)
	{
		translate([0,27.55-get_height(i),0])
			scale([0.33, get_height(i), 1])
				translate([x,0,0])
					upc_symbol(
						symbol=get_symbol(digits,checkdigit,i),
						bar=bar, space=space, quiet_zone=quiet_zone,
						vector_mode=vector_mode,
						parity=get_parity(digits, i),
						reverse=get_reverse(digits, i));
		if (i<16)
			draw_symbol(digits, checkdigit,
				bar, space, quiet_zone,
				vector_mode,
				x+upc_symbol_len(get_symbol(digits,checkdigit,i)),
				i+1);
	}

	//returns the position x/y for the text digit in
	//position i ranging from 0 to 13
	function get_text_pos(i) =
	[
		0.33*(
			(i==0)?0:
			(i<7)?(
				upc_symbol_len(10)+upc_symbol_len(11)+
				upc_symbol_len(0)*(i-1+0.25)
			):
			(i<13)?(
				upc_symbol_len(10)+upc_symbol_len(11)+
				upc_symbol_len(12)+
				upc_symbol_len(0)*(i-1+0.25)
			):
			(
				upc_symbol_len(10)+upc_symbol_len(11)+
				upc_symbol_len(12)+upc_symbol_len(11)+
				upc_symbol_len(0)*(i-1+0.25)
			)
		),
		0,
		0
	];

	//draw individual text numerals
	//digits must contain 12 or 13 numerals
	//this module is then called recursively with
	//i incrementing from 0 to 13
	module draw_text(digits, checkdigit, draw_quiet_arrow,
		font, fontsize, i=0)
	{
		char = (i==13)?
				(draw_quiet_arrow)?">":"":
				(digits[i]!=undef)?
					str(digits[i]):str(checkdigit);

		translate(get_text_pos(i))
			text(char, font=font, size=fontsize);

		if (i<13)
			draw_text(digits, checkdigit, draw_quiet_arrow,
				font, fontsize, i+1);
	}

	module extrude_text(vector_mode, height)
	{
		if (vector_mode)
			children();
		else
			linear_extrude(height)
				children();
	}

	//preliminaries out of the way
	//invoke the modules to draw the actual symbol
	draw_symbol(digits, checkdigit,
		bar=bar, space=space, quiet_zone=quiet_zone,
		vector_mode=vector_mode);
	if (font)
		if (is_indexable(bar))
			color(bar) extrude_text(vector_mode, 1)
				draw_text(digits, checkdigit, draw_quiet_arrow,
					font, fontsize);
		else
			extrude_text(vector_mode, clamp_nonnum(bar))
				draw_text(digits, checkdigit, draw_quiet_arrow,
					font, fontsize);
}


/* examples */
//UPC_A("333333333331", bar="blue", font=undef);
//UPC_A("33333333333", bar="black"); //checkdigit 1
//UPC_A("03600029145", bar="black"); //checkdigit 2
//UPC_A("04210000526", bar="black"); //checkdigit 4
//UPC_A("12345678901", bar="black"); //checkdigit 2
//UPC_A("01234554321", bar="black"); //checkdigit 0
UPC_A("012345543210", bar="black", vector_mode=true);
//UPC_A("012345543210", bar=true);
//UPC_A("012345543210", bar=3);
//UPC_A("012345543210", bar=[.5,.8,.9]);
//UPC_A("012345543210", bar=false);
//UPC_A("012345543210", bar=0);
//UPC_A("012345543210");

//EAN_13("5901234123457>", bar="black");
//EAN_13("871125300120", bar=true); //checkdigit 2
//EAN_13("8711253001202", bar=false);
//EAN_13("8711253001202", bar=0);
//EAN_13("401234512345", bar=3); //checkdigit 6
//EAN_13("978044053981", bar="black", font=undef); //checkdigit 0
//EAN_13("509999785532", bar=[.2,.3,.7]); //checkdigit 3
//EAN_13("506006700408", vector_mode=true); //checkdigit 8
//EAN_13("502236681664>", bar="black"); //checkdigit 9
//EAN_13("978144729047", bar="black"); //checkdigit 6
//EAN_13("978038549081", bar="black"); //checkdigit 8
