/********************************************************
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
 *   UPC_A(string, bar, space)
 *     Generates the UPC-A barcode representing string.
 *     The bar and space parameters can be used to
 *     change the appearance of the barcode.
 *     See the bitmap library for more details.
 *
 * TODO:
 *   Add checksum calculation
 *   Add EAN-13 support
 ********************************************************/
use <util/bitmap.scad>

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
 * (see documentation in bitmap.scad)
 *
 * parity - false for even, true for odd
 * reverse - true to mirror the symbol (EAN use)
 */
module upc_symbol(symbol, bar=1, space=0, parity=true, reverse=false)
{
	B=parity?bar:space;
	S=parity?space:bar;

	vector = [
		for (i=[0:1:upc_symbol_len(symbol)-1])
			let (index=reverse?upc_symbol_len(symbol)-i-1:i)
				symbol_vector[symbol][index]?B:S
	];

	1dbitmap(vector);
}

/*
 * upc_symbol - render a single symbol
 *
 * string - UPC digit string to encode
 *   string of digits (only) of length 12
 * 
 * bar - bar representation
 * space - space representation
 * (see documentation in bitmap.scad)
 */
module UPC_A(string, bar=1, space=0)
{
	if (len(string)!=12)
		echo("WARNING: UPC string must be exactly 12 digits");

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

	function get_symbol(string, i) =
		(i==0)?10:
		(i==1)?11:
		(i<8)?translate_symbol(string[i-2]):
		(i==8)?12:
		(i<15)?translate_symbol(string[i-3]):
		(i==15)?11:
		(i==16)?10: undef;
		
	function get_height(i) =
		(i<3)?27.55:
		(i==8)?27.55:
		(i>13)?27.55: 25.9;

	function get_parity(i) = ((i>8)&&(i<15))?false:true;

	module draw_symbol(string, bar=1, space=0, x=0, i=0)
	{
		translate([0,27.55-get_height(i),0])
			scale([0.33, get_height(i), 1])
				translate([x,0,0])
					upc_symbol(symbol=get_symbol(string,i),
						bar=bar, space=space,
						parity=get_parity(i));
		if (i<16)
			draw_symbol(string, bar, space,
				x+upc_symbol_len(get_symbol(string,i)),
				i+1);
	}

	draw_symbol(string, bar=bar, space=space);
}

/* example */
UPC_A("333333333331", bar="black");
