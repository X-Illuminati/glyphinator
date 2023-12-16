/*****************************************************************************
 * Code 39 Symbol Library
 * Generates Code 39 Barcodes
 *****************************************************************************
 * Copyright 2017 Jasper Chan
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
 * API:
 *   code39(code, height, unit, text)
 *     code: code to be encoded (must be wrapped in *, e.x. "*ABC*")
 *     height: specifies how tall the barcode is (default: 10).
 *     unit: specifies the width of a single bar unit (default: 1).
 *     text: "char" to show character under each symbol, "centered" to show
 *           entire code centered under barcode
 *     center: specify whether to center the barcode on the origin
 *             (default: false)
 *
 *   code39_width(code, unit)
 *     code: code to be encoded (must be wrapped in *, e.x. "*ABC*")
 *     unit: specifies the width of a single bar unit (default: 1).
 *
 *****************************************************************************/


/*
 * 2D Vector of supported Code 39 characters
 */
char_vector = [
	["1", "A", "K", "U"],
	["2", "B", "L", "V"],
	["3", "C", "M", "W"],
	["4", "D", "N", "X"],
	["5", "E", "O", "Y"],
	["6", "F", "P", "Z"],
	["7", "G", "Q", "-"],
	["8", "H", "R", "."],
	["9", "I", "S", " "],
	["0", "J", "T", "*"],
	["$", "/", "+", "%"]
];


/*
 * 1D version of char_vector to make searching for characters easier
 */
function flatten(l) = [ for (a = l) for (b = a) b ];
flat_char_vector = flatten(char_vector);

/*
 * 1 is wide bar, 0 is thin bar
 */
bar_vector = [
	[1, 0, 0, 0, 1], // ▮|||▮
	[0, 1, 0, 0, 1], // |▮||▮
	[1, 1, 0, 0, 0], // ▮▮|||
	[0, 0, 1, 0, 1], // ||▮|▮
	[1, 0, 1, 0, 0], // ▮|▮||
	[0, 1, 1, 0, 0], // |▮▮||
	[0, 0, 0, 1, 1], // |||▮▮
	[1, 0, 0, 1, 0], // ▮||▮|
	[0, 1, 0, 1, 0], // |▮|▮|
	[0, 0, 1, 1, 0], // ||▮▮|
	[0, 0, 0, 0, 0], // |||||
];


/*
 * index to put a space in (0 indexed, space is put after index)
 */
space_vector = [
	[
		[1],
		[2],
		[3],
		[0]
	],
	[
		[0, 1, 2],
		[0, 1, 3],
		[0, 2, 3],
		[1, 2, 3]
	]
];

/*
 * Returns true if item is in list, false otherwise
 */
function item_in_list(item, list, idx=0) =
	list[idx] == item
	? true
	: idx >= len(list)
	  ? false
	  : item_in_list(item, list, idx=idx+1);

/*
 * 11th row of the Code 39 table uses a different spacing scheme
 */
function get_space_vector_idx(idx0) =
	idx0 == 10
	? 1
	: 0;

/*
 * Get the index of a character from flat_char_vector
 */
function get_flat_idx(char, idx=0) =
	char == flat_char_vector[idx]
	? idx
	: get_flat_idx(char, idx=idx+1);

/*
 * Get the indices of a character from char_vector, returned as a list
 */
function get_idx(char) =
	let(idx = get_flat_idx(char),
		idx0 = floor(idx/len(char_vector[0])),
		idx1 = idx % len(char_vector[0]))
		[idx0, idx1];

/*
 * Get the width of a single bar in a symbol
 * Args:
 *	idx: index of the bar inside the symbol
 *	space: list of indexes to insert a space in the symbol
 * 	bar: list of wide/thin bars in the symbol
 *	include_space: include the space that comes after the bar as part of the width
 */
function get_bar_fragment_width(idx, space, bar, include_space=true) =
	let(
		bar_width = bar[idx] ? 3 : 1,
		space_width = include_space ? (item_in_list(idx, space) ? 3 : 1) : 0)
	bar_width + space_width;

/*
 * Get the offset of a single bar in a symbol
 * Args:
 *	idx: index of the bar inside the symbol
 *	space: list of indexes to insert a space in the symbol
 * 	bar: list of wide/thin bars in the symbol
 */
function get_bar_offset(idx, space, bar, offset=0) =
	idx == 0
	? offset
	: get_bar_offset(
		idx-1, space, bar, offset + get_bar_fragment_width(idx-1, space, bar));

/*
 * Remove the * markers at the beginning and end of a Code 39 string
 * Args:
 *	in: string to strip
 */
function strip_marker(in, out="", idx=0) =
	idx == len(in)
	? out
	: in[idx] == "*"
	  ? strip_marker(in, out=out, idx=idx+1)
	  : strip_marker(in, out=str(out, in[idx]), idx=idx+1);

/*
 * Single Code 39 Symbol
 * Args:
 *	char: char to encode
 *	height: height of the symbol
 */
module code39_symbol(char, height=10) {
	idxs = get_idx(char);
	bar = bar_vector[idxs[0]];
	space_idx = get_space_vector_idx(idxs[0]);
	space = space_vector[space_idx][idxs[1]];
	bar_vector = [
	for(i = [0:len(bar)-1])
		let(
			bar_width = get_bar_fragment_width(i, space, bar, include_space=false),
			bar_offset = get_bar_offset(i, space, bar)
		) [bar_width, bar_offset]
	];
	for(i = [0:len(bar)-1]) {
		translate([bar_vector[i][1], 0])
			square([bar_vector[i][0], height]);
	}
}

/*
 * Code 39 barcode width helper
 *	Returns the width of the barcode (note: does not include the
 *	final character separation space after the last character)
 * Args:
 *	code: string to encode (must be wrapped with "*")
 *	unit: width of a single thin bar/space
 */
function code39_width(code, unit=1) = ((len(code))*16 - 1)*unit;

/*
 * Code 39 barcode
 * Args:
 *	code: string to encode (must be wrapped with "*")
 *	height: height of the barcode
 *	unit: width of a single thin bar/space
 *	text: "char" to have each character printed under its respective symbol,
 *	      "centered" to have the whole string centered under the barcode
 */
module code39(code, height=10, unit=1, text=false, center=false) {
	offset=(center)?
		[code39_width(code, unit)/2, height/2]:
		[0,0];

	for(i = [0:len(code)-1]) {
		translate([i*16*unit, 0]-offset)
			scale([unit, 1, 1])
				code39_symbol(code[i], height=height);
	}
	text_size = unit*10;
	if(text == "char") {
		for(i = [0:len(code)-1]) {
			if(code[i] != "*")
				translate([(i+0.5)*16*unit, -text_size-1]-offset)
					text(code[i], font="Courier New:style=Bold",
						 halign="center", size=text_size);
		}
	} else if(text == "centered") {
		translate([len(code)*16*unit/2, -3]-offset)
			text(strip_marker(code), font="Courier New:style=Bold",
				 halign="center", valign="top", size=text_size);
	}
}

/* examples */
//color("black")
//code39("*ABCDEFG$/+%*", height=40, text="centered")

color("black")
	linear_extrude(3, center=true)
		code39("*A %*", height=40, unit=2, text="char", center=true);
