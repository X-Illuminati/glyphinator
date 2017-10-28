/*****************************************************************************
 * Quick Response Utility Library
 * Provides internal helper interfaces for quick_response.scad
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
 * Depends on the reed-solomon-quick_response.scad library.
 * When run on its own, all echo statements in this library should print
 * "true".
 *
 * API:
 *   qr_pad(data, ecc_level, data_size=undef)
 *     Pad the data vector up to data_size bytes.
 *     Starts with an EOM nibble, compacts other nibbles.
 *     If data_size is left undefined, an appropriate value will be calculated
 *     from data and ecc_level (so ecc_level must be provided in this case).
 *
 *   qr_ecc(data, version, ecc_level)
 *     Calculate and append reed-solomon error correction bytes over the data
 *     byte vector. The number of error correction bytes will be determined
 *     by version and ecc_level.
 *     The len(data) must be a particular size; use qr_pad() to pad up to the
 *     nearest valid size.
 *
 *   qr_get_props_by_version(version)
 *     Get a property vector based on the targetted symbol version.
 *     See getter functions below to interpret this property vector.
 *
 *   qr_get_props_by_data_size(data_size, ecc_level)
 *     Get a property vector based on data_size.
 *     Returns properties appropriate for a symbol that can contain at
 *     least data_size data codewords at ecc_level ECC.
 *     See getter functions below to interpret this property vector.
 *
 *   qr_get_props_by_total_size(total_size)
 *     Get a property vector based on total_size.
 *     Returns properties appropriate for a symbol that has precisely
 *     total_size combined data and ecc codewords.
 *     See getter functions below to interpret this property vector.
 *
 *   qr_nibble(x)
 *     Return value x represented as a 4-bit nibble.
 *
 *   qr_compact_nibbles(data)
 *     Convert the data vector of mixed bytes and nibbles into a vector of
 *     bytes only. If there are an odd number of total nibbles, the final
 *     value in the returned vector will be an unpadded nibble.
 *
 * Getter Functions for Use with Property Vector:
 *   qr_prop_version(properties) - return symbol version
 *   qr_prop_total_size(properties) - return number of total codewords
 *   qr_prop_ecc_size(properties, ecc_level) - return number of ecc codewords
 *   qr_prop_data_size(properties, ecc_level) - return number of data cw
 *   qr_prop_dimension(properties) - return symbol dimension (square)
 *
 * TODO:
 *  - Change echos to asserts (future OpenSCAD version)
 *
 *****************************************************************************/
use <reed-solomon-quick_response.scad>

/*
I'd like to keep all of the constants related to each
quick response symbol version in on spot.
This table is indexed by symbol version.
 - sz: size of symbol (width/height in modules)
 - #a: number of alignment patterns
 - #cw: number of total codewords
 - rem: remainder bits (parital last codeword)
 - #L: number of ecc codewords (level low)
 - #M: number of ecc codewords (level mid)
 - #Q: number of ecc codewords (level quality)
 - #H: number of ecc codewords (level high)
*/
qr_prop_table = [
	/*ver, sz,#a, #cw,rem, #L, #M, #Q,  #H*/
	[   1, 21, 0,  26,  0,  7, 10, 13,  17],
	[   2, 25, 1,  44,  7, 10, 16, 22,  28],
	[   3, 29, 1,  70,  7, 15, 26, 36,  44],
	[   4, 33, 1, 100,  7, 20, 36, 52,  64],
	[   5, 37, 1, 134,  7, 26, 48, 72,  88],
	[   6, 41, 1, 172,  7, 36, 64, 96, 112],
];

/*
 * Property Getter functions
 *
 * properties - one of the rows from the qr_prop_table
 * ecc_level - determines ratio of ecc:data bytes
 *   0=Low, 1=Mid, 2=Quality, 3=High
 */
function qr_prop_version(properties)=properties[0];
function qr_prop_dimension(properties)=properties[1];
function qr_prop_align_count(properties)=properties[2];
function qr_prop_total_size(properties)=properties[3];
function qr_prop_remainder(properties)=properties[4];
function qr_prop_ecc_size(properties, ecc_level)=
	((ecc_level<0) || (ecc_level>3))?undef:
	properties[5+ecc_level];
function qr_prop_data_size(properties, ecc_level)=
	((ecc_level<0) || (ecc_level>3))?undef:
	qr_prop_total_size(properties)-qr_prop_ecc_size(properties, ecc_level);

/*
 * qr_get_props_by_version
 * Return a row from qr_prop_table corresponding to version.
 *
 * version - symbol version
 */
function qr_get_props_by_version(version)=
	qr_prop_table[version-1];

echo("*** qr_get_props_by_version() testcases ***");
echo(qr_get_props_by_version(-1)==undef);
echo(qr_get_props_by_version(0)==undef);
echo(qr_get_props_by_version(1)!=undef);
echo(qr_get_props_by_version(6)!=undef);
echo(qr_get_props_by_version(true)==undef);
echo(qr_get_props_by_version(false)==undef);
echo(qr_get_props_by_version(undef)==undef);
echo(qr_get_props_by_version(7)==undef); //will need adjustment in the future

/*
 * qr_get_props_by_data_size
 * Return a row from qr_prop_table based data size.
 * Recursively looks up the row with (cw-ecc) >= data_size.
 *
 * data_size - number of data codewords
 * ecc_level - determines ratio of ecc:data bytes
 *   0=Low, 1=Mid, 2=Quality, 3=High
 */
function qr_get_props_by_data_size(data_size, ecc_level, i=0) =
	(data_size<0)?undef:
	(data_size==true)?undef:
	(data_size==false)?undef:
	let(p=qr_prop_table[i])
		(p==undef)?undef:
		(qr_prop_data_size(p, ecc_level)>=data_size)?p:
		qr_get_props_by_data_size(data_size, ecc_level, i+1);

echo("*** qr_get_props_by_data_size() testcases ***");
echo(qr_get_props_by_data_size(-1, 0)==undef);
echo(qr_get_props_by_data_size(0, 0)!=undef);
echo(qr_get_props_by_data_size(1, 0)!=undef);
echo(qr_get_props_by_data_size(136, 0)!=undef);
echo(qr_get_props_by_data_size(0, -1)==undef);
echo(qr_get_props_by_data_size(0, 1)!=undef);
echo(qr_get_props_by_data_size(0, 2)!=undef);
echo(qr_get_props_by_data_size(0, 3)!=undef);
echo(qr_get_props_by_data_size(0, 4)==undef);
echo(qr_get_props_by_data_size(true, 0)==undef);
echo(qr_get_props_by_data_size(false, 0)==undef);
echo(qr_get_props_by_data_size(137, 0)==undef); //will need adjustment in the future

/*
 * qr_get_props_by_total_size
 * Return a row from qr_prop_table based total size.
 * Recursively looks up the row with #cw == total_size.
 *
 * total_size - number of total codewords
 */
function qr_get_props_by_total_size(total_size, i=0) =
	(total_size<26)?undef:
	(total_size==true)?undef:
	(total_size==false)?undef:
	let(p=qr_prop_table[i])
		(p==undef)?undef:
		(qr_prop_total_size(p)==total_size)?p:
		qr_get_props_by_total_size(total_size, i+1);

echo("*** qr_get_props_by_total_size() testcases ***");
echo(qr_get_props_by_total_size(-1)==undef);
echo(qr_get_props_by_total_size(0)==undef);
echo(qr_get_props_by_total_size(1)==undef);
echo(qr_get_props_by_total_size(3)==undef);
echo(qr_get_props_by_total_size(26)!=undef);
echo(qr_get_props_by_total_size(29)==undef);
echo(qr_get_props_by_total_size(44)!=undef);
echo(qr_get_props_by_total_size(80)==undef);
echo(qr_get_props_by_total_size(100)!=undef);
echo(qr_get_props_by_total_size(172)!=undef);
echo(qr_get_props_by_total_size(true)==undef);
echo(qr_get_props_by_total_size(false)==undef);
echo(qr_get_props_by_total_size(173)==undef); //will need adjustment in the future

echo("*** qr_prop_version testcases ***");
echo(len(qr_prop_table)==6); //reminder to check results below
for (i=[0:len(qr_prop_table)-1])
	echo(qr_prop_version(qr_prop_table[i])==(i+1));

echo("*** combination testcases ***");
echo(qr_prop_data_size(qr_get_props_by_version(1), 3)==9);
echo(qr_prop_data_size(qr_get_props_by_version(1), 2)==13);
echo(qr_prop_data_size(qr_get_props_by_version(2), 2)==22);
echo(qr_prop_data_size(qr_get_props_by_version(6), 1)==108);
echo(qr_prop_data_size(qr_get_props_by_version(6), 0)==136);
echo(qr_prop_data_size(qr_get_props_by_version(1), -1)==undef);
echo(qr_prop_data_size(qr_get_props_by_version(1), 4)==undef);
echo(qr_prop_data_size(qr_get_props_by_version(1), undef)==undef);
echo(qr_prop_total_size(qr_get_props_by_version(1))==26);
echo(qr_prop_total_size(qr_get_props_by_version(3))==70);
echo(qr_prop_total_size(qr_get_props_by_version(6))==172);
echo(qr_prop_dimension(qr_get_props_by_version(1))==21);
echo(qr_prop_dimension(qr_get_props_by_version(4))==33);
echo(qr_prop_dimension(qr_get_props_by_version(6))==41);
echo(qr_prop_ecc_size(qr_get_props_by_version(1), 0)==7);
echo(qr_prop_ecc_size(qr_get_props_by_version(1), 1)==10);
echo(qr_prop_ecc_size(qr_get_props_by_version(5), 2)==72);
echo(qr_prop_ecc_size(qr_get_props_by_version(6), 2)==96);
echo(qr_prop_ecc_size(qr_get_props_by_version(6), 3)==112);
echo(qr_prop_ecc_size(qr_get_props_by_version(1), -1)==undef);
echo(qr_prop_ecc_size(qr_get_props_by_version(1), 4)==undef);
echo(qr_prop_ecc_size(qr_get_props_by_version(1), undef)==undef);
echo(qr_prop_data_size(qr_get_props_by_data_size(19,0), 0)==19);
echo(qr_prop_data_size(qr_get_props_by_data_size(44,1), 1)==44);
echo(qr_prop_data_size(qr_get_props_by_data_size(48,2), 2)==48);
echo(qr_prop_data_size(qr_get_props_by_data_size(46,3), 3)==46);
echo(qr_prop_data_size(qr_get_props_by_data_size(60,3), 3)==60);
echo(qr_prop_total_size(qr_get_props_by_data_size(13,2))==26);
echo(qr_prop_total_size(qr_get_props_by_data_size(26,3))==70);
echo(qr_prop_total_size(qr_get_props_by_data_size(136,0))==172);
echo(qr_prop_dimension(qr_get_props_by_data_size(16,1))==21);
echo(qr_prop_dimension(qr_get_props_by_data_size(34,0))==25);
echo(qr_prop_dimension(qr_get_props_by_data_size(76,2))==41);
echo(qr_prop_ecc_size(qr_get_props_by_data_size(9,3), 3)==17);
echo(qr_prop_ecc_size(qr_get_props_by_data_size(16,3), 3)==28);
echo(qr_prop_ecc_size(qr_get_props_by_data_size(34,2), 2)==36);
echo(qr_prop_ecc_size(qr_get_props_by_data_size(36,3), 3)==64);
echo(qr_prop_ecc_size(qr_get_props_by_data_size(108,1), 1)==64);
echo(qr_prop_data_size(qr_get_props_by_total_size(26), 1)==16);
echo(qr_prop_data_size(qr_get_props_by_total_size(26), 3)==9);
echo(qr_prop_data_size(qr_get_props_by_total_size(70), 2)==34);
echo(qr_prop_data_size(qr_get_props_by_total_size(172), 0)==136);
echo(qr_prop_data_size(qr_get_props_by_total_size(172), 3)==60);
echo(qr_prop_total_size(qr_get_props_by_total_size(26))==26);
echo(qr_prop_total_size(qr_get_props_by_total_size(70))==70);
echo(qr_prop_total_size(qr_get_props_by_total_size(100))==100);
echo(qr_prop_total_size(qr_get_props_by_total_size(172))==172);
echo(qr_prop_dimension(qr_get_props_by_total_size(26))==21);
echo(qr_prop_dimension(qr_get_props_by_total_size(134))==37);
echo(qr_prop_dimension(qr_get_props_by_total_size(172))==41);
echo(qr_prop_ecc_size(qr_get_props_by_total_size(26), 0)==7);
echo(qr_prop_ecc_size(qr_get_props_by_total_size(26), 2)==13);
echo(qr_prop_ecc_size(qr_get_props_by_total_size(44), 2)==22);
echo(qr_prop_ecc_size(qr_get_props_by_total_size(172), 1)==64);
echo(qr_prop_ecc_size(qr_get_props_by_total_size(172), 3)==112);
echo(qr_prop_version(qr_get_props_by_total_size(26))==1);
echo(qr_prop_version(qr_get_props_by_total_size(100))==4);
echo(qr_prop_version(qr_get_props_by_total_size(172))==6);

/*
 * qr_nibble
 * Encode a value as a nibble.
 *
 * Within this framework most values represent bytes.
 * However, it is sometimes necessary to indicate a
 * 4-bit value. I am encoding these as negative numbers.
 * -16 is a special case since there is no -0.
 */
function qr_nibble(x) = (x==0)?-16:-x;

//Split a byte into [high nibble, low nibble]
//If it is already a nibble return it as [nibble].
function qr_byte2nibbles(x) =
	(x==undef)?undef:
	(x<0)?[x]: //already a nibble
	[qr_nibble(floor(x/16)),qr_nibble(x%16)];

//Combine 2 nibbles into a byte value
//a is high nibble, b is low nibble
function qr_nibbles2byte(a,b) =
	let(
		v1 =
			(a==undef)?0:
			(a==-16)?0:
			-a,
		v2 =
			(b==undef)?0:
			(b==-16)?0:
			-b
		) v1*16+v2;

/*
 * qr_compact_nibbles
 * Take a vector of mixed bytes and nibbles and compact it
 * down into a vector of only bytes.
 * If there are an odd number of total nibbles, the final
 * value in the returned vector will be an unpadded nibble.
 *
 * data - data vector composed of mixed byte values
 *   and negative nibble values created with qr_nibble()
 */
function qr_compact_nibbles(data, i=0, carry=0) =
	(i>=len(data))? //terminate recursion
		carry?[carry]:[]:
	(carry)? // carry-in nibble
		let(
			next=qr_byte2nibbles(data[i]),
			remainder=(len(next)==2)?next[1]:undef,
			value=qr_nibbles2byte(carry, next[0])
		) concat(value, qr_compact_nibbles(data, i+1, remainder)):
	(data[i]<0)? //data[i] is a nibble
		let(
			next=qr_byte2nibbles(data[i+1]),
			remainder=(len(next)==2)?next[1]:undef,
			value=(undef==next)?data[i]:qr_nibbles2byte(data[i], next[0])
		) concat(value, qr_compact_nibbles(data, i+2, remainder)):
	// else - data[i] is already a byte and no carry-in
	concat(data[i], qr_compact_nibbles(data,i+1));

echo("*** qr_compact_nibbles() testcases ***");
echo(qr_compact_nibbles([0])==[0]); //0x00
echo(qr_compact_nibbles([qr_nibble(8)])==[qr_nibble(8)]); //0x8.
echo(qr_compact_nibbles([qr_nibble(8), qr_nibble(1)])==[129]); //0x81
echo(qr_compact_nibbles([qr_nibble(0), 70, 4, 51, qr_nibble(3)])==[4,96,67,51]); //0x04604333
echo(qr_compact_nibbles([70, 4, 51, qr_nibble(3)])==[70, 4, 51, qr_nibble(3)]); //0x4604333.
echo( //0x0462F04.
	qr_compact_nibbles(
		[qr_nibble(0), 70, qr_nibble(2), qr_nibble(15), 4])
	==[4,98,240,qr_nibble(4)]);
echo( //0x00046233F04.
	qr_compact_nibbles(
		[0, qr_nibble(0), 70, qr_nibble(2), 51, qr_nibble(15), 4])
	==[0,4,98,51,240,qr_nibble(4)]);
echo( //0x0004623F0433
	qr_compact_nibbles(
		[0, qr_nibble(0), 70, qr_nibble(2), qr_nibble(3), qr_nibble(15), 4, 51])
	==[0,4,98,63,4,51]);
echo( //0x146330C204172F
	qr_compact_nibbles(
		[qr_nibble(1), 70, 51, 12, qr_nibble(2), 4, 23, 47])
	==[20,99,48,194,4,23,47]);

EOM=qr_nibble(0);

/*
 * qr_pad - pad a qr_nibble/byte vector up to an expected size
 *
 * data - the vector of initial data

 * ecc_level - determines ratio of ecc:data bytes
 *   0=Low, 1=Mid, 2=Quality, 3=High
 * data_size - (optional) the size to pad the data vector up to
 *   if left undefined, a value will be calculated from data
 *
 * ecc_level must be provided unless data_size is provided
 * returns undef if the length of the data ends up being > data_size
 */
function qr_pad(data, ecc_level, data_size=undef) =
	((ecc_level==undef) && (data_size==undef))?undef:
	let(d=qr_compact_nibbles(
			//check whether data already ends with EOM
			(data[len(data)-1]==EOM)?
				data:
				concat(data,[EOM])),
		s=len(d),
		//determine number of data codewords
		dcw=(data_size!=undef)?
			data_size: //use data_size if provided
			qr_prop_data_size(
				qr_get_props_by_data_size(
					(d[s-1]==EOM)?s-1:s, //final EOM byte is optional
					ecc_level), ecc_level)
	)
		(dcw==undef)?undef: //lookup failure
		((s==dcw+1)&&(d[s-1]==EOM))? //special case - EOM unneeded
			[for (i=[0:s-2]) d[i]]:
		(s>dcw)?undef: //too long
		let(offset=s%2) [
			for (i=[0:dcw-1])
				((i==s-1)&&(d[i]<0))?
					qr_nibbles2byte(d[i],undef):
				(i<s)?d[i]:
				((i-s)%2==0)?236:17
		];

echo("*** qr_pad() testcases ***");
echo(qr_pad([1,2,3,4,5],data_size=4)==undef);
echo(qr_pad([1,2,3,4,5],0,data_size=4)==undef);
echo(qr_pad([0,qr_nibble(1),2,qr_nibble(3),4,qr_nibble(5)],data_size=4)
	==undef);
echo(qr_pad([0])==undef);
echo(qr_pad([0],0,4)==[0,0,236,17]);
echo(qr_pad([for (i=[0:137]) i],0)==undef);

echo(qr_pad([],data_size=10)==[0,236,17,236,17,236,17,236,17,236]);
echo(qr_pad([1],data_size=10)==[1,0,236,17,236,17,236,17,236,17]);
echo(qr_pad([1,2],data_size=10)==[1,2,0,236,17,236,17,236,17,236]);
echo(qr_pad([1,2,3],data_size=10)==[1,2,3,0,236,17,236,17,236,17]);
echo(qr_pad([1,2,3,4],data_size=10)==[1,2,3,4,0,236,17,236,17,236]);
echo(qr_pad([1,2,3,4,5,6,7,8],data_size=10)==[1,2,3,4,5,6,7,8,0,236]);
echo(qr_pad([1,2,3,4,5,6,7,8,9],data_size=10)==[1,2,3,4,5,6,7,8,9,0]);
echo(qr_pad([1,2,3,4,5,6,7,8,9,10],data_size=10)==[1,2,3,4,5,6,7,8,9,10]);

echo(qr_pad([qr_nibble(0),1,2,3,qr_nibble(4)],data_size=4)==[0,16,32,52]);
echo(qr_pad([qr_nibble(0),1,2,3,qr_nibble(4)],data_size=5)
	==[0,16,32,52,0]);
echo(qr_pad([qr_nibble(0),1,2,3,qr_nibble(4)],data_size=6)
	==[0,16,32,52,0,236]);
echo(qr_pad([qr_nibble(0),1,2,3,qr_nibble(4)],data_size=7)
	==[0,16,32,52,0,236,17]);
echo(qr_pad([qr_nibble(0),1,2,3,qr_nibble(4)],data_size=8)
	==[0,16,32,52,0,236,17,236]);
echo(qr_pad([qr_nibble(1),2,qr_nibble(3),4,qr_nibble(5)],data_size=4)
	==[16,35,4,80]);
echo(qr_pad([qr_nibble(1),2,qr_nibble(3),4,qr_nibble(5)],data_size=5)
	==[16,35,4,80,236]);
echo(qr_pad([qr_nibble(1),2,qr_nibble(3),4,qr_nibble(5)],data_size=6)
	==[16,35,4,80,236,17]);
echo(qr_pad([qr_nibble(1),2,qr_nibble(3),4,qr_nibble(5)],data_size=7)
	==[16,35,4,80,236,17,236]);

echo(qr_pad([1,2,3,4,5,6,7,8,9], 3)==[1,2,3,4,5,6,7,8,9]);
echo(qr_pad([1,2,3,4,5,6,7,8,9,10], 3)
	==[1,2,3,4,5,6,7,8,9,10,0,236,17,236,17,236]);
echo(qr_pad([1,2,3,4,5,6,7,8,9,10,11,12,13], 2)
	==[1,2,3,4,5,6,7,8,9,10,11,12,13]);
echo(qr_pad([1,2,3,4,5,6,7,8,9,10,11,12,13,14], 2)
	==[1,2,3,4,5,6,7,8,9,10,11,12,13,14,0,236,17,236,17,236,17,236]);
echo(qr_pad([qr_nibble(1),1,2,3,4,5,6,7,8], 3)
	==[16,16,32,48,64,80,96,112,128]);
echo(qr_pad([qr_nibble(1),1,2,3,4,5,6,7,8,9], 3)
	==[16,16,32,48,64,80,96,112,128,144,236,17,236,17,236,17]);
echo(qr_pad([qr_nibble(1),1,2,3,4,5,6,7,8,9,10,11,12], 2)
	==[16,16,32,48,64,80,96,112,128,144,160,176,192]);
echo(qr_pad([qr_nibble(1),1,2,3,4,5,6,7,8,9,10,11,12,13], 2)==[16,16,32,48,64,80,96,112,128,144,160,176,192,208,236,17,236,17,236,17,236,17]);

/*
 * qr_ecc - append reed-solomon error correction bytes
 *
 * data - the vector of data bytes
 * version - 1..40 - determines symbol size
 * ecc_level - determines ratio of ecc:data bytes
 *   0=Low, 1=Mid, 2=Quality, 3=High
 */
function qr_ecc(data, version, ecc_level=2) =
	let(p=qr_get_props_by_version(version),
		dcw=qr_prop_data_size(p, ecc_level),
		ecw=qr_prop_ecc_size(p, ecc_level))
		(ecw==undef || dcw==undef || dcw!=len(data))?undef:
		concat(data,rs285_ecc(data,dcw,ecw));

echo("*** qr_ecc() testcases ***");
echo(qr_ecc()==undef);
echo(qr_ecc([10,20])==undef);
echo(qr_ecc([10,20], version=1, ecc_level=4)==undef);
echo(qr_ecc([10,20], version=1)==undef);
echo(qr_ecc([64,69,102,87,35,16,236,17,236], version=1, ecc_level=3)
	==[64,69,102,87,35,16,236,17,236,150,106,201,175,226,23,128,154,76,96,209,69,45,171,227,182,8]);
