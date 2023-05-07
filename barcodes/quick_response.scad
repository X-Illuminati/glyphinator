/*****************************************************************************
 * Quick Response Library
 * Generates Quick Response 2D barcodes
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
 * - util/quick_response-util.scad
 *   - util/bitlib.scad
 *   - util/reed-solomon-quick_response.scad
 *     - util/bitlib.scad
 *
 * API:
 *   quick_response(bytes, ecc_level=2, mask=0, version=undef
 *                  mark=1, space=0, quiet_zone=0, pullback=0.003,
 *                  vector_mode=false, expert_mode=false)
 *     Generates a quick-response-style symbol with contents specified by the
 *     bytes array and selectable ecc_level and mask pattern.
 *     See "ECC Levels" and "Mask Patterns" below for more details.
 *     If necessary, version can be specified explicitly.
 *     The mark, space, quiet_zone, and pullback parameters can be used to
 *     change the appearance of the symbol. A negative pullback will enlarge
 *     the modules and cause them to blend together. See the bitmap library
 *     for more details.
 *     The vector_mode flag determines whether to create 2D vector artwork
 *     instead of 3D solid geometry. See notes/caveats in the bitmap library.
 *     The expert_mode flag should only be used by experts.
 *
 *   qr_bytes(data)
 *     Encode the data byte vector as a quick response byte/binary TLV
 *     vector.
 *     See qr_byte_mode() below.
 *     See ascii_to_vec() in util/stringlib.scad for ASCII conversion.
 *
 *   qr_numeric(digits)
 *     Encode the digits vector as a quick response numeric TLV vector.
 *     See qr_numeric_mode() below.
 *     See atoi() in util/stringlib.scad for ASCII to int conversion.
 *
 *   qr_alphanum(string)
 *     Encode the alpha-numeric string as a quick response alphanumeric TLV
 *     vector.
 *     See qr_alphanum_mode() below.
 *
 * ECC Levels
 *   These determine the number of correctable errors and the ratio of ecc
 *   bytes to data bytes.
 *     0=Low (~7.5% correctable)
 *     1=Mid (~15% correctable)
 *     2=Quality (~22.5% correctable)
 *     3=High (~30% correctable)
 *
 * Mask Patterns
 *   These XOR masks are applied over the data area of the symbo in order to
 *   balance light/dark areas and avoid false-positive matches for the fixed
 *   patterns.
 *     0=checkerboard (fine)
 *     1=rows
 *     2=columns
 *     3=diagonals
 *     4=checkerboard (coarse)
 *     5=* tiles
 *     6=<> tiles
 *     7=bowties
 *
 * TODO:
 * - Larger sizes
 * - Determine best mask automatically
 * - Invert 7-bit remainder word?
 *
 *****************************************************************************/
use <../util/stringlib.scad>
use <../util/bitlib.scad>
use <../util/bitmap.scad>
use <../util/quick_response-util.scad>

function qr_EOM() = qr_bitfield(0,4); //end-of-message
function qr_numeric_mode() = qr_bitfield(1,4); //begin numeric mode (followed by 10-bit length)
function qr_alphanum_mode() = qr_bitfield(2,4); //begin alphanumeric mode (followed by 9-bit length)
function qr_byte_mode() = qr_bitfield(4,4); //begin byte/binary mode (followed by 8-bit length)

/*
 * qr_bytes - encode byte vector in quick response byte/binary mode
 *
 * data - vector of data bytes to encode
 *
 */
function qr_bytes(data) =
	(len(data)==undef)?undef:
	(len(data)>255)?undef:
	concat (
		[qr_byte_mode(), len(data)],
		data
	);

/*
 * qr_numeric - encode digit vector in quick response numeric mode
 *
 * digits - vector of digits to encode
 *
 */
function qr_numeric(digits) =
	(len(digits)==undef)?undef:
	(len(digits)>1023)?undef:
	concat (
		[qr_numeric_mode(), qr_bitfield(len(digits),10)],
		[
			for (i=[0:3:len(digits)-1])
			let
			(
				d1=digits[i],
				d2=digits[i+1],
				d3=digits[i+2],
				len=(d1==undef)?0:
					(d2==undef)?4:
					(d3==undef)?7:
					10,
				v1=(d1>=0 && d1<=9)?d1:undef,
				v2=(d2>=0 && d2<=9)?d2:undef,
				v3=(d3>=0 && d3<=9)?d3:undef,
				val=(v1==undef)?0:
					(v2==undef)?v1:
					(v3==undef)?v1*10+v2:
					v1*100+v2*10+v3
			)
			qr_bitfield(val, len)
		]
	);

/*
 * qr_aphanumeric - encode alpha-numeric string in quick response
 *   alphanumeric mode
 *
 * string - alphanumeric string to encode
 *
 */
function qr_alphanum(string) = (len(string)==undef)?undef:
	let (val=search(string, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"))
		concat (
			[qr_alphanum_mode(), qr_bitfield(len(val),9)],
			[
				for (i = [0:2:len(val)-1])
					let(
						l=(val[i+1]==undef)?6:11,
						v=(val[i+1]==undef)?val[i]:
							45*val[i]+val[i+1]
					)
						qr_bitfield(v, l)
			]
		);

/*
 * quick_response - Generate a Quick Response symbol
 *
 * bytes - data bytes to encode
 *
 * ecc_level - determines ratio of ecc:data bytes
 *   0=Low, 1=Mid, 2=Quality, 3=High
 * mask - mask pattern applied on data/ecc bytes
 *   0=checkerboard (fine),
 *   1=rows,
 *   2=columns,
 *   3=diagonals,
 *   4=checkerboard (coarse),
 *   5=* tiles,
 *   6=<> tiles,
 *   7=bowties
 *
 * version - specify symbol version explicitly
 * mark - mark representation
 * space - space representation
 * quiet_zone - representation for the quiet zone
 * pullback - reduce each modules size by this amount
 *   (see documentation in bitmap.scad)
 *
 * vector_mode - create a 2D vector drawing instead of 3D extrusion
 * expert_mode - only use this if you are an expert
 * debug - number of codewords to render
 */
module quick_response(bytes, ecc_level=2, mask=0, version=undef,
	mark=1, space=0, quiet_zone=0, pullback=0.003,
	vector_mode=false,
	expert_mode=false, debug=undef)
{
	if ((version!=undef) && (version<1 || version>40))
		echo(str("ERROR: version ", version, " is invalid"));
	if ((ecc_level<0) || (ecc_level>3))
		echo(str("ERROR: ecc_level ", ecc_level, " is invalid"));
	if ((mask<0) || (mask>7))
		echo(str("ERROR: mask ", mask, " is invalid"));

	if (version && version>6)
		echo(str("WARNING: version ", version, " is not implemented"));

	//determining the symbol version to use is somewhat tricky
	//here do to various combinations of expert_mode and
	//explicitly supplied version
	//pre_pad_bytes is only used for the case where neither of
	//these are set and we need to auto-detect the version
	pre_pad_bytes = (!expert_mode && (version==undef))?
		qr_pad(bytes, ecc_level=ecc_level):
		undef;

	props = (expert_mode)?
		qr_get_props_by_total_size(len(bytes)):
		(version==undef)?
			qr_get_props_by_data_size(len(pre_pad_bytes), ecc_level):
			qr_get_props_by_version(version);

	if (props==undef)
		if (expert_mode)
			echo("ERROR: Are you sure you're an expert?");
		else
			echo(str("ERROR: Could not determine symbol properties. ",
				len(bytes), " bytes of data might be an unsupported size."));

	_version=qr_prop_version(props);
	dims=qr_prop_dimension(props);
	align_count=qr_prop_align_count(props);
	size=qr_prop_total_size(props);
	rem_bits=qr_prop_remainder(props);
	data_size=qr_prop_data_size(props, ecc_level);
	
	//echo(str("DEBUG version=", _version, " dims=", dims, " #align=", align_count, " total size=", size, " data size=", data_size, " remainder=", rem_bits));

	data_bytes=(expert_mode)?
		bytes:
		(pre_pad_bytes==undef)?
			qr_ecc(qr_pad(bytes, data_size=data_size),
				version=_version, ecc_level=ecc_level):
			qr_ecc(pre_pad_bytes,
				version=_version, ecc_level=ecc_level);

	//precomputed BCH remainders for the 32 different
	//format codes (BCH 15,5 with poly 1335)
	bch_1335 =
	[
		  0,311,622,857,491,220,901, 690,
		982,737,440,143,573,778, 83, 356,
		667,940,245,450,880,583,286,  41,
		333,122,803,532,166,401,712,1023
	];

	format_ecc=bch_1335[xor(ecc_level,1)*8+mask];
	format_info =
	[
		bit(format_ecc,0),bit(format_ecc,1),bit(format_ecc,2),
		bit(format_ecc,3),bit(format_ecc,4),bit(format_ecc,5),
		bit(format_ecc,6),bit(format_ecc,7),bit(format_ecc,8),
		bit(format_ecc,9),
		bit(mask,0),bit(mask,1),bit(mask,2),
		!bit(ecc_level,0),bit(ecc_level,1),
	];
	//echo(str("DEBUG format info=",format_info));

	//finder pattern
	function finder(M,S) = [
		[M,M,M,M,M,M,M],
		[M,S,S,S,S,S,M],
		[M,S,M,M,M,S,M],
		[M,S,M,M,M,S,M],
		[M,S,M,M,M,S,M],
		[M,S,S,S,S,S,M],
		[M,M,M,M,M,M,M],
	];

	//alignment pattern
	function alignment(M,S) = [
		[M,M,M,M,M],
		[M,S,S,S,M],
		[M,S,M,S,M],
		[M,S,S,S,M],
		[M,M,M,M,M],
	];

	//codeword styles
	cw_box = 0; //regular box codeword
	cw_u_box = 1; //u-shaped box turnaround
	cw_l_box = 2; //irregular box turnaround
	cw_skew = 3; //skewed codeword (z-shaped)
	cw_l_skew = 4; //irregular skewed turnaround
	cw_skirt = 5; //box cw that skirts alignment pattern
	cw_rem7 = 6; //remainder 7-space pattern

	//convert the byte value x to a 2D bool array with a shape
	//dictated by the style parameter
	//the codeword array returned is facing in the "up" direction
	//reverse the order of the rows for the "down" direction
	function codeword(x, style=0) =
	(style==cw_box)?
	[
		[bit(x,0), bit(x,1)],
		[bit(x,2), bit(x,3)],
		[bit(x,4), bit(x,5)],
		[bit(x,6), bit(x,7)]
	]:
	(style==cw_u_box)?
	[
		[bit(x,2), bit(x,3), bit(x,4), bit(x,5)],
		[bit(x,0), bit(x,1), bit(x,6), bit(x,7)]
	]:
	(style==cw_l_box)?
	[
		[bit(x,0), bit(x,1), bit(x,2), bit(x,3)],
		[   undef,    undef, bit(x,4), bit(x,5)],
		[   undef,    undef, bit(x,6), bit(x,7)]
	]:
	(style==cw_skew)?
	[
		[   undef, bit(x,0)],
		[bit(x,1), bit(x,2)],
		[bit(x,3), bit(x,4)],
		[bit(x,5), bit(x,6)],
		[bit(x,7),    undef]
	]:
	(style==cw_l_skew)?
	[
		[bit(x,0), bit(x,1), bit(x,2)],
		[   undef, bit(x,3), bit(x,4)],
		[   undef, bit(x,5), bit(x,6)],
		[   undef, bit(x,7),    undef]
	]:
	(style==cw_skirt)?
	[
		[bit(x,0),    undef],
		[bit(x,1),    undef],
		[bit(x,2),    undef],
		[bit(x,3),    undef],
		[bit(x,4), bit(x,5)],
		[bit(x,6), bit(x,7)]
	]:
	(style==cw_rem7)?
	[
		[false,false],
		[false,false],
		[false,false],
		[false,undef]
	]:
	undef;

	//dimensions for each codeword style
	function codeword_size(style=0) =
		(style==cw_box)?[2,4]:
		(style==cw_u_box)?[4,2]:
		(style==cw_l_box)?[4,3]:
		(style==cw_skew)?[2,5]:
		(style==cw_l_skew)?[3,4]:
		(style==cw_skirt)?[2,6]:
		(style==cw_rem7)?[2,4]:
		undef;

	//offset applied to next codeword in order
	//to nest it into the gap in the current style
	function nest_factor(style=0, dir=0) =
		(style==cw_u_box)?[2,0]:
		(style==cw_l_box)?[2,-1]:
		(style==cw_skew)?[0,dir?1:-1]:
		(style==cw_l_skew)?[1,dir?-1:0]:
		[0,0];

	//return the distance to the edge of the symbol
	//(or the finder/format patterns)
	function collision_dist(x, y, dir) =
		(dir==1)? //going down
			(x<9)?
				(y-8)
			: // x>=9
				(y-0)
		: // going up
			(x<9)?
				(dims-9-y)
			:(x>=dims-8)?
				(dims-9-y)
			: // 9 <= x < dims-8
				(dims-y);

	//check for split of the symbol across the
	//upper, horizontal clock track
	function horiz_clock_split(y, height, dir) =
		((y<(dims-7)) && (y+height>(dims-7)))?
			height-((dims-7)-y+dir):undef;

	//check for split of the symbol across the alignment pattern
	function align_split(x, y, height, dir) =
		(align_count>0)?
			((x>=dims-9) && (x<dims-4))?
				(dir==0)?
					((y<=4) && (y+height>4))?
						4-y:undef:
				//dir==1
					((y<9) && (y+height>4))?
						9-y:undef:
			undef:
			undef;

	//check for split of the symbol across the
	//left, vertical clock track
	function vert_clock_split(x, width) =
		((x<=6) && (x+width>6))?
			(6-x+1):undef;

	//check whether the current position collides
	//with the format pattern in the lower-left
	function check_format_skirt(x, y, width) =
		(y<8)?
			(x==8)?1:
			(x==7)?2:0:
			0;

	//check whether the current symbol collides with
	//the alignment pattern and has to skirt it
	//rather than split it
	//returns style if no skirt is needed
	function check_align_skirt(x, y, style, dir) =
		(align_count > 0)?
			let(height=codeword_size(style).y)
				((x==dims-10) && (dir==0))?
					(y==8)?cw_skew:
					((y<=4) && (y+height>4))?
						cw_skirt:style:
				((x==dims-5) && (dir==1))?
					(y==4)?cw_skew:
					((y<9) && (y+height>4))?
						cw_skirt:style:
				style:
			style;

	//calculate the masked value of bit b
	//at position x,y
	function mask_bit(b, x, y) =
		(b==undef)?undef:
		let(_y=dims-y-1) (
			(mask==0)?(x+_y)%2:
			(mask==1)?_y%2:
			(mask==2)?x%3:
			(mask==3)?(x+_y)%3:
			(mask==4)?(floor(x/3) + floor(_y/2))%2:
			(mask==5)?(x*_y)%2+(x*_y)%3:
			(mask==6)?((x*_y)%2+(x*_y)%3)%2:
			(mask==7)?((x+_y)%2+(x*_y)%3)%2:
			true)?b:!b;

	//run the 2d bitmap, bm, through the mask
	//process and then draw it at the desired x,y
	//position using the 2dbitmap module
	module masked_bitmap(bm, x, y) {
		rows=len(bm)-1;
		cooked = [
			for (i=[0:rows]) [
				for (j=[0:len(bm[i])-1])
					let (b=mask_bit(bm[i][j],x+j,y+rows-i))
						(b==true)?mark:
						(b==false)?space:
						undef
				]
			];
		translate([x,y])
			2dbitmap(cooked, pullback=pullback, vector_mode=vector_mode);
	}

	//draw individual codewords from bytes array
	//this module is called recursively with i, x, and y
	//iterating across the data region of the symbol
	module quick_response_inner(bytes, i=0, x=undef, y=0, dir=0, _mode=cw_box)
	{
		//echo(str("DEBUG x=", x, " y=", y, " dir=", dir, " mode=", mode, " val=", bytes[i]));

		//check for skirt around alignment pattern
		mode=check_align_skirt(x, y, _mode, dir);

		//check for splits around the vertical clock
		//track and format pattern
		s=codeword_size(mode);
		vcs=vert_clock_split(x, s.x);
		fc=check_format_skirt(x, y);
		vsplit=(vcs!=undef)?vcs:(fc)?fc:undef;

		//check for splits around the horizontal clock
		//track and alignment pattern
		hcs=horiz_clock_split(y, s.y, dir);
		as=align_split(x, y, s.y, dir);
		hsplit=(hcs!=undef)?hcs:(as!=undef)?as:undef;

		xadj=(vcs!=undef)?-1:0;
		yadj=(hcs!=undef)?(dir)?-1:1:
			(as!=undef)?(dir)?-5:5:
			(fc)?8:0;

		//if (vsplit!=undef) echo(str("DEBUG vsplit=",vsplit," xadj=",xadj));
		//if ((hsplit!=undef) || (yadj)) echo(str("DEBUG hsplit=",hsplit," yadj=",yadj));

		//get the codeword array (reversing rows if needed)
		cw=let(_cw=codeword(bytes[i], mode))
			(dir==0)?_cw:
			[for (i=[s.y-1:-1:0]) _cw[i]];

		if (hsplit && (hsplit!=s.y)) {
			//upper half
			cw1=[for (i=[0:hsplit-1]) cw[i]];
			masked_bitmap(cw1, x, y+yadj+(s.y-hsplit)+(dir?-yadj:0));
			//lower half
			cw2=[for (i=[hsplit:s.y-1]) cw[i]];
			masked_bitmap(cw2, x, y+(dir?yadj:0));
		} else if (vsplit && (vsplit!=s.x)) {
			//left half
			cw1=[for (row=cw) [for (i=[0:vsplit-1]) row[i]]];
			masked_bitmap(cw1, x+xadj, y+yadj);
			//right half
			cw2=[for (row=cw) [for (i=[vsplit:s.x-1]) row[i]]];
			masked_bitmap(cw2, x+vsplit, y+(fc?0:yadj));
		} else {
			masked_bitmap(cw, x+xadj, y+yadj);
		}

		//for debugging purposes, we might want to only render
		//n codewords so that it is easier to check the glyph
		//as it is generated or column-by-column
		render_len=(debug==undef)?
			(size-(rem_bits?0:1)):
			debug-1;
		if (i<render_len) {
			//echo(str("DEBUG dist=", dist, " reverse=",reverse_dir, " nest=", nest));
			newi=i+1;
			dist=collision_dist(x, ((dir)?y:y+s.y)+yadj, dir);
			nest=nest_factor(mode, dir);
			//determine next steps based on current mode and dist
			reverse_dir=(dist<=0);
			newdir=(reverse_dir)?(dir?0:1):dir;
			newmode =
				(newi==size)?
					(rem_bits==7)?cw_rem7:
					undef:
				(mode==cw_box)?
					(dist==2)?cw_u_box:
					(dist==3)?cw_l_box:
					mode:
				(mode==cw_l_box)?cw_box:
				(mode==cw_u_box)?cw_box:
				(mode==cw_skirt)?cw_skew:
				(mode==cw_skew)?
					(dist==3)?cw_l_skew:
					mode:
				(mode==cw_l_skew)?cw_skew:
				mode;
			news=codeword_size(newmode);
			newx=x+xadj+nest.x-news.x+(reverse_dir?0:s.x);
			newy=y+yadj+nest.y+(
					reverse_dir?
						(dir?-s.y+news.y:-news.y+s.y):
						(dir?-news.y:s.y)
					);
			quick_response_inner(bytes, i=newi, x=newx, y=newy,
				dir=newdir, _mode=newmode);
		}
	}

	//draws the format patterns around the edge
	//of the finder patterns
	module format_patterns() {
		//bit n of format info
		function fi(n) =
			((n==1) || (n==4) || (n==10) || (n==12) || (n==14))?
				format_info[n]?space:mark:
				format_info[n]?mark:space;

		//format chunk 1
		translate([8,dims-6])
			2dbitmap(
				[
					[fi(0)],
					[fi(1)],
					[fi(2)],
					[fi(3)],
					[fi(4)],
					[fi(5)]
				],
				pullback=pullback, vector_mode=vector_mode);

		//format chunk 2
		translate([7,dims-9])
			2dbitmap(
				[
					[undef,fi(6)],
					[fi(8),fi(7)]
				],
				pullback=pullback, vector_mode=vector_mode);

		//format chunk 3
		translate([0,dims-9])
			2dbitmap(
				[
					[fi(14),fi(13),fi(12),fi(11),fi(10),fi(9)]
				],
				pullback=pullback, vector_mode=vector_mode);

		//format chunk 4
		translate([dims-8,dims-9])
			2dbitmap(
				[
					[fi(7),fi(6),fi(5),fi(4),fi(3),fi(2),fi(1),fi(0)]
				],
				pullback=pullback, vector_mode=vector_mode);

		//format chunk 5
		translate([8,0])
			2dbitmap(
				[
					[mark],
					[fi(8)],
					[fi(9)],
					[fi(10)],
					[fi(11)],
					[fi(12)],
					[fi(13)],
					[fi(14)]
				],
				pullback=pullback, vector_mode=vector_mode);
	}

	//draw the symbol
	translate([4,4])
	{
		//draw the data region
		quick_response_inner(data_bytes, x=dims-2);

		//draw the finder patterns
		2dbitmap(finder(mark, space), pullback=pullback,
			vector_mode=vector_mode);
		translate([0,7])
			2dbitmap([[for (i=[0:7]) space]], pullback=pullback,
				vector_mode=vector_mode);
		translate([7,0])
			2dbitmap([for (i=[0:6]) [space]], pullback=pullback,
				vector_mode=vector_mode);
		translate([0,dims-7])
			2dbitmap(finder(mark, space), pullback=pullback,
				vector_mode=vector_mode);
		translate([0,dims-8])
			2dbitmap([[for (i=[0:7]) space]], pullback=pullback,
				vector_mode=vector_mode);
		translate([7,dims-7])
			2dbitmap([for (i=[0:6]) [space]], pullback=pullback,
				vector_mode=vector_mode);
		translate([dims-7,dims-7])
			2dbitmap(finder(mark, space), pullback=pullback,
				vector_mode=vector_mode);
		translate([dims-8,dims-8])
			2dbitmap([[for (i=[0:7]) space]], pullback=pullback,
				vector_mode=vector_mode);
		translate([dims-8,dims-7])
			2dbitmap([for (i=[0:6]) [space]], pullback=pullback,
				vector_mode=vector_mode);

		//draw the clock track
		translate([6,8])
			2dbitmap([for (i=[0:dims-17]) [(i%2)?space:mark]],
				pullback=pullback, vector_mode=vector_mode);
		translate([8,dims-7])
			2dbitmap([[for (i=[0:dims-17]) (i%2)?space:mark]],
				pullback=pullback, vector_mode=vector_mode);

		//draw the alignment pattern
		if (align_count)
			translate([dims-9,4])
				2dbitmap(alignment(mark, space), pullback=pullback,
					vector_mode=vector_mode);

		//draw the quiet zone
		translate([0,dims])
			2dbitmap([for (i=[0:3]) [for (j=[0:dims-1]) quiet_zone]],
				vector_mode=vector_mode);
		translate([-4,-4])
			2dbitmap([for (i=[0:dims+7]) [for (j=[0:3]) quiet_zone]],
				vector_mode=vector_mode);
		translate([0,-4])
			2dbitmap([for (i=[0:3]) [for (j=[0:dims-1]) quiet_zone]],
				vector_mode=vector_mode);
		translate([dims,-4])
			2dbitmap([for (i=[0:dims+7]) [for (j=[0:3]) quiet_zone]],
				vector_mode=vector_mode);

		//draw the format patterns
		format_patterns();
	}
}

/* Examples */
example=2;
//example 0 - unconfirmed validity - test for numeric mode and alphanum mode (also sets vector_mode for 2D rendering test)
//example 1 - Version 1, Mask 1, ECC High - From https://en.wikipedia.org/wiki/File:Qr-1.png
//example 2 - Version 2, Mask 2, ECC High - From https://en.wikipedia.org/wiki/File:Qr-2.png
//example 3 - Version 3, Mask 1, ECC High - From https://en.wikipedia.org/wiki/File:Qr-3.png
//example 4 - Version 4, Mask 6, ECC High - From https://en.wikipedia.org/wiki/File:Qr-4.png
//example 5 - Version 5, Mask 7, ECC Low  - From https://en.wikipedia.org/wiki/File:Japan-qr-code-billboard.jpg
//example 6 - Version 6, Mask 4, ECC Qual - From https://commons.wikimedia.org/wiki/File:Qr_code-Main_Page_en.svg
//example 7 - Version 3, Mask 7, ECC Low  - From https://en.wikipedia.org/wiki/File:QRCode-1-Intro.png
//example 8 - Version 4, Mask 2, ECC Low  - From https://commons.wikimedia.org/wiki/File:Qrcode-WikiCommons-app-iOS.png
//example 9 - Version 5/6, Mask 3, ECC High - From https://commons.wikimedia.org/wiki/File:QR_code_on_oBike.jpg

if (example==0)
	quick_response(
		concat(
			qr_alphanum("+ASDF://$ %"),
			qr_numeric([7,9,1,4,5])
		),
		mark="black",
		vector_mode=true);

if (example==1)
	quick_response(
		qr_bytes(ascii_to_vec("Ver1")),
		mask=1, ecc_level=3,
		mark="black");

if (example==2)
	quick_response(
		qr_bytes(ascii_to_vec("Version 2")),
		mask=2, ecc_level=3,
		mark="black");

if(example==3)
	quick_response(
		qr_bytes(ascii_to_vec("Version 3 QR Code")),
		mask=1, ecc_level=3,
		mark="black");

if(example==4)
	quick_response(
		qr_bytes(ascii_to_vec("Version 4 QR Code, up to 50 char")),
		mask=6, ecc_level=3,
		mark="black");

if (example==5)
	quick_response(
		qr_bytes(
			concat(
				ascii_to_vec("http://sagasou.mobi \r\n\r\nMEBKM:TITLE:"),
				[ //shift-jis encoded string "探そうモビで専門学校探し！"
					146,84,
					130,187,
					130,164,
					131,130,
					131,114,
					130,197,
					144,234,
					150,229,
					138,119,
					141,90,
					146,84,
					130,181,
					129,73
				],
				ascii_to_vec(";URL:http\\://sagasou.mobi;;")
			)
		),
		mask=7, ecc_level=0,
		mark="black");

// This example has some strange white-space characters and inverted
// remainder pattern.
if (example==6)
	quick_response(
		qr_bytes(ascii_to_vec("Welcome to Wikipedia,\r\nthe free encyclopedia \r\nthat anyone can edit.")),
		mask=4, ecc_level=2,
		mark="black");

if (example==7)
	quick_response(
		qr_bytes(ascii_to_vec("Mr. Watson, come here - I want to see you.")),
		mask=7, ecc_level=0,
		mark="black");

// This example has some shift-JIS encoded characters in the middle
// of the string.
// Since byte-mode is being used without an ECI directive, I suspect
// that the proper interpretation of the symbol will depend on the
// particular scanner software being used.
if (example==8)
	quick_response(
		concat(
			qr_bytes(ascii_to_vec(
				"https://itunes.apple.com/us/app/wikimedia-commons/id")),
			qr_numeric([6,3,0,9,0,1,7,8,0]),
			qr_bytes(ascii_to_vec("?mt=8"))
		),
		mask=2, ecc_level=0,
		mark="black");

// This example is mirrored and is actually short enough to be
// version 5. Presumably, they force it to be version 6 in order to
// future-proof their serial number.
if (example==9)
	mirror([1,0,0])
	quick_response(
		concat(
			qr_bytes(ascii_to_vec("http://www.o.bike/download/app.html?m=")),
			qr_numeric([8,8,6,5,0,8,5,4,7])
		),
		mask=3, ecc_level=3, version=6,
		mark="black");
