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
 * - util/bitlib.scad
 * - util/bitmap.scad
 * - util/reed-solomon.scad
 *
 * API:
 *   data_matrix(bytes, size, corner, mark, space)
 *     Generates a DataMatrix symbol with contents specified by bytes.
 *     The size parameter is the dimension of the symbol.
 *     The corner parameter will depend on the overall size and should be
 *     automated in the future.
 *     The mark and space parameters can be used to change the appearance of
 *     the symbol. See the bitmap library for more details.
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
 *   dm_pad(data, data_size)
 *     Pad the data byte vector up to data_size using the DataMatrix padding
 *     algorithm (mod 253).
 *     This padding algorithm includes the EOM byte if necessary.
 *
 *   dm_ecc(data, data_size, ecc_size)
 *     Calculate DataMatrix ECC200 error correction bytes over data.
 *     The data vector must have a length of data_size.
 *     The result of this function will be a vector that includes data
 *     followed by ecc_size error correction bytes.
 *
 * TODO:
 *  - Add support for larger sizes (many missing)
 *  - Determine ideal data size (and ecc size) automatically from supplied
 *    data byte vector
 *  - Determine dimensions and corner type from ideal data size
 *  - Add support for rectangular matrixes
 *  - Add other encoding modes (low priority)
 *
 *****************************************************************************/
use <util/bitlib.scad>
use <util/bitmap.scad>
use <util/reed-solomon.scad>

/* Some definitions of useful data bytes that can be
   concatenated into your byte string */
function EOM() = 129; // end-of-message (first padding byte)
function c40_mode() = 230; // begin C40 encoding mode
function base256_mode() = 231; // begin base-256 (byte) encoding mode
function fnc1_mode() = 232; // begin FNC1 (GS1-DataMatrix) encoding mode
function text_mode() = 239; // begin text encoding mode
function ascii_mode() = 254; // return to ASCII encoding mode
function unused() = 0; // 0 is explicitly not used as a control code

/*
 * dm_codeword - generate a single codeword as a 2D array
 *   suitable for passing to the 2dbitmap module
 *
 * x - data byte to encode
 * M - mark value
 * S - space value
 * (see documentation in bitmap.scad)
 */
function dm_codeword(x, M=1, S=0) = [
	[bit(x,7)?M:S, bit(x,6)?M:S, 0],
	[bit(x,5)?M:S, bit(x,4)?M:S, bit(x,3)?M:S],
	[bit(x,2)?M:S, bit(x,1)?M:S, bit(x,0)?M:S]
];

/*
 * ascii_to_dec - convert ASCII string to decimal vector
 *
 * a - the ASCII string to vectorize
 */
function ascii_to_dec(a) =
[
	for (i = [0 : len(a) - 1])
		let (val = search(a, "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7f"))
			val[i]+1
];

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
	let (vec=ascii_to_dec(string))
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
 * dm_pad - pad a byte vector up to an expected size
 *
 * data - the vector of initial data bytes
 * data_size - the expected vector size
 *  (this value depends on the barcode dimensions)
 *
 * returns undef if len(data) > data_size
 */
function dm_pad(data, data_size) =
	(len(data)>data_size)?undef:
	[
		for (i=[0:data_size-1])
			(i==len(data))? EOM():
			(i>len(data))?
				let(p=((((149*(i+1))%253)+130)%254))
					(p==0)?254:p:
			data[i]
	];

/*
 * dm_ecc - append DataMatrix ECC200 error correction bytes
 *
 * data - the vector of data bytes
 * data_size - the data length for the particular matrix size
 * ecc_size - the ecc length for the particular matrix size
 */
function dm_ecc(data,data_size,ecc_size) =
	concat(data,rs_ecc(data,data_size,ecc_size));

/*
 * data_matrix - Generate a DataMatrix barcode
 *
 * bytes - data bytes to encode
 * size - dimensions of the barcode (must be multiple of two)
 * corner - corner style to use
 * (TODO: determine this automatically)
 *
 * mark - mark representation
 * space - space representation
 * (see documentation in bitmap.scad)
 */
module data_matrix(bytes, size, corner, mark=1, space=0)
{
	if ((size==undef) || (size.x%2) || (size.y%2))
		echo("WARNING: size must be a multiple of two in each dimension");

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
				2dbitmap([
					[s[1][1],s[1][2],s[2][0],s[2][1]],
					[0,0,0,s[2][2]]
				]);
		else /* 1==corner */
			translate([size.x-4,-4,0])
				2dbitmap([
					[s[1][1],s[1][2]],
					[0,s[2][0]],
					[0,s[2][1]],
					[0,s[2][2]]
				]);
	}

	module drawcorner2(s, size, corner)
	{
		if (2==corner)
			translate([0,-size.y+2,0])
				2dbitmap([
					[s[0][0]],
					[s[0][1]],
					[s[1][0]]
				]);
		else /* 1==corner */
			translate([0,-size.y+2,0])
				2dbitmap([
					[s[0][0],s[0][1],s[1][0]]
				]);
	}

	//x-adjustment for split codewords (based on corner type)
	function splitx(size)=
		(22==size.x)?4:
		(20==size.x)?-2:
		(18==size.x)?0:
		(16==size.x)?2:
		(14==size.x)?4:
		(12==size.x)?-2:
		(10==size.x)?0:
		0;

	//y-adjustment for split codewords (based on corner type)
	function splity(size)=
		(22==size.y)?-4:
		(20==size.y)?2:
		(18==size.y)?0:
		(16==size.y)?-2:
		(14==size.y)?-4:
		(12==size.y)?2:
		(10==size.y)?0:
		0;

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
	module draw_codeword(bitmap, size, corner, x, y)
	{
		if (x<0) {
			if ((corner) && (-y+4>size.y)) {
				drawcorner1(bitmap, size, corner);
				drawcorner2(bitmap, size, corner);
			} else {
				translate([0,y,0])
					2dbitmap(colsplit(bitmap, x));
				translate([size.x+x-2,y+splity(size),0])
					2dbitmap(colsplit(bitmap, -x));
			}
		} else {
			if (y+2>=0) {
				translate([x,y,0])
					2dbitmap(rowsplit(bitmap, y));
				translate([x+splitx(size),-size.y+2,0])
					2dbitmap(rowsplit(bitmap, -y));
			} else {
				translate([x,y,0])
					2dbitmap(bitmap);
			}
		}
	}

	//draw individual codewords from bytes array
	//this module is called recursively with i, x, y, and direction
	//iterating across the data region of the symbol
	//size and corner define the shape of the symbol
	module data_matrix_inner(bytes, size, corner, mark=1, space=0, i=0, x=-2, y=-5, direction=0)
	{
		//echo(str("DEBUG x=", x, " y=", y, " dir=", direction%2, " val=", bytes[i]));

		// convert the byte to a codeword bitmap
		bitmap=(bytes[i]==undef)?undef:dm_codeword(bytes[i], mark, space);

		// draw the codeword
		if (bitmap==undef)
			translate([size.x-4,-size.y+2,0])
				2dbitmap(unusedshape(size, mark, space));
		else
			draw_codeword(bitmap, size, corner, x, y);

		// recurse
		if (i<len(bytes)) {
			if (direction%2) {
				if (x<0) {
					if (-y+2>=size.y) {
						new_dir = direction+1;
						new_x=x+5;
						new_y=y+1;
						data_matrix_inner(bytes, size, corner, mark, space, i+1, new_x, new_y, new_dir);
					} else if (-y+4>=size.y) {
						new_dir = direction+1;
						new_x=x+3;
						new_y=y-1;
						data_matrix_inner(bytes, size, corner, mark, space, i+1, new_x, new_y, new_dir);
					} else {
						new_dir = direction+1;
						new_x=x-2+1;
						new_y=y-2-3;
						data_matrix_inner(bytes, size, corner, mark, space, i+1, new_x, new_y, new_dir);
					}
				} else if (-y+2>=size.y) {
					new_dir = direction+1;
					new_x=x+2+3;
					new_y=y+2-1;
					data_matrix_inner(bytes, size, corner, mark, space, i+1, new_x, new_y, new_dir);
				} else {
					new_x=x-2;
					new_y=y-2;
					new_dir = direction;
					data_matrix_inner(bytes, size, corner, mark, space, i+1, new_x, new_y, new_dir);
				}
			} else {
				if ((y+2>0) || check_corner_collision(corner, size, x, y)) {
					new_dir = direction+1;
					new_x=x+2+1;
					new_y=y+2-3;
					data_matrix_inner(bytes, size, corner, mark, space,  i+1, new_x, new_y, new_dir);
				} else if (x+5>=size.x-2) {
					new_dir = direction+1;
					new_x=x-2+3;
					new_y=y-2-1;
					data_matrix_inner(bytes, size, corner, mark, space,  i+1, new_x, new_y, new_dir);
				} else {
					new_x=x+2;
					new_y=y+2;
					new_dir = direction;
					data_matrix_inner(bytes, size, corner, mark, space,  i+1, new_x, new_y, new_dir);
				}
			}
		}
	}


	// draw the symbol
	translate([2,size.y,0]) {
		//draw the data region
		data_matrix_inner(bytes, size, corner, mark, space);
		//draw the L finder pattern
		translate([-1,-size.y+1])
			2dbitmap([[for (i=[0:size.x-1]) mark]]);
		translate([-1,-size.y+2])
			2dbitmap([for (i=[0:size.y-2]) [mark]]);
		//draw the clock track
		2dbitmap([[for (i=[0:size.x-2]) (i%2)?mark:space]]);
		translate([size.x-2,-size.y+2])
			2dbitmap([for (i=[1:size.y-2]) [(i%2)?mark:space]]);
		//draw the quiet zone
		translate([-2,-size.y])
			2dbitmap([[for (i=[0:size.x+1]) space]]);
		translate([-2,-size.y+1])
			2dbitmap([for (i=[0:size.y]) [space]]);
		translate([-1,1])
			2dbitmap([[for (i=[0:size.x-1]) space]]);
		translate([size.x-1,-size.y+1])
			2dbitmap([for (i=[1:size.y+1]) [space]]);
	}
}

/* Examples */

/* 10x10 - 3 data bytes, 5 ecc bytes */
//data_matrix(dm_ecc(dm_ascii("123456"), 3, 5), size=[10,10], corner=0, mark="black");
/* same as above but with dm_pad(), which is redundant in this case */
//data_matrix(dm_ecc(dm_pad(dm_ascii("123456"),3), 3, 5), size=[10,10], corner=0, mark="black");
/* same as above but with manual ecc bytes instead of dm_ecc() */
//data_matrix(concat(dm_ascii("123456"),[114,25,5,88,102]), size=[10,10], corner=0, mark="black");

/* 12x12 - 5 data bytes, 7 ecc bytes */
//data_matrix(dm_ecc(dm_pad(dm_ascii("17001164"),5), 5, 7), size=[12,12], corner=0, mark="black");
//data_matrix(dm_ecc(concat(c40_mode(),dm_c40("H0VLP7")), 5, 7), size=[12,12], corner=0, mark="black");

/* 14x14 - 8 data bytes, 10 ecc bytes */
//data_matrix(dm_ecc(concat(c40_mode(),dm_c40("TELESI"),ascii_mode(),dm_ascii("S1")), 8, 10), size=[14,14], corner=1, mark="black");

/* 16x16 - 12 data bytes, 12 ecc bytes */
//data_matrix(dm_ecc(dm_pad(dm_ascii("Wikipedia"),12), 12, 12), size=[16,16], corner=2, mark="black");

/* 18x18 - 18 data bytes, 14 ecc bytes */
//data_matrix(dm_ecc(dm_pad(dm_ascii("Hourez Jonathan"),18),18,14), size=[18,18], corner=0, mark="black");

/* 20x20 - 22 data bytes, 18 ecc bytes */
//data_matrix(dm_ecc(dm_pad(concat([fnc1_mode()],dm_ascii("01034531200000111709112510ABCD1234")),22),22,18), size=[20,20], corner=0, mark="black");

/* 22x22 - 30 data bytes, 20 ecc bytes */
//data_matrix(dm_ecc(dm_pad(dm_ascii("http://www.idautomation.com"),30), 30, 20), size=[22,22], corner=1, mark="black");
data_matrix(dm_ecc(dm_pad(concat(text_mode(),dm_text("Wikipedia, the free encyclopedi"),ascii_mode(),dm_ascii("a")),30), 30, 20), size=[22,22], corner=1, mark="black");
/* same as above but using manual padding and ecc */
//data_matrix(concat(text_mode(),dm_text("Wikipedia, the free encyclopedi"),ascii_mode(),dm_ascii("a"),EOM(),[104,254,150,45,20,78,91,227,88,60,21,174,213,62,93,103,126,46,56,95,247,47,22,65]), size=[22,22], corner=1, mark="black");

/* base-256 mode example: data is 63=0x3F='?' */
//data_matrix(dm_ecc(dm_base256_append([base256_mode()],[63],fills_symbol=true), 3, 5), size=[10,10], corner=0, mark="black");
