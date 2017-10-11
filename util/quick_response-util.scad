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
 * When run on its own, all echo statements in this library should print
 * "true".
 *
 * API:
 *   qr_nibble(x)
 *     Return value x represented as a 4-bit nibble.
 *
 *   qr_compact_nibbles(data)
 *     Convert the data vector of mixed bytes and nibbles into a vector of
 *     bytes only. If there are an odd number of nibbles, a final 0 nibble
 *     will be appended to the end to pad out the final byte.
 *
 *   qr_get_props_by_version(version)
 *     Get a property vector based on the targetted symbol version.
 *     See getter functions below to interpret this property vector.
 *
 * Getter Functions for Use with Property Vector:
 *   qr_prop_total_size(properties) - return number of total codewords
 *   qr_prop_ecc_size(properties, ecc_level) - return number of ecc codewords
 *   qr_prop_data_size(properties, ecc_level) - return number of data cw
 *   qr_prop_dimension(properties) - return symbol dimension (square)
 *
 * TODO:
 *  - Change echos to asserts (future OpenSCAD version)
 *
 *****************************************************************************/

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
	/*ver- sz,#a, #cw,rem, #L, #M, #Q,  #H*/
	[/*1*/ 21, 0,  26,  0,  7, 10, 13,  17],
	[/*2*/ 25, 1,  44,  7, 10, 16, 22,  28],
	[/*3*/ 29, 1,  70,  7, 15, 26, 36,  44],
	[/*4*/ 33, 1, 100,  7, 20, 36, 52,  64],
	[/*5*/ 37, 1, 134,  7, 26, 48, 72,  88],
	[/*6*/ 41, 1, 172,  7, 36, 64, 96, 112],
];

/*
 * Property Getter functions
 *
 * properties - one of the rows from the qr_prop_table
 * ecc_level - determines ratio of ecc:data bytes
 *   0=Low, 1=Mid, 2=Quality, 3=High
 */
function qr_prop_dimension(properties)=properties[0];
function qr_prop_align_count(properties)=properties[1];
function qr_prop_total_size(properties)=properties[2];
function qr_prop_remainder(properties)=properties[3];
function qr_prop_ecc_size(properties, ecc_level)=
	((ecc_level<0) || (ecc_level>3))?undef:
	properties[4+ecc_level];
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

echo("*** combination testcases ***");
echo(qr_prop_data_size(qr_get_props_by_version(1),3)==9);
echo(qr_prop_data_size(qr_get_props_by_version(1),2)==13);
echo(qr_prop_data_size(qr_get_props_by_version(2),2)==22);
echo(qr_prop_data_size(qr_get_props_by_version(6),1)==108);
echo(qr_prop_data_size(qr_get_props_by_version(6),0)==136);
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
 * A 0-padding nibble will be added at the end if necessary.
 *
 * data - data vector composed of mixed byte values
 *   and negative nibble values created with qr_nibble()
 */
function qr_compact_nibbles(data, i=0, carry=0) =
	(i>=len(data))? //terminate recursion
		carry?[qr_nibbles2byte(carry,undef)]:[]:
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
			value=qr_nibbles2byte(data[i], next[0])
		) concat(value, qr_compact_nibbles(data, i+2, remainder)):
	// else - data[i] is already a byte and no carry-in
	concat(data[i], qr_compact_nibbles(data,i+1));

echo("*** qr_compact_nibbles() testcases ***");
echo(qr_compact_nibbles([0])==[0]); //0x00
echo(qr_compact_nibbles([qr_nibble(8)])==[128]); //0x8.
echo(qr_compact_nibbles([qr_nibble(8), qr_nibble(1)])==[129]); //0x81
echo(qr_compact_nibbles([qr_nibble(0), 70, qr_nibble(2), qr_nibble(15), 4])==[4,98,240,64]); //0x0462F04.
echo( //0x00046233F04.
	qr_compact_nibbles(
		[0, qr_nibble(0), 70, qr_nibble(2), 51, qr_nibble(15), 4])
	==[0,4,98,51,240,64]);
echo( //0x0004623F0433
	qr_compact_nibbles(
		[0, qr_nibble(0), 70, qr_nibble(2), qr_nibble(3), qr_nibble(15), 4, 51])
	==[0,4,98,63,4,51]);
echo( //0x146330C204172F
	qr_compact_nibbles(
		[qr_nibble(1), 70, 51, 12, qr_nibble(2), 4, 23, 47])
	==[20,99,48,194,4,23,47]);
