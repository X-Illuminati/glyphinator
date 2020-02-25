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
 * Depends on bitmap.scad library.
 *
 * API:
 *   code39(code, height, unit, text)
 *     code: code to be encoded (must be wrapped in *, e.x. "*ABC*")
 *     height: specifies how tall the barcode is (default: 10).
 *     unit: specifies the width of a single bar unit (default: 1).
 *     text: "char" to show character under each symbol, "centered" to show
 *           entire code centered under barcode
 *
 *****************************************************************************/
use <../util/bitmap.scad>


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
	["0", "J", "T", "*"]
];

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
	[0, 0, 1, 1, 0]  // ||▮▮|
];


/*
 * index to put a space in (0 indexed, space is put after index)
 */
space_vector = [1, 2, 3, 0];

function get_flat_idx(char, idx=0) = 
	char == flat_char_vector[idx] 
	? idx
	: get_flat_idx(char, idx=idx+1);

function get_idx(char) =
	let(idx = get_flat_idx(char),
		idx0 = floor(idx/len(char_vector[0])),
		idx1 = idx % len(char_vector[0])) 
		[idx0, idx1];

function get_bar_fragment_width(idx, space, bar, include_space=true) = 
	let(
		bar_width = bar[idx] ? 3 : 1,
		space_width = include_space ? (idx == space ? 3 : 1) : 0)
	bar_width + space_width;

function get_bar_offset(idx, space, bar, offset=0) = 
	idx == 0
	? offset
	: get_bar_offset(
		idx-1, space, bar, offset + get_bar_fragment_width(idx-1, space, bar));

function strip_marker(in, out="", idx=0) =
	idx == len(in)
	? out
	: in[idx] == "*"
	  ? strip_marker(in, out=out, idx=idx+1)
	  : strip_marker(in, out=str(out, in[idx]), idx=idx+1);

module code39_symbol(char, height=10) {
	idxs = get_idx(char);
	bar = bar_vector[idxs[0]];
	space = space_vector[idxs[1]];
	for(i = [0:len(bar)-1]) {
		let(
			bar_width = get_bar_fragment_width(i, space, bar, include_space=false),
			bar_offset = get_bar_offset(i, space, bar)
		) {
			translate([bar_offset, 0])
				square([bar_width, height]);
		}
	}
}

module code39(code, height=10, unit=1, text=false) {
	for(i = [0:len(code)-1]) {
		translate([i*16*unit, 0])
			scale([unit, 1, 1])
				code39_symbol(code[i], height=height);
	}
	text_size = unit*10;
	if(text == "char") {
		for(i = [0:len(code)-1]) {
			if(code[i] != "*")
				translate([(i+0.5)*16*unit, -3])
					text(code[i], font="Courier New:style=Bold", 
						 halign="center", valign="top", size=text_size);
		}
	} else if(text == "centered") {
		translate([len(code)*16*unit/2, -3])
			text(strip_marker(code), font="Courier New:style=Bold", 
				 halign="center", valign="top", size=text_size);
	}
}

color("black")
code39("*ABCDEFG*", height=40, text="centered");

