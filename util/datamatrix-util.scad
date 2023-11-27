/*****************************************************************************
 * Data Matrix Utility Library
 * Provides internal helper interfaces for datamatrix.scad
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
 * Depends on the reed-solomon-datamatrix.scad and compat.scad libraries.
 * When run on its own, all echo statements in this library should print
 * "true".
 *
 * API:
 *   dm_pad(data, data_size=undef)
 *     Pad the data byte vector up to data_size using the DataMatrix padding
 *     algorithm (mod 253).
 *     This padding algorithm includes the EOM byte.
 *     If data_size is left undefined, an appropriate value will be calculated
 *     from len(data).
 *
 *   dm_ecc(data)
 *     Calculate and append DataMatrix ECC200 error correction bytes over the
 *     data byte vector.
 *     The len(data) must be a particular size; use dm_pad() to pad up to the
 *     nearest valid size.
 *
 *   dm_get_props_by_data_size(data_size)
 *     Get a property vector based on data_size.
 *     Returns properties appropriate for a DM symbol that can contain at
 *     least data_size data codewords.
 *     See getter functions below to interpret this property vector.
 *
 *   dm_get_props_by_total_size(total_size)
 *     Get a property vector based on total_size.
 *     Returns properties appropriate for a DM symbol that has precisely
 *     total_size combined data and ecc codewords.
 *     See getter functions below to interpret this property vector.
 *
 *  Getter Functions for Use with Property Vector:
 *    dm_prop_data_size(properties) - return number of data codewords
 *    dm_prop_ecc_size(properties) - return number of ecc codewords
 *    dm_prop_total_size(properties) - return number of total codewords
 *    dm_prop_dimensions(properties) - return symbol dimensions
 *
 * TODO:
 *  - Change echos to asserts (future OpenSCAD version)
 *
 *****************************************************************************/
use <compat.scad>
use <reed-solomon-datamatrix.scad>

/*
I'd like to keep all of the constants related to each
DataMatrix format in on spot.
 - dcw: number of data codewords
 - ecw: number of ecc codewords
 - tcw: number of total codewords
 - dimen: dimensions for the symbol
 - c: corner type
 - xa: x adjustment for codewords that wrap around
       from the top to the bottom side of the symbol
 - ya: y adjustment for codewords that wrap around
       from the left to the right side of the symbol
*/
dm_prop_table = [
	//dcw,ecw,tcw, dimen ,c,xa,ya
	[   3,  5,  8,[10,10],0, 0, 0],
	[   5,  7, 12,[12,12],0,-2, 2],
	[   8, 10, 18,[14,14],1, 4,-4],
	[  12, 12, 24,[16,16],2, 2,-2],
	[  18, 14, 32,[18,18],0, 0, 0],
	[  22, 18, 40,[20,20],0,-2, 2],
	[  30, 20, 50,[22,22],1, 4,-4],
	[  36, 24, 60,[24,24],2, 2,-2],
	[  44, 28, 72,[26,26],0, 0, 0],
];

/*
 * Property Getter functions
 *
 * properties - one of the rows from the dm_prop_table
 */
function dm_prop_data_size(properties) = properties[0];
function dm_prop_ecc_size(properties) = properties[1];
function dm_prop_total_size(properties) = properties[2];
function dm_prop_dimensions(properties) = properties[3];
function dm_prop_corner(properties) = properties[4];
function dm_prop_x_adjust(properties) = properties[5];
function dm_prop_y_adjust(properties) = properties[6];

/*
 * dm_get_props_by_data_size
 * Return a row from dm_prop_table based on data size.
 * Recursively looks up the row with dcw >= data_size.
 *
 * data_size - number of data codewords
 */
function dm_get_props_by_data_size(data_size, i=0) =
	(!isa_num(data_size))?undef:
	(data_size<0)?undef:
	let(p=dm_prop_table[i])
		(p==undef)?undef:
		(dm_prop_data_size(p)>=data_size)?p:
		dm_get_props_by_data_size(data_size, i+1);

echo("*** dm_get_props_by_data_size() testcases ***");
do_assert(dm_get_props_by_data_size(-1)==undef,
	"dm_get_props_by_data_size test 00");
do_assert(dm_get_props_by_data_size(0)!=undef,
	"dm_get_props_by_data_size test 01");
do_assert(dm_get_props_by_data_size(1)!=undef,
	"dm_get_props_by_data_size test 02");
do_assert(dm_get_props_by_data_size(44)!=undef,
	"dm_get_props_by_data_size test 03");
do_assert(dm_get_props_by_data_size(true)==undef,
	"dm_get_props_by_data_size test 04");
do_assert(dm_get_props_by_data_size(false)==undef,
	"dm_get_props_by_data_size test 05");
//the tested value will need adjustment if more rows are added to the table
do_assert(dm_get_props_by_data_size(45)==undef,
	"dm_get_props_by_data_size test 06");

/*
 * dm_get_props_by_total_size
 * Return a row from dm_prop_table based on total size.
 * Recursively looks up the row with tcw == total_size.
 *
 * total_size - number of total codewords
 */
function dm_get_props_by_total_size(total_size, i=0) =
	(!isa_num(total_size))?undef:
	(total_size<8)?undef:
	let(p=dm_prop_table[i])
		(p==undef)?undef:
		(dm_prop_total_size(p)==total_size)?p:
		dm_get_props_by_total_size(total_size, i+1);

echo("*** dm_get_props_by_total_size() testcases ***");
do_assert(dm_get_props_by_total_size(-1)==undef,
	"dm_get_props_by_total_size test 00");
do_assert(dm_get_props_by_total_size(0)==undef,
	"dm_get_props_by_total_size test 01");
do_assert(dm_get_props_by_total_size(1)==undef,
	"dm_get_props_by_total_size test 02");
do_assert(dm_get_props_by_total_size(3)==undef,
	"dm_get_props_by_total_size test 03");
do_assert(dm_get_props_by_total_size(8)!=undef,
	"dm_get_props_by_total_size test 04");
do_assert(dm_get_props_by_total_size(9)==undef,
	"dm_get_props_by_total_size test 05");
do_assert(dm_get_props_by_total_size(32)!=undef,
	"dm_get_props_by_total_size test 06");
do_assert(dm_get_props_by_total_size(44)==undef,
	"dm_get_props_by_total_size test 07");
do_assert(dm_get_props_by_total_size(72)!=undef,
	"dm_get_props_by_total_size test 08");
do_assert(dm_get_props_by_total_size(true)==undef,
	"dm_get_props_by_total_size test 09");
do_assert(dm_get_props_by_total_size(false)==undef,
	"dm_get_props_by_total_size test 10");
//the tested value will need adjustment if more rows are added to the table
do_assert(dm_get_props_by_total_size(73)==undef,
	"dm_get_props_by_total_size test 11");

echo("*** combination testcases ***");
do_assert(dm_prop_data_size(dm_get_props_by_data_size(0))==3,
	"combination test 00");
do_assert(dm_prop_data_size(dm_get_props_by_data_size(1))==3,
	"combination test 01");
do_assert(dm_prop_data_size(dm_get_props_by_data_size(3))==3,
	"combination test 02");
do_assert(dm_prop_data_size(dm_get_props_by_data_size(10))==12,
	"combination test 03");
do_assert(dm_prop_data_size(dm_get_props_by_data_size(15))==18,
	"combination test 04");
do_assert(dm_prop_data_size(dm_get_props_by_data_size(44))==44,
	"combination test 05");
do_assert(dm_prop_data_size(dm_get_props_by_total_size(24))==12,
	"combination test 06");
do_assert(dm_prop_data_size(dm_get_props_by_total_size(40))==22,
	"combination test 07");
do_assert(dm_prop_data_size(dm_get_props_by_total_size(72))==44,
	"combination test 08");
do_assert(dm_prop_total_size(dm_get_props_by_data_size(0))==8,
	"combination test 09");
do_assert(dm_prop_total_size(dm_get_props_by_data_size(1))==8,
	"combination test 10");
do_assert(dm_prop_total_size(dm_get_props_by_data_size(3))==8,
	"combination test 11");
do_assert(dm_prop_total_size(dm_get_props_by_data_size(14))==32,
	"combination test 12");
do_assert(dm_prop_total_size(dm_get_props_by_data_size(22))==40,
	"combination test 13");
do_assert(dm_prop_total_size(dm_get_props_by_data_size(44))==72,
	"combination test 14");
do_assert(dm_prop_total_size(dm_get_props_by_total_size(8))==8,
	"combination test 15");
do_assert(dm_prop_total_size(dm_get_props_by_total_size(32))==32,
	"combination test 16");
do_assert(dm_prop_total_size(dm_get_props_by_total_size(50))==50,
	"combination test 17");
do_assert(dm_prop_dimensions(dm_get_props_by_data_size(0))==[10,10],
	"combination test 18");
do_assert(dm_prop_dimensions(dm_get_props_by_data_size(1))==[10,10],
	"combination test 19");
do_assert(dm_prop_dimensions(dm_get_props_by_data_size(3))==[10,10],
	"combination test 20");
do_assert(dm_prop_dimensions(dm_get_props_by_data_size(8))==[14,14],
	"combination test 21");
do_assert(dm_prop_dimensions(dm_get_props_by_data_size(40))==[26,26],
	"combination test 22");
do_assert(dm_prop_dimensions(dm_get_props_by_data_size(44))==[26,26],
	"combination test 23");
do_assert(dm_prop_dimensions(dm_get_props_by_total_size(18))==[14,14],
	"combination test 24");
do_assert(dm_prop_dimensions(dm_get_props_by_total_size(40))==[20,20],
	"combination test 25");
do_assert(dm_prop_dimensions(dm_get_props_by_total_size(60))==[24,24],
	"combination test 26");

EOM = 129; // end-of-message (first padding byte)

/*
 * dm_pad - pad a byte vector up to an expected size
 *
 * data - the vector of initial data bytes
 *
 * data_size - (optional) the size to pad the data vector up to
 *   if left undefined, a value will be calculated from len(data)
 * returns undef if len(data) > data_size
 */
function dm_pad(data, data_size=undef) =
	let(dcw = (data_size!=undef)?data_size:
		dm_prop_data_size(dm_get_props_by_data_size(len(data))))
		(dcw==undef)?undef:
		(len(data)>dcw)?undef:
		[
			for (i=[0:dcw-1])
				(i==len(data))? EOM:
				(i>len(data))?
					let(p=((((149*(i+1))%253)+130)%254))
						(p==0)?254:p:
				data[i]
		];

echo("*** dm_pad() testcases ***");
do_assert(dm_pad([1,2,3,4,5],4)==undef,                  "dm_pad test 00");
do_assert(dm_pad([],44)
	==[129,175,70,220,115,11,161,56,206,101,251,147,42,192,87,237,133,28,178,73,223,118,14,164,59,209,104,254,150,45,195,90,240,136,31,181,76,226,121,17,167,62,212,107],
	"dm_pad test 01");
do_assert(dm_pad([88,106,108,106,113,102,101,106,98],12)
	==[88,106,108,106,113,102,101,106,98,129,251,147],   "dm_pad test 02");
do_assert(dm_pad([88,106,108,106,113,102,101,106,98])
	==[88,106,108,106,113,102,101,106,98,129,251,147],   "dm_pad test 03");
do_assert(dm_pad([])==[129,175,70],                      "dm_pad test 04");
do_assert(dm_pad([1])==[1,129,70],                       "dm_pad test 05");
do_assert(dm_pad([1,2])==[1,2,129],                      "dm_pad test 06");
do_assert(dm_pad([1,2,3])==[1,2,3],                      "dm_pad test 07");
do_assert(dm_pad([1,2,3,4])==[1,2,3,4,129],              "dm_pad test 08");
do_assert(dm_pad([1,2,3,4,5,6,7,8,9,10,11,12,13])
	==[1,2,3,4,5,6,7,8,9,10,11,12,13,129,87,237,133,28], "dm_pad test 09");

/*
 * dm_ecc - append DataMatrix ECC200 error correction bytes
 *
 * data - the vector of data bytes
 */
function dm_ecc(data) = isa_list(data)?
	let(p=dm_get_props_by_data_size(len(data)),
		dcw=dm_prop_data_size(p),
		ecw=dm_prop_ecc_size(p))
		(dcw==undef || dcw!=len(data))?undef:
		concat(data,rs301_ecc(data,dcw,ecw))
	:undef;

echo("*** dm_ecc() testcases ***");
do_assert(dm_ecc()==undef,        "dm_ecc test 00");
do_assert(dm_ecc(undef)==undef,   "dm_ecc test 01");
do_assert(dm_ecc([])==undef,      "dm_ecc test 02");
do_assert(dm_ecc(false)==undef,   "dm_ecc test 03");
do_assert(dm_ecc(true)==undef,    "dm_ecc test 04");
do_assert(dm_ecc("")==undef,      "dm_ecc test 05");
do_assert(dm_ecc([10,20])==undef, "dm_ecc test 06");
do_assert(dm_ecc([88,106,108,106,113,102,101,106,98,129,251,147])
	==[88,106,108,106,113,102,101,106,98,129,251,147,104,216,88,39,233,202,71,217,26,92,25,232],
	"dm_ecc test 07");
