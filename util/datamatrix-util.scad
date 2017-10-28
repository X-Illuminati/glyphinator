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
 * Depends on the reed-solomon-datamatrix.scad library.
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
 * Return a row from dm_prop_table based data size.
 * Recursively looks up the row with dcw >= data_size.
 *
 * data_size - number of data codewords
 */
function dm_get_props_by_data_size(data_size, i=0) =
	(data_size<0)?undef:
	(data_size==true)?undef:
	(data_size==false)?undef:
	let(p=dm_prop_table[i])
		(p==undef)?undef:
		(dm_prop_data_size(p)>=data_size)?p:
		dm_get_props_by_data_size(data_size, i+1);

echo("*** dm_get_props_by_data_size() testcases ***");
echo(dm_get_props_by_data_size(-1)==undef);
echo(dm_get_props_by_data_size(0)!=undef);
echo(dm_get_props_by_data_size(1)!=undef);
echo(dm_get_props_by_data_size(44)!=undef);
echo(dm_get_props_by_data_size(true)==undef);
echo(dm_get_props_by_data_size(false)==undef);
echo(dm_get_props_by_data_size(45)==undef); //will need adjustment in the future

/*
 * dm_get_props_by_total_size
 * Return a row from dm_prop_table based total size.
 * Recursively looks up the row with tcw == total_size.
 *
 * total_size - number of total codewords
 */
function dm_get_props_by_total_size(total_size, i=0) =
	(total_size<8)?undef:
	(total_size==true)?undef:
	(total_size==false)?undef:
	let(p=dm_prop_table[i])
		(p==undef)?undef:
		(dm_prop_total_size(p)==total_size)?p:
		dm_get_props_by_total_size(total_size, i+1);

echo("*** dm_get_props_by_total_size() testcases ***");
echo(dm_get_props_by_total_size(-1)==undef);
echo(dm_get_props_by_total_size(0)==undef);
echo(dm_get_props_by_total_size(1)==undef);
echo(dm_get_props_by_total_size(3)==undef);
echo(dm_get_props_by_total_size(8)!=undef);
echo(dm_get_props_by_total_size(9)==undef);
echo(dm_get_props_by_total_size(32)!=undef);
echo(dm_get_props_by_total_size(44)==undef);
echo(dm_get_props_by_total_size(72)!=undef);
echo(dm_get_props_by_total_size(true)==undef);
echo(dm_get_props_by_total_size(false)==undef);
echo(dm_get_props_by_total_size(73)==undef); //will need adjustment in the future

echo("*** combination testcases ***");
echo(dm_prop_data_size(dm_get_props_by_data_size(0))==3);
echo(dm_prop_data_size(dm_get_props_by_data_size(1))==3);
echo(dm_prop_data_size(dm_get_props_by_data_size(3))==3);
echo(dm_prop_data_size(dm_get_props_by_data_size(10))==12);
echo(dm_prop_data_size(dm_get_props_by_data_size(15))==18);
echo(dm_prop_data_size(dm_get_props_by_data_size(44))==44);
echo(dm_prop_data_size(dm_get_props_by_total_size(24))==12);
echo(dm_prop_data_size(dm_get_props_by_total_size(40))==22);
echo(dm_prop_data_size(dm_get_props_by_total_size(72))==44);
echo(dm_prop_total_size(dm_get_props_by_data_size(0))==8);
echo(dm_prop_total_size(dm_get_props_by_data_size(1))==8);
echo(dm_prop_total_size(dm_get_props_by_data_size(3))==8);
echo(dm_prop_total_size(dm_get_props_by_data_size(14))==32);
echo(dm_prop_total_size(dm_get_props_by_data_size(22))==40);
echo(dm_prop_total_size(dm_get_props_by_data_size(44))==72);
echo(dm_prop_total_size(dm_get_props_by_total_size(8))==8);
echo(dm_prop_total_size(dm_get_props_by_total_size(32))==32);
echo(dm_prop_total_size(dm_get_props_by_total_size(50))==50);
echo(dm_prop_dimensions(dm_get_props_by_data_size(0))==[10,10]);
echo(dm_prop_dimensions(dm_get_props_by_data_size(1))==[10,10]);
echo(dm_prop_dimensions(dm_get_props_by_data_size(3))==[10,10]);
echo(dm_prop_dimensions(dm_get_props_by_data_size(8))==[14,14]);
echo(dm_prop_dimensions(dm_get_props_by_data_size(40))==[26,26]);
echo(dm_prop_dimensions(dm_get_props_by_data_size(44))==[26,26]);
echo(dm_prop_dimensions(dm_get_props_by_total_size(18))==[14,14]);
echo(dm_prop_dimensions(dm_get_props_by_total_size(40))==[20,20]);
echo(dm_prop_dimensions(dm_get_props_by_total_size(60))==[24,24]);

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
echo(dm_pad([1,2,3,4,5],4)==undef);
echo(dm_pad([],44)==[129,175,70,220,115,11,161,56,206,101,251,147,42,192,87,237,133,28,178,73,223,118,14,164,59,209,104,254,150,45,195,90,240,136,31,181,76,226,121,17,167,62,212,107]);
echo(dm_pad([88,106,108,106,113,102,101,106,98],12)==[88,106,108,106,113,102,101,106,98,129,251,147]);
echo(dm_pad([88,106,108,106,113,102,101,106,98])==[88,106,108,106,113,102,101,106,98,129,251,147]);
echo(dm_pad([])==[129,175,70]);
echo(dm_pad([1])==[1,129,70]);
echo(dm_pad([1,2])==[1,2,129]);
echo(dm_pad([1,2,3])==[1,2,3]);
echo(dm_pad([1,2,3,4])==[1,2,3,4,129]);
echo(dm_pad([1,2,3,4,5,6,7,8,9,10,11,12,13])==[1,2,3,4,5,6,7,8,9,10,11,12,13,129,87,237,133,28]);

/*
 * dm_ecc - append DataMatrix ECC200 error correction bytes
 *
 * data - the vector of data bytes
 */
function dm_ecc(data) =
	let(p=dm_get_props_by_data_size(len(data)),
		dcw=dm_prop_data_size(p),
		ecw=dm_prop_ecc_size(p))
		(dcw==undef || dcw!=len(data))?undef:
		concat(data,rs301_ecc(data,dcw,ecw));

echo("*** dm_ecc() testcases ***");
echo(dm_ecc()==undef);
echo(dm_ecc([10,20])==undef);
echo(dm_ecc([88,106,108,106,113,102,101,106,98,129,251,147])
	==[88,106,108,106,113,102,101,106,98,129,251,147,104,216,88,39,233,202,71,217,26,92,25,232]);
