/*****************************************************************************
 * Data Matrix Symbol Library
 * Generates Data Matrix 2D barcodes
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
 * - util/stringlib.scad
 * - util/bitlib.scad
 * - util/bitmap.scad
 * - util/datamatrix-util.scad
 *   - util/reed-solomon-datamatrix.scad
 *     - util/bitlib.scad
 *
 * API:
 *   data_matrix(bytes, mark=1, space=0, quiet_zone=0, expansion=.001,
 *     vector_mode=false, expert_mode=false)
 *     Generates a DataMatrix symbol with contents specified by bytes.
 *     The mark, space, quiet_zone, and expansion parameters can be used to
 *     change the appearance of the symbol. See the bitmap library for more
 *     details.
 *     The vector_mode flag determines whether to create 2D vector artwork
 *     instead of 3D solid geometry. See notes/caveats in the bitmap library.
 *     The expert_mode flag should only be used by experts.
 *
 *   dm_ascii(string, frob_digits=true)
 *     Returns a suitable byte array representing string, encoded in
 *     DataMatrix ASCII encoding.
 *     Pairs of digits are normally compacted, but this can be forcibly
 *     disabed by setting frob_digits=false.
 *     See ascii_mode() below, but ASCII is the default.
 *
 *   dm_text(string)
 *     Returns a suitable byte array representing string, encoded in
 *     DataMatrix text encoding.
 *     See text_mode() below.
 *
 *   dm_c40(string)
 *     Returns a suitable byte array representing string, encoded in
 *     DataMatrix C40 encoding.
 *     See c40_mode() below.
 *
 *   dm_base256(data, pos, fills_symbol=false)
 *     Encode the data byte vector using DataMatrix base-256 encoding
 *     algorithm (mod 255). A 1 or 2 byte length prefix is prepended to the
 *     data automatically.
 *     The nature of the algorithm means that it needs pos to be the starting
 *     byte position of the data bytes within the overall symbol data field.
 *     See also helper function dm_base256_append().
 *     The fills_symbol flag can be used by experts.
 *     See base256_mode() below.
 *
 *   dm_base256_append(preceding_data, byte_data, fills_symbol=false)
 *     Helper function to append dm_base256(byte_data, _pos_) to
 *     preceding_data, where _pos_ is determined automatically.
 *     The final byte of preceding_data must be 'base256_mode()'.
 *     The fills_symbol flag can be used by experts.
 *
 * TODO:
 *  - Add support for 32x32, 36x36, 40x40, 44x44, 48x48
 *  - Add support for rectangular matrixes
 *  - Add support for larger sizes than 48x48
 *  - Add other encoding modes
 *
 *****************************************************************************/
use <../util/stringlib.scad>
use <../util/bitlib.scad>
use <../util/bitmap.scad>
use <../util/datamatrix-util.scad>

/* Some definitions of useful data bytes that can be
   concatenated into your byte string */
function EOM() = 129; // end-of-message (first padding byte)
function c40_mode() = 230; // begin C40 encoding mode
function base256_mode() = 231; // begin base-256 (byte) encoding mode
function fnc1_mode() = 232; // begin FNC1 (GS1-DataMatrix) encoding mode
function text_mode() = 239; // begin text encoding mode
function ascii_mode() = 254; // return to ASCII encoding mode
function unused() = 0; // 0 is explicitly not used as a control code

//take the ASCII byte vector and convert it to
//the DM ASCII encoding
//compacting of digit pairs can be forcibly disabled
function frobulate(vec, frob_digits=true, i=0) =
	(i==len(vec))?[]: //terminate recursion
		let(
			inc=frob_digits?
				(
					//check for digit pairs
					((vec[i]>=48)&&(vec[i]<=57) &&
					 (vec[i+1]>=48)&&(vec[i+1]<=57))?2:1
				):1,
			val=(inc==2)?
				(vec[i]-48)*10+(vec[i+1]-48)+130:
				vec[i]+1
		)
		concat(val, frobulate(vec, frob_digits, i+inc));
/*
 * dm_ascii - convert ASCII string to byte vector encoded in
 *   DataMatrix ASCII mode
 *
 * string - the ASCII string to encode
 * frob_digits - whether to compact digit pairs
 */
function dm_ascii(string, frob_digits=true) =
	let (vec=ascii_to_vec(string))
	frobulate(vec,frob_digits);

function ascii_to_text(a) =
	let (
		bytearray =
		[
			for (val=search(a, " 0123456789abcdefghijklmnopqrstuvwxyz\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f!\"#$%&'()*+,-./:;<=>?@[\\]^_`ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}~\x7f"))
				(val>=95)?[2,val-95]:
				(val>=68)?[1,val-68]:
				(val>=37)?[0,val-37+1]:
				[val+3]
		]
	) [ for (B=bytearray, b=B) b ];

function ascii_to_c40(a) =
	let (
		bytearray =
		[
			for (val=search(a, " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f!\"#$%&'()*+,-./:;<=>?@[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7f"))
				(val>=95)?[2,val-95]:
				(val>=68)?[1,val-68]:
				(val>=37)?[0,val-37+1]:
				[val+3]
		]
	) [ for (B=bytearray, b=B) b ];

/*
 * dm_text - convert ASCII string to byte vector encoded in
 *   DataMatrix text mode
 *
 * string - the ASCII string to encode
 */
function dm_text(string) =
	let (
		bytearray = ascii_to_text(string),
		bytelen = len(bytearray)
	) [	for (
			i=[0:3:bytelen-1],
			packedval=bytearray[i]*1600+bytearray[i+1]*40+bytearray[i+2]+1,
			bytepair=[floor(packedval/256),packedval%256]
		) bytepair ];

/*
 * dm_c40 - convert ASCII string to byte vector encoded in
 *   DataMatrix C40 mode
 *
 * string - the ASCII string to encode
 */
function dm_c40(string) =
	let (
		bytearray = ascii_to_c40(string),
		bytelen = len(bytearray)
	) [	for (
			i=[0:3:bytelen-1],
			packedval=bytearray[i]*1600+bytearray[i+1]*40+bytearray[i+2]+1,
			bytepair=[floor(packedval/256),packedval%256]
		) bytepair ];

/*
 * dm_base256 - encode byte vector in DataMatrix base-256 mode
 *
 * data - the byte data to encode
 * pos - the starting byte position of the data within the
 *   overall symbol data field
 *   note: at least base256_mode()=231 will precede the byte
 *   data so this value can not be 0
 *   see also: dm_base256_append()
 * fills_symbol - indicates that the data vector fills out
 *   the remainder of the symbol by itself -- this attribute
 *   is a little bit awkward and I'm not sure that it is
 *   really necessary; so, if in doubt, leave it false
 */
function dm_base256(data, pos=1, fills_symbol=false) =
	let(l = len(data))
		(l==0)?undef:
		let(prefix =
			(fills_symbol)?[0]:
			(l<250)?[l]:
			[249+floor(l/250),l%250],
			message=concat(prefix,data)
		)
		[
			for (i=[0:len(message)-1])
				((((149*(i+pos+1))%255)+1+message[i])%256)
		];

/*
 * dm_base256_append - encode byte vector in DataMatrix
 *	 base-256 mode and append it to some existing data
 *
 * preceding_data - the pre-existing data to append this to
 *   note: must end with base256_mode()=231
 * byte_data - the byte data to encode
 * fills_symbol - indicates that the data vector fills out
 *   the remainder of the symbol by itself -- this attribute
 *   is a little bit awkward and I'm not sure that it is
 *   really necessary; so, if in doubt, leave it false
 */
function dm_base256_append(preceding_data, byte_data, fills_symbol=false) =
	let (l = len(preceding_data))
		(preceding_data[l-1]!=base256_mode())?undef:
		concat(preceding_data, dm_base256(byte_data, l, fills_symbol));

/*
 * data_matrix - Generate a DataMatrix barcode
 *
 * bytes - data bytes to encode
 *
 * mark - mark representation
 * space - space representation
 * quiet_zone - representation for the quiet zone
 * expansion - reduce modules by this amount
 *   (see documentation in bitmap.scad)
 *
 * vector_mode - create a 2D vector drawing instead of 3D extrusion
 * expert_mode - only use this if you are an expert
 */
module data_matrix(bytes, mark=1, space=0, quiet_zone=0, expansion=.001,
	vector_mode=false, expert_mode=false)
{
	properties = (expert_mode)?
		dm_get_props_by_total_size(len(bytes)):
		dm_get_props_by_data_size(len(bytes));
	data_bytes = (expert_mode)?bytes:dm_ecc(dm_pad(bytes));
	size=dm_prop_dimensions(properties);

	if (properties==undef)
		if (expert_mode)
			echo("ERROR: Are you sure you're an expert?");
		else
			echo(str("ERROR: Could not determine symbol dimensions. ",
				len(bytes), " bytes of data might be an unsupported size."));

	corner=dm_prop_corner(properties);
	xadj=dm_prop_x_adjust(properties);
	yadj=dm_prop_y_adjust(properties);

	//echo(str("DEBUG size=", size, " xadj=", xadj, " yadj=", yadj, " corner=", corner));

	//generate a single codeword as a 2D array
	//suitable for passing to the 2dbitmap module
	function dm_codeword(x, M=1, S=0) = [
		[bit(x,7)?M:S, bit(x,6)?M:S, 0],
		[bit(x,5)?M:S, bit(x,4)?M:S, bit(x,3)?M:S],
		[bit(x,2)?M:S, bit(x,1)?M:S, bit(x,0)?M:S]
	];

	//split the codeword into two, selecting columns
	function colsplit(s, x) =
	[
		for(i=[0:2]) // iterate over all 3 rows
		[
			// select left-most 1 or 2 columns if x is positive
			// select right-most 1 or 2 columns if x is negative
			for (j=[((x<0)?-x:0) : ((x<0)?2:x-1)])
				s[i][j]
		]
	];

	//split the codeword into two, selecting rows
	function rowsplit(s, y) =
	[
		// select top-most 1 or 2 rows if y is positive
		// select bottom-most 1 or 2 rows if y is negative
		for (i=[((y<0)?3+y:0) : ((y<0)?2:2-y)])
			s[i]
	];

	//split the codeword into two parts for the
	//upper right and lower left corner
	//todo: calculate corner shape automatically
	module drawcorner1(s, size, corner)
	{

		if (2==corner)
			translate([size.x-6,-2,0])
				2dbitmap(
					[
						[s[1][1],s[1][2],s[2][0],s[2][1]],
						[0,0,0,s[2][2]]
					],
					expansion=expansion, vector_mode=vector_mode);
		else /* 1==corner */
			translate([size.x-4,-4,0])
				2dbitmap(
					[
						[s[1][1],s[1][2]],
						[0,s[2][0]],
						[0,s[2][1]],
						[0,s[2][2]]
					],
					expansion=expansion, vector_mode=vector_mode);
	}

	module drawcorner2(s, size, corner)
	{
		if (2==corner)
			translate([0,-size.y+2,0])
				2dbitmap(
					[
						[s[0][0]],
						[s[0][1]],
						[s[1][0]]
					],
					expansion=expansion, vector_mode=vector_mode);
		else /* 1==corner */
			translate([0,-size.y+2,0])
				2dbitmap(
					[
						[s[0][0],s[0][1],s[1][0]]
					],
					expansion=expansion, vector_mode=vector_mode);
	}

	//check whether x,y have entered the upper-right corner
	//codeword shape (based on corner type)
	function check_corner_collision(corner, size, x, y)=
		(1==corner)?
			((y+3>0) && (x+10>size.x)):
		(2==corner)?
			((y+4>0) && (x+10>size.x)):
		false;

	//generate a filler shape for unused area
	function unusedshape(size, M=1, S=0)=
		(4==((size.x-2)*(size.y-2))%8)?
		[
			[M,S],
			[S,M]
		]:undef;

	//draw the codeword bitmap at the given x,y
	//coordinates
	//uses size and corner type to split the codeword
	//across the edges of the symbol
	module draw_codeword(bitmap, x, y, size, corner, xadj, yadj)
	{
		if (x<0) {
			if ((corner) && (-y+4>size.y)) {
				drawcorner1(bitmap, size, corner);
				drawcorner2(bitmap, size, corner);
			} else {
				translate([0,y,0])
					2dbitmap(colsplit(bitmap, x), expansion=expansion,
						vector_mode=vector_mode);
				translate([size.x+x-2,y+yadj,0])
					2dbitmap(colsplit(bitmap, -x), expansion=expansion,
						vector_mode=vector_mode);
			}
		} else {
			if (y+2>=0) {
				translate([x,y,0])
					2dbitmap(rowsplit(bitmap, y), expansion=expansion,
						vector_mode=vector_mode);
				translate([x+xadj,-size.y+2,0])
					2dbitmap(rowsplit(bitmap, -y), expansion=expansion,
						vector_mode=vector_mode);
			} else {
				translate([x,y,0])
					2dbitmap(bitmap, expansion=expansion,
						vector_mode=vector_mode);
			}
		}
	}

	//draw individual codewords from bytes array
	//this module is called recursively with i, x, y, and direction
	//iterating across the data region of the symbol
	//size and corner define the shape of the symbol
	module data_matrix_inner(bytes, size, corner, xadj, yadj, mark=1, space=0, i=0, x=-2, y=-5, direction=0)
	{
		//echo(str("DEBUG x=", x, " y=", y, " dir=", direction%2, " val=", bytes[i]));

		// convert the byte to a codeword bitmap
		bitmap=(bytes[i]==undef)?undef:dm_codeword(bytes[i], mark, space);

		// draw the codeword
		if (bitmap==undef)
			translate([size.x-4,-size.y+2,0])
				2dbitmap(unusedshape(size, mark, space), expansion=expansion,
					vector_mode=vector_mode);
		else
			draw_codeword(bitmap, x, y, size, corner, xadj, yadj);

		// recurse
		if (i<len(bytes)) {
			if (direction%2) {
				if (x<0) {
					if (-y+2>=size.y) {
						new_dir = direction+1;
						new_x=x+5;
						new_y=y+1;
						data_matrix_inner(bytes, size, corner, xadj, yadj, mark, space, i+1, new_x, new_y, new_dir);
					} else if (-y+4>=size.y) {
						new_dir = direction+1;
						new_x=x+3;
						new_y=y-1;
						data_matrix_inner(bytes, size, corner, xadj, yadj, mark, space, i+1, new_x, new_y, new_dir);
					} else {
						new_dir = direction+1;
						new_x=x-2+1;
						new_y=y-2-3;
						data_matrix_inner(bytes, size, corner, xadj, yadj, mark, space, i+1, new_x, new_y, new_dir);
					}
				} else if (-y+2>=size.y) {
					new_dir = direction+1;
					new_x=x+2+3;
					new_y=y+2-1;
					data_matrix_inner(bytes, size, corner, xadj, yadj, mark, space, i+1, new_x, new_y, new_dir);
				} else {
					new_x=x-2;
					new_y=y-2;
					new_dir = direction;
					data_matrix_inner(bytes, size, corner, xadj, yadj, mark, space, i+1, new_x, new_y, new_dir);
				}
			} else {
				if ((y+2>0) || check_corner_collision(corner, size, x, y)) {
					new_dir = direction+1;
					new_x=x+2+1;
					new_y=y+2-3;
					data_matrix_inner(bytes, size, corner, xadj, yadj, mark, space,  i+1, new_x, new_y, new_dir);
				} else if (x+5>=size.x-2) {
					new_dir = direction+1;
					new_x=x-2+3;
					new_y=y-2-1;
					data_matrix_inner(bytes, size, corner, xadj, yadj, mark, space,  i+1, new_x, new_y, new_dir);
				} else {
					new_x=x+2;
					new_y=y+2;
					new_dir = direction;
					data_matrix_inner(bytes, size, corner, xadj, yadj, mark, space,  i+1, new_x, new_y, new_dir);
				}
			}
		}
	}


	// draw the symbol
	if (size != undef)
	translate([2,size.y,0]) {
		//draw the data region
		data_matrix_inner(data_bytes, size, corner, xadj, yadj, mark, space);
		//draw the L finder pattern
		translate([-1,-size.y+1])
			2dbitmap([[for (i=[0:size.x-1]) mark]], expansion=expansion,
				vector_mode=vector_mode);
		translate([-1,-size.y+2])
			2dbitmap([for (i=[0:size.y-2]) [mark]], expansion=expansion,
				vector_mode=vector_mode);
		//draw the clock track
		2dbitmap([[for (i=[0:size.x-2]) (i%2)?mark:space]],
			expansion=expansion, vector_mode=vector_mode);
		translate([size.x-2,-size.y+2])
			2dbitmap([for (i=[1:size.y-2]) [(i%2)?mark:space]],
				expansion=expansion, vector_mode=vector_mode);
		//draw the quiet zone
		translate([-2,-size.y])
			2dbitmap([[for (i=[0:size.x+1]) quiet_zone]], expansion=expansion,
				vector_mode=vector_mode);
		translate([-2,-size.y+1])
			2dbitmap([for (i=[0:size.y]) [quiet_zone]], expansion=expansion,
				vector_mode=vector_mode);
		translate([-1,1])
			2dbitmap([[for (i=[0:size.x-1]) quiet_zone]], expansion=expansion,
				vector_mode=vector_mode);
		translate([size.x-1,-size.y+1])
			2dbitmap([for (i=[1:size.y+1]) [quiet_zone]], expansion=expansion,
				vector_mode=vector_mode);
	}
}

/* Examples */
example=5;
//example  0 - 10x10 - 3 data bytes, 5 ecc bytes - vector_mode example
//example  1 - 10x10 - 3 data bytes, 5 ecc bytes - expert_mode example
//example  2 - 12x12 - 5 data bytes, 7 ecc bytes
//example  3 - 12x12 - 5 data bytes, 7 ecc bytes - c40 mode
//example  4 - 14x14 - 8 data bytes, 10 ecc bytes - mixed-mode
//example  5 - 16x16 - 12 data bytes, 12 ecc bytes - From Wikipedia
//example  6 - 18x18 - 18 data bytes, 14 ecc bytes
//example  7 - 20x20 - 22 data bytes, 18 ecc bytes - fnc1 mode
//example  8 - 22x22 - 30 data bytes, 20 ecc bytes - From http://www.idautomation.com
//example  9 - 22x22 - 30 data bytes, 20 ecc bytes - text mode - From Wikipedia
//example 10 - 22x22 - 30 data bytes, 20 ecc bytes - dm_pad example
//example 11 - 22x22 - 30 data bytes, 20 ecc bytes - expert_mode example
//example 12 - 24x24 - 36 data bytes, 24 ecc bytes
//example 13 - 26x26 - 44 data bytes, 28 ecc bytes
//example 14 - 10x10 - 3 data bytes, 5 ecc bytes - base-256 mode example

if (example==0)
	data_matrix(dm_ascii("123456"), mark="black", vector_mode=true);

// This example is the same as example 0 but with expert_mode ecc bytes provided
// manually instead of using dm_ecc().
if (example==1)
	data_matrix(
		concat(
			dm_ascii("123456"),
			[114,25,5,88,102]
		),
		mark="black", expert_mode=true);

if (example==2)
	data_matrix(dm_ascii("17001164"), mark="black");

if (example==3)
	data_matrix(
		concat(
			c40_mode(),
			dm_c40("H0VLP7")
		),
		mark="black");

if (example==4)
	data_matrix(
		concat(
			c40_mode(),
			dm_c40("TELESI"),
			ascii_mode(),
			dm_ascii("S1")
		),
		mark="black");

if (example==5)
	data_matrix(dm_ascii("Wikipedia"), mark="black");

if (example==6)
	data_matrix(dm_ascii("Hourez Jonathan"), mark="black");

if (example==7)
	data_matrix(
		concat(
			[fnc1_mode()],
			dm_ascii("01034531200000111709112510ABCD1234")
		),
		mark="black");

if (example==8)
	data_matrix(dm_ascii("http://www.idautomation.com"), mark="black");

if (example==9)
	data_matrix(
		concat(
			text_mode(),
			dm_text("Wikipedia, the free encyclopedi"),
			ascii_mode(),
			dm_ascii("a")
		),
		mark="black");

// This example is the same as example 9 but using expert_mode with dm_pad().
if (example==10)
	data_matrix(
		dm_ecc(
			dm_pad(
				concat(
					text_mode(),
					dm_text("Wikipedia, the free encyclopedi"),
					ascii_mode(),
					dm_ascii("a")
				)
			)
		),
		mark="black", expert_mode=true);

// This example is the same as example 9 and 10 but adding the expert_mode
// padding and ecc bytes completely manually instead of using dm_pad().
if (example==11)
	data_matrix(
		concat(
			text_mode(),
			dm_text("Wikipedia, the free encyclopedi"),
			ascii_mode(),
			dm_ascii("a"),
			EOM(),
			[104,254,150,45,20,78,91,227,88,60,21,174,213,62,93,103,126,46,56,95,247,47,22,65]
		),
		mark="black", expert_mode=true);

if (example==12)
	data_matrix(dm_ascii("http://de.wikiquote.org/wiki/Zukunft"), mark="black");

if (example==13)
	data_matrix(
		dm_ascii("http://semapedia.org/v/Mixer_(consolle)/it"),
		mark="black");

// This example shows use of base-256 mode.
// The data is a single byte (63=0x3F='?').
if (example==14)
	data_matrix(
		dm_base256_append(
			[base256_mode()],
			[63],
			fills_symbol=true
		),
		mark="black");
