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
 * Depends on the bitlib.scad and reed-solomon-quick_response.scad library.
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
 *   qr_bitfield(value, bitlen)
 *     Annotate value as being an n-bit word where n is bitlen.
 *
 *   qr_compact_data(data)
 *     Convert the data vector of mixed-length words into a vector of
 *     bytes only. If the total number of bits has a remainder modulo 8, the
 *     final value in the returned vector will be a qr_bitfield.
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
use <bitlib.scad>
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
function qr_prop_blocks(properties, ecc_level) =
	let (ecc=qr_prop_ecc_size(properties, ecc_level))
		ceil(pow(2,floor(log(2,ecc)-4)));
// helper function to recursively determine block lengths
// data block sizes have some corner cases that need to
// be calculated based on a binary tree
// in this function, i doubles each time until it matches bc
// j will then match all of the values 0,1/bc,...,(bc-1)/bc
function _block_lens_helper(bc, ds, i=1, j=0) =
	(i==bc)?
		[floor(ds/bc+j)]:
		concat(
			_block_lens_helper(bc,ds,i=i*2,j=j),
			_block_lens_helper(bc,ds,i=i*2,j=j+1/(i*2))
		);
function qr_prop_block_lens(properties, ecc_level) =
	let(bc=qr_prop_blocks(properties, ecc_level),
		ds=qr_prop_data_size(properties, ecc_level),
		ebs=qr_prop_ecc_size(properties, ecc_level)/bc
	)
	[for(i=_block_lens_helper(bc, ds))
		[ebs, i] // combine ebs with helper array values
	];


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

echo("*** qr_prop_blocks testcases ***");
echo(len(qr_prop_table)==6); //reminder to check results below
for (i=[0:len(qr_prop_table)-1]) {
	lev=0;
	test_table=[1,1,1,1,1,2];
	echo(qr_prop_blocks(qr_prop_table[i],lev)
		==test_table[i]);
}
for (i=[0:len(qr_prop_table)-1]) {
	lev=1;
	test_table=[1,1,1,2,2,4];
	echo(qr_prop_blocks(qr_prop_table[i],lev)
		==test_table[i]);
}
for (i=[0:len(qr_prop_table)-1]) {
	lev=2;
	test_table=[1,1,2,2,4,4];
	echo(qr_prop_blocks(qr_prop_table[i],lev)
		==test_table[i]);
}
for (i=[0:len(qr_prop_table)-1]) {
	lev=3;
	test_table=[1,1,2,4,4,4];
	echo(qr_prop_blocks(qr_prop_table[i],lev)
		==test_table[i]);
}

echo("*** qr_prop_block_lens testcases ***");
echo(len(qr_prop_table)==6); //reminder to add to results
//we'll just spot check a few of these -
//mostly the ones that are tricky
echo(qr_prop_block_lens(qr_prop_table[0],0)
	==[[7,19]]);
echo(qr_prop_block_lens(qr_prop_table[5],0)
	==[[18,68],[18,68]]);
echo(qr_prop_block_lens(qr_prop_table[0],1)
	==[[10,16]]);
echo(qr_prop_block_lens(qr_prop_table[5],1)
	==[[16,27],[16,27],[16,27],[16,27]]);
echo(qr_prop_block_lens(qr_prop_table[0],2)
	==[[13,13]]);
echo(qr_prop_block_lens(qr_prop_table[2],2)
	==[[18,17],[18,17]]);
echo(qr_prop_block_lens(qr_prop_table[4],2)
	==[[18,15],[18,15],[18,16],[18,16]]);
echo(qr_prop_block_lens(qr_prop_table[5],2)
	==[[24,19],[24,19],[24,19],[24,19]]);
echo(qr_prop_block_lens(qr_prop_table[0],3)
	==[[17,9]]);
echo(qr_prop_block_lens(qr_prop_table[2],3)
	==[[22,13],[22,13]]);
echo(qr_prop_block_lens(qr_prop_table[3],3)
	==[[16,9],[16,9],[16,9],[16,9]]);
echo(qr_prop_block_lens(qr_prop_table[4],3)
	==[[22,11],[22,11],[22,12],[22,12]]);
echo(qr_prop_block_lens(qr_prop_table[5],3)
	==[[28,15],[28,15],[28,15],[28,15]]);

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
 * qr_bitfield
 * Annotate a value's length in bits.
 *
 * Within this framework most values represent bytes.
 * However, it is sometimes necessary to encode an n-bit
 * word. I am encoding these as 2-tuples: [n, value].
 *
 * value - the value
 * bitlen - the number of bits for the word
 */
function qr_bitfield(value, bitlen) = [bitlen,value];

//helper to retrieve the length from a bitfield
function qr_bitfield_len(x) =
	(x==undef)?undef:
	(len(x)==undef)?8: //assume byte
	(len(x)==2)?x[0]:
	undef;

//helper to retrieve the value from a bitfield
function qr_bitfield_val(x) =
	(x==undef)?undef:
	(len(x)==undef)?x:
	(len(x)==2)?x[1]:
	undef;

//Split a word into n-bits
function qr_split_bits(x) =
	(x==undef)?undef:
	let (l = qr_bitfield_len(x), v = qr_bitfield_val(x))
		[for (i=[l-1:-1:0]) [1, bit(v,i)?1:0]];

echo("*** qr_split_bits() testcases ***");
echo(qr_split_bits(0)==[[1,0],[1,0],[1,0],[1,0],[1,0],[1,0],[1,0],[1,0]]);
echo(qr_split_bits(1)==[[1,0],[1,0],[1,0],[1,0],[1,0],[1,0],[1,0],[1,1]]);
echo(qr_split_bits(128)==[[1,1],[1,0],[1,0],[1,0],[1,0],[1,0],[1,0],[1,0]]);
echo(qr_split_bits(146)==[[1,1],[1,0],[1,0],[1,1],[1,0],[1,0],[1,1],[1,0]]);
echo(qr_split_bits(qr_bitfield(1,8))==
	[[1,0],[1,0],[1,0],[1,0],[1,0],[1,0],[1,0],[1,1]]);
echo(qr_split_bits(qr_bitfield(128,8))==
	[[1,1],[1,0],[1,0],[1,0],[1,0],[1,0],[1,0],[1,0]]);
echo(qr_split_bits(qr_bitfield(3,4))==[[1,0],[1,0],[1,1],[1,1]]);
echo(qr_split_bits(qr_bitfield(8,4))==[[1,1],[1,0],[1,0],[1,0]]);
echo(qr_split_bits(qr_bitfield(0,2))==[[1,0],[1,0]]);
echo(qr_split_bits(qr_bitfield(3,2))==[[1,1],[1,1]]);

//recursively combine several words into a bigger word
function qr_combine_words(vec, i=0) =
	let (
		x=(i==(len(vec)-1))?
			[0,0]:
			qr_combine_words(vec, i+1),
		y=(vec[i]==undef)?[0,0]:vec[i]
	)
		[
			qr_bitfield_len(y)+qr_bitfield_len(x),
			qr_bitfield_val(y)*
				pow(2,qr_bitfield_len(x))+qr_bitfield_val(x)
		];

echo("*** qr_combine_words() testcases ***");
echo(qr_combine_words([[3,5]])==[3,5]);
echo(qr_combine_words([[3,3],[2,3]])==[5,15]);
echo(qr_combine_words([[3,3],[0,0],[2,3]])==[5,15]);
echo(qr_combine_words([[3,3],[2,3],undef])==[5,15]);
echo(qr_combine_words(qr_split_bits(0))==qr_bitfield(0,8));
echo(qr_combine_words(qr_split_bits(1))==qr_bitfield(1,8));
echo(qr_combine_words(qr_split_bits(128))==qr_bitfield(128,8));
echo(qr_combine_words(qr_split_bits(146))==qr_bitfield(146,8));
echo(qr_combine_words(qr_split_bits(qr_bitfield(3,4)))==qr_bitfield(3,4));
echo(qr_combine_words(qr_split_bits(qr_bitfield(8,4)))==qr_bitfield(8,4));
echo(qr_combine_words(qr_split_bits(qr_bitfield(0,2)))==qr_bitfield(0,2));
echo(qr_combine_words(qr_split_bits(qr_bitfield(3,2)))==qr_bitfield(3,2));

/*
 * qr_compact_data
 * Take a data vector of mixed-length words and compact it
 * down into a vector of only bytes.
 * If total bitlen has a remainder modulo 8, then the final
 * word will be a qr_bitfield.
 *
 * data - data vector composed of mixed-length words
 *   These can be bare-values (interpreted as bytes) or
 *   2-tuples created with qr_bitfield().
 */
function qr_compact_data(data) =
	let(bvec=[for (v=data, x=qr_split_bits(v)) x])
	[
		for (i=[0:8:len(bvec)-1])
			let (bitfield=qr_combine_words(
				[
					bvec[i+0], bvec[i+1], bvec[i+2], bvec[i+3],
					bvec[i+4], bvec[i+5], bvec[i+6], bvec[i+7]
				])
			)
				(qr_bitfield_len(bitfield)==8)?
					qr_bitfield_val(bitfield):
					bitfield
	];

echo("*** qr_compact_data() testcases ***");
echo(qr_compact_data([0])==[0]); //0x00
echo(qr_compact_data([qr_bitfield(8,4)])==[qr_bitfield(8,4)]); //0x8.
echo(qr_compact_data([qr_bitfield(8,4), qr_bitfield(1,4)])==[129]); //0x81
echo(qr_compact_data([qr_bitfield(3,2), 128, qr_bitfield(1,1)]) //0xE02.
	==[224,qr_bitfield(1,3)]);
echo(qr_compact_data([qr_bitfield(0,4), 70, 4, 51, qr_bitfield(3,4)]) //0x04604333
	==[4,96,67,51]);
echo(qr_compact_data([70, 4, 51, qr_bitfield(3,4)]) //0x4604333.
	==[70, 4, 51, qr_bitfield(3,4)]);
echo( //0x0462F04.
	qr_compact_data(
		[qr_bitfield(0,4), 70, qr_bitfield(2,4), qr_bitfield(15,4), 4])
	==[4,98,240,qr_bitfield(4,4)]);
echo( //0x00046233F04.
	qr_compact_data(
		[0, qr_bitfield(0,4), 70, qr_bitfield(2,4), 51, qr_bitfield(15,4), 4])
	==[0,4,98,51,240,qr_bitfield(4,4)]);
echo( //0x0004623F0433
	qr_compact_data(
		[0, qr_bitfield(0,4), 70, qr_bitfield(2,4), qr_bitfield(3,4), qr_bitfield(15,4), 4, 51])
	==[0,4,98,63,4,51]);
echo( //0x146330C204172F
	qr_compact_data(
		[qr_bitfield(1,4), 70, 51, 12, qr_bitfield(2,4), 4, 23, 47])
	==[20,99,48,194,4,23,47]);

EOM=qr_bitfield(0,4);

/*
 * qr_pad - pad a data vector up to an expected size
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
	let(d=qr_compact_data(
			//check whether data already ends with EOM
			(data[len(data)-1]==EOM)?
				data:
				concat(data,[EOM])),
		s=len(d),
		//SPECIAL CASE - There is a circular dependency between
		//  calculation of #dcw and size of compacted data.
		//  We must ask a question: was the final EOM really
		//  necessary?
		//  The answer is determined by noticing that we added
		//  EOM above, which is 4 bits of 0 and now we have a
		//  compacted vector that might end with a partial byte
		//  that is all 0 and less than 4-bits.
		q=((qr_bitfield_val(d[s-1])==0)
			&& (qr_bitfield_len(d[s-1]<=4))),
		//determine number of data codewords
		dcw=(data_size!=undef)?
			data_size: //use data_size if provided
			qr_prop_data_size(
				qr_get_props_by_data_size(
					//special case question determines min data size
					(q)?s-1:s,
					ecc_level), ecc_level)
	)
		(dcw==undef)?undef: //lookup failure
		//special case question determines whether final dcw
		//can be ignored
		((s==dcw+1) && q)?
			[for (i=[0:s-2]) qr_bitfield_val(d[i])]:
		(s>dcw)?undef: //too long
		let(offset=s%2) [
			for (i=[0:dcw-1])
				((i==s-1)&&(qr_bitfield_len(d[i])!=8))?
					//special case - pad out final byte with 0s
					qr_bitfield_val(qr_combine_words(
						[d[i], qr_bitfield(0, 8-qr_bitfield_len(d[i]))]
					)):
				(i<s)?qr_bitfield_val(d[i]):
				((i-s)%2==0)?236:17
		];

echo("*** qr_pad() testcases ***");
echo(qr_pad([1,2,3,4,5],data_size=4)==undef);
echo(qr_pad([1,2,3,4,5],0,data_size=4)==undef);
echo(qr_pad([0,qr_bitfield(1,4),2,qr_bitfield(3,4),4,qr_bitfield(5,4)],data_size=4)
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

echo(qr_pad([qr_bitfield(0,4),1,2,3,qr_bitfield(4,4)],data_size=4)==[0,16,32,52]);
echo(qr_pad([qr_bitfield(0,4),1,2,3,qr_bitfield(4,4)],data_size=5)
	==[0,16,32,52,0]);
echo(qr_pad([qr_bitfield(0,4),1,2,3,qr_bitfield(4,4)],data_size=6)
	==[0,16,32,52,0,236]);
echo(qr_pad([qr_bitfield(0,4),1,2,3,qr_bitfield(4,4)],data_size=7)
	==[0,16,32,52,0,236,17]);
echo(qr_pad([qr_bitfield(0,4),1,2,3,qr_bitfield(4,4)],data_size=8)
	==[0,16,32,52,0,236,17,236]);
echo(qr_pad([qr_bitfield(1,4),2,qr_bitfield(3,4),4,qr_bitfield(5,4)],data_size=4)
	==[16,35,4,80]);
echo(qr_pad([qr_bitfield(1,4),2,qr_bitfield(3,4),4,qr_bitfield(5,4)],data_size=5)
	==[16,35,4,80,236]);
echo(qr_pad([qr_bitfield(1,4),2,qr_bitfield(3,4),4,qr_bitfield(5,4)],data_size=6)
	==[16,35,4,80,236,17]);
echo(qr_pad([qr_bitfield(1,4),2,qr_bitfield(3,4),4,qr_bitfield(5,4)],data_size=7)
	==[16,35,4,80,236,17,236]);

echo(qr_pad([1,2,3,4,5,6,7,8,9], 3)==[1,2,3,4,5,6,7,8,9]);
echo(qr_pad([1,2,3,4,5,6,7,8,9,10], 3)
	==[1,2,3,4,5,6,7,8,9,10,0,236,17,236,17,236]);
echo(qr_pad([1,2,3,4,5,6,7,8,9,10,11,12,13], 2)
	==[1,2,3,4,5,6,7,8,9,10,11,12,13]);
echo(qr_pad([1,2,3,4,5,6,7,8,9,10,11,12,13,14], 2)
	==[1,2,3,4,5,6,7,8,9,10,11,12,13,14,0,236,17,236,17,236,17,236]);
echo(qr_pad([qr_bitfield(1,4),1,2,3,4,5,6,7,8], 3)
	==[16,16,32,48,64,80,96,112,128]);
echo(qr_pad([qr_bitfield(1,4),1,2,3,4,5,6,7,8,9], 3)
	==[16,16,32,48,64,80,96,112,128,144,236,17,236,17,236,17]);
echo(qr_pad([qr_bitfield(1,4),1,2,3,4,5,6,7,8,9,10,11,12], 2)
	==[16,16,32,48,64,80,96,112,128,144,160,176,192]);
echo(qr_pad([qr_bitfield(1,4),1,2,3,4,5,6,7,8,9,10,11,12,13], 2)==[16,16,32,48,64,80,96,112,128,144,160,176,192,208,236,17,236,17,236,17,236,17]);

//complex testcase - mix of alphanum and numeric mode with odd lengths
qr_pad_test_in1 = [
	qr_bitfield(2,4),
	qr_bitfield(11,9),
	qr_bitfield(1810,11),
	qr_bitfield(1273,11),
	qr_bitfield(719,11),
	qr_bitfield(1978,11),
	qr_bitfield(1701,11),
	qr_bitfield(38,6),
	qr_bitfield(1,4),
	qr_bitfield(4,10),
	qr_bitfield(791,10),
	qr_bitfield(4,4)
];
qr_pad_test_out1 = [32,95,18,159,43,63,221,106,89,132,4,197,208];
echo(qr_pad(qr_pad_test_in1, data_size=13) == qr_pad_test_out1);
echo(qr_pad(qr_pad_test_in1, ecc_level=2) == qr_pad_test_out1);
//more complex - overflow by 1 bit
qr_pad_test_in2 = [
	qr_bitfield(2,4),
	qr_bitfield(11,9),
	qr_bitfield(1810,11),
	qr_bitfield(1273,11),
	qr_bitfield(719,11),
	qr_bitfield(1978,11),
	qr_bitfield(1701,11),
	qr_bitfield(38,6),
	qr_bitfield(1,4),
	qr_bitfield(5,10),
	qr_bitfield(791,10),
	qr_bitfield(45,7)
];
qr_pad_test_out2 = [32,95,18,159,43,63,221,106,89,132,5,197,214,128];
echo(qr_pad(qr_pad_test_in2, data_size=14) == qr_pad_test_out2);
echo(qr_pad(qr_pad_test_in2, ecc_level=2)
	== concat(qr_pad_test_out2, [236,17,236,17,236,17,236,17]));

// helper function to slice the data byte vector into
// individual blocks for ECC
// runs recursively with i acting as the index into
// block_info and j acting as the index into data
function qr_slice_data(data, block_info, i=0, j=0) =
	concat(
		[[for (k=[j:j+block_info[i][1]-1]) data[k]]],
		(i==len(block_info)-1)?[]:
			qr_slice_data(data, block_info, i+1, j+block_info[i][1])
	);

// helper function to interleave the slices and create
// a single vector of data bytes
// TODO: check results for more than 2 slices
// TODO: check results for uneaven slices
function qr_interleave(slices) =
[
	let (count=len(slices),
		max_vec=[for (i=slices) len(i)],
		slen=max(max_vec))
	for (i=[0:slen-1])
		for (j=slices) if (j[i]!=undef) j[i]
];

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
		let(bc=qr_prop_blocks(p, ecc_level),
			block_info=qr_prop_block_lens(p, ecc_level),
			data_slices=qr_slice_data(data, block_info),
			ecc_blocks=[
				for (i=[0:bc-1])
					rs285_ecc(data_slices[i],
						block_info[i][1], //data slice size
						block_info[i][0]) //ecc block len
			]
		)
			concat(qr_interleave(data_slices),qr_interleave(ecc_blocks));

echo("*** qr_ecc() testcases ***");
echo(qr_ecc()==undef);
echo(qr_ecc([10,20])==undef);
echo(qr_ecc([10,20], version=1, ecc_level=4)==undef);
echo(qr_ecc([10,20], version=1)==undef);
echo(qr_ecc([64,69,102,87,35,16,236,17,236], version=1, ecc_level=3)
	==[64,69,102,87,35,16,236,17,236,150,106,201,175,226,23,128,154,76,96,209,69,45,171,227,182,8]);
//2-block interleave testcase
echo(qr_ecc([65,21,102,87,39,54,150,246,226,3,50,5,21,34,4,54,246,70,80,236,17,236,17,236,17,236],
	version=3,ecc_level=3)
	==[65,34,21,4,102,54,87,246,39,70,54,80,150,236,246,17,226,236,3,17,50,236,5,17,21,236,197,162,86,45,14,104,81,211,172,236,97,22,172,65,1,220,122,146,174,143,180,31,12,109,188,79,220,41,29,236,46,44,158,56,103,126,44,2,4,130,228,52,113,137]);
