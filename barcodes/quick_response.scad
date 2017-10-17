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
 * - util/bitlib.scad
 * - util/bitmap.scad
 * - util/quick_response-util.scad
 *   - util/reed-solomon-quick_response.scad
 *     - util/bitlib.scad
 *
 * API:
 *   quick_response(bytes, version=1, ecc_level=2, mask=0,
 *     mark=1, space=0, quiet_zone=0)
 *     TODO
 *
 * TODO:
 * - ECC block interleaving
 * - Data encoding
 * - Determine symbol version automatically
 * - Larger sizes
 *
 *****************************************************************************/
use <../util/bitlib.scad>
use <../util/bitmap.scad>
use <../util/quick_response-util.scad>

/*
 * quick_response - Generate a Quick Response symbol
 *
 * bytes - data bytes to encode
 *
 * version - 1..40 - determines symbol size
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
 * mark - mark representation
 * space - space representation
 * quiet_zone - representation for the quiet zone
 *   (see documentation in bitmap.scad)
 */
module quick_response(bytes, version=1, ecc_level=2, mask=0, mark=1, space=0, quiet_zone=0)
{
	if ((version<1) || (version>40))
		echo(str("ERROR: version ", version, " is invalid"));
	if ((ecc_level<0) || (ecc_level>3))
		echo(str("ERROR: ecc_level ", ecc_level, " is invalid"));
	if ((mask<0) || (mask>7))
		echo(str("ERROR: mask ", mask, " is invalid"));

	if (version>6)
		echo(str("WARNING: version ", version, " is not implemented"));

	props=qr_get_props_by_version(version);
	dims=qr_prop_dimension(props);
	align_count=qr_prop_align_count(props);
	size=qr_prop_total_size(props);
	rem_bits=qr_prop_remainder(props);
	
	echo(str("DEBUG version=", version, " dims=", dims, " #align=", align_count, " size=", size, " remainder=", rem_bits));

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
			2dbitmap(cooked);
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

		if (i<(size-(rem_bits?0:1))) {
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
			quick_response_inner(bytes, mark=mark,
				space=space, i=newi, x=newx, y=newy,
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
			2dbitmap([
				[fi(0)],
				[fi(1)],
				[fi(2)],
				[fi(3)],
				[fi(4)],
				[fi(5)]
			]);

		//format chunk 2
		translate([7,dims-9])
			2dbitmap([
				[undef,fi(6)],
				[fi(8),fi(7)]
			]);

		//format chunk 3
		translate([0,dims-9])
			2dbitmap([
				[fi(14),fi(13),fi(12),fi(11),fi(10),fi(9)]
			]);

		//format chunk 4
		translate([dims-8,dims-9])
			2dbitmap([
				[fi(7),fi(6),fi(5),fi(4),fi(3),fi(2),fi(1),fi(0)]
			]);

		//format chunk 5
		translate([8,0])
			2dbitmap([
				[mark],
				[fi(8)],
				[fi(9)],
				[fi(10)],
				[fi(11)],
				[fi(12)],
				[fi(13)],
				[fi(14)]
			]);
	}

	//draw the symbol
	translate([4,4])
	{
		//draw the data region
		quick_response_inner(bytes, x=dims-2);

		//draw the finder patterns
		2dbitmap(finder(mark, space));
		translate([0,7])
			2dbitmap([[for (i=[0:7]) space]]);
		translate([7,0])
			2dbitmap([for (i=[0:6]) [space]]);
		translate([0,dims-7])
			2dbitmap(finder(mark, space));
		translate([0,dims-8])
			2dbitmap([[for (i=[0:7]) space]]);
		translate([7,dims-7])
			2dbitmap([for (i=[0:6]) [space]]);
		translate([dims-7,dims-7])
			2dbitmap(finder(mark, space));
		translate([dims-8,dims-8])
			2dbitmap([[for (i=[0:7]) space]]);
		translate([dims-8,dims-7])
			2dbitmap([for (i=[0:6]) [space]]);

		//draw the clock track
		translate([6,8])
			2dbitmap([for (i=[0:dims-17]) [(i%2)?space:mark]]);
		translate([8,dims-7])
			2dbitmap([[for (i=[0:dims-17]) (i%2)?space:mark]]);

		//draw the alignment pattern
		if (align_count)
			translate([dims-9,4])
				2dbitmap(alignment(mark, space));

		//draw the quiet zone
		translate([0,dims])
			2dbitmap([for (i=[0:3]) [for (j=[0:dims-1]) quiet_zone]]);
		translate([-4,-4])
			2dbitmap([for (i=[0:dims+7]) [for (j=[0:3]) quiet_zone]]);
		translate([0,-4])
			2dbitmap([for (i=[0:3]) [for (j=[0:dims-1]) quiet_zone]]);
		translate([dims,-4])
			2dbitmap([for (i=[0:dims+7]) [for (j=[0:3]) quiet_zone]]);

		//draw the format patterns
		format_patterns();
	}
}

/* Examples */
example=3;
//example 1 - Version 1, Mask 1, ECC High - From https://en.wikipedia.org/wiki/File:Qr-1.png
//example 2 - Version 2, Mask 2, ECC High - From https://en.wikipedia.org/wiki/File:Qr-2.png
//example 3 - Version 3, Mask 7, ECC Low  - From https://en.wikipedia.org/wiki/File:QRCode-1-Intro.png

if (example==1)
	quick_response(
		qr_ecc(
			qr_pad([
				qr_nibble(4), //byte mode
				4,            //length
				86,101,114,49 //ASCII "Ver1"
			], ecc_level=3), //26-{7,10,13,17}
			version=1, ecc_level=3),
		version=1, mask=1, ecc_level=3,
		mark="black");

if (example==2)
	quick_response(
		qr_ecc(
			qr_pad([
				qr_nibble(4), //byte mode
				9,            //length
				86,101,114,   //ASCII "Version 2"
				115,105,111,110,32,50
			], ecc_level=3), //44-{10,16,22,28}
			version=2, ecc_level=3),
		version=2, mask=2, ecc_level=3,
		mark="black");

if (example==3)
	quick_response(
		qr_ecc(
			qr_pad([
				qr_nibble(4), //byte mode
				42,           //length
				//ASCII "Mr. Watson, come here - I want to see you."
				77,114,46,32,87,97,116,115,111,110,44,
				32,99,111,109,101,32,104,101,114,101,
				32,45,32,73,32,119,97,110,116,32,116,
				111,32,115,101,101,32,121,111,117,46
			], ecc_level=0), //70-{15,26,36,44}
			version=3, ecc_level=0),
		version=3, mask=7, ecc_level=0,
		mark="black");
