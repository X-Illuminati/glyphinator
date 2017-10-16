/*****************************************************************************
 * Reed-Solomon ECC Library
 * Generates Quick Response ECC bytes
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
 * Depends on the bitlib.scad library.
 * When run on its own, all echo statements in this library should print
 * "true".
 *
 * API:
 *   rs285_ecc(data, data_size, ecc_size)
 *     Generate a vector of ecc_size bytes over data (which is vector of byte
 *     values with length data_size). Calculation is performed using
 *     Reed-Solomon error correction on GF(2^8) with polynomial 285.
 *     data_size is provided as a security measure. If len(data) != data_size
 *     the function will return undef rather than a vector.
 *
 * TODO:
 *  - Add more unit tests
 *  - Change echos to asserts (future OpenSCAD version)
 *
 *****************************************************************************/
use <bitlib.scad>

// calculate Galois-field log function on n
function rs285_galois_log(n)=
	let (galois_log_table=[
		-255, 255,   1,  25,   2,  50,  26, 198,   3, 223,  51, 238,  27, 104, 199,  75,
		   4, 100, 224,  14,  52, 141, 239, 129,  28, 193, 105, 248, 200,   8,  76, 113,
		   5, 138, 101,  47, 225,  36,  15,  33,  53, 147, 142, 218, 240,  18, 130,  69,
		  29, 181, 194, 125, 106,  39, 249, 185, 201, 154,   9, 120,  77, 228, 114, 166,
		   6, 191, 139,  98, 102, 221,  48, 253, 226, 152,  37, 179,  16, 145,  34, 136,
		  54, 208, 148, 206, 143, 150, 219, 189, 241, 210,  19,  92, 131,  56,  70,  64,
		  30,  66, 182, 163, 195,  72, 126, 110, 107,  58,  40,  84, 250, 133, 186,  61,
		 202,  94, 155, 159,  10,  21, 121,  43,  78, 212, 229, 172, 115, 243, 167,  87,
		   7, 112, 192, 247, 140, 128,  99,  13, 103,  74, 222, 237,  49, 197, 254,  24,
		 227, 165, 153, 119,  38, 184, 180, 124,  17,  68, 146, 217,  35,  32, 137,  46,
		  55,  63, 209,  91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190,  97,
		 242,  86, 211, 171,  20,  42,  93, 158, 132,  60,  57,  83,  71, 109,  65, 162,
		  31,  45,  67, 216, 183, 123, 164, 118, 196,  23,  73, 236, 127,  12, 111, 246,
		 108, 161,  59,  82,  41, 157,  85, 170, 251,  96, 134, 177, 187, 204,  62,  90,
		 203,  89,  95, 176, 156, 169, 160,  81,  11, 245,  22, 235, 122, 117,  44, 215,
		  79, 174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168,  80,  88, 175])
		galois_log_table[n];

// calculate Galois-field anti-log function on n
function rs285_galois_alog(n)=
	let (galois_antilog_table=[
		  1,   2,   4,   8,  16,  32,  64, 128,  29,  58, 116, 232, 205, 135,  19,  38,
		 76, 152,  45,  90, 180, 117, 234, 201, 143,   3,   6,  12,  24,  48,  96, 192,
		157,  39,  78, 156,  37,  74, 148,  53, 106, 212, 181, 119, 238, 193, 159,  35,
		 70, 140,   5,  10,  20,  40,  80, 160,  93, 186, 105, 210, 185, 111, 222, 161,
		 95, 190,  97, 194, 153,  47,  94, 188, 101, 202, 137,  15,  30,  60, 120, 240,
		253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163,  91, 182, 113, 226,
		217, 175,  67, 134,  17,  34,  68, 136,  13,  26,  52, 104, 208, 189, 103, 206,
		129,  31,  62, 124, 248, 237, 199, 147,  59, 118, 236, 197, 151,  51, 102, 204,
		133,  23,  46,  92, 184, 109, 218, 169,  79, 158,  33,  66, 132,  21,  42,  84,
		168,  77, 154,  41,  82, 164,  85, 170,  73, 146,  57, 114, 228, 213, 183, 115,
		230, 209, 191,  99, 198, 145,  63, 126, 252, 229, 215, 179, 123, 246, 241, 255,
		227, 219, 171,  75, 150,  49,  98, 196, 149,  55, 110, 220, 165,  87, 174,  65,
		130,  25,  50, 100, 200, 141,   7,  14,  28,  56, 112, 224, 221, 167,  83, 166,
		 81, 162,  89, 178, 121, 242, 249, 239, 195, 155,  43,  86, 172,  69, 138,   9,
		 18,  36,  72, 144,  61, 122, 244, 245, 247, 243, 251, 235, 203, 139,  11,  22,
		 44,  88, 176, 125, 250, 233, 207, 131,  27,  54, 108, 216, 173,  71, 142,  1])
		galois_antilog_table[n];

// perform Galois-field multiplication of a*b
// using the Galois log and anti-log functions above
function rs285_multg(a,b) =
	rs285_galois_alog((rs285_galois_log(a)+rs285_galois_log(b)) % 255);

// factor tables for GF(2^8) poly 285 (base 0)
// s, the number of ecc bytes serves as a key to retrieve the correct table
function rs_factor_table(s) =
	(s==7)?[117,68,11,164,154,122,127]: //Factor table for Version 1 - Low ECC
	(s==10)?[193,157,113,95,94,199,111,159,194,216]: //Ver 1 - Med and Ver 2 - Low ECC
	(s==13)?[120,132,83,43,46,13,52,17,177,17,227,73,137]: //1Q
	(s==15)?[26,134,32,151,132,139,105,105,10,74,112,163,111,196,29]: //3L
	(s==16)?[59,36,50,98,229,41,65,163,8,30,209,68,189,104,13,59]: //2M, 4H, 6M
	(s==17)?[79,99,125,53,85,134,143,41,249,83,197,22,119,120,83,66,119]: //1H
	(s==18)?[146,217,67,32,75,173,82,73,220,240,215,199,175,149,113,183,251,239]: //3Q, 4M, 5Q, 6L
	(s==20)?[174,165,121,121,198,228,22,187,36,69,150,112,220,6,99,111,5,240,185,152]: //4L
	(s==22)?[245,145,26,230,218,86,253,67,123,29,137,28,40,69,189,19,244,182,176,131,179,89]: //2Q, 5H
	(s==24)?[117,144,217,127,247,237,1,206,43,61,72,130,73,229,150,115,102,216,237,178,70,169,118,122]: //5M, 6Q
	(s==26)?[94,43,77,146,144,70,68,135,42,233,117,209,40,145,24,206,56,77,152,199,98,136,4,183,51,246]: //3M, 4Q, 5L
	(s==28)?[197,58,74,176,147,121,100,181,127,233,119,117,56,247,12,167,41,100,174,103,150,208,251,18,13,28,9,252]: //2H, 6H
	undef;

/*
Calculate the ecc bytes over data.
The function is called recursively as it needs to build up the ecc
state over data_size passes.
In each pass the ecc state is calculated using the Galois-field
multiplication function.
Here is the function implemented in python:

for i in range(data_size):
	t=data[i] ^ ecc[0]
	for j in range(ecc_size):
		if (t==0):
			ecc[j]=0
		else:
			ecc[j]=galois_antilog[(galois_log[t]+galois_log[f[ecc_size-j-1]])%255]
		if ((j+1)<ecc_size):
			ecc[j]=ecc[j+1]^ecc[j]
*/
function rs285_ecc(data,data_size,ecc_size,pass=0)=
	let (f=rs_factor_table(ecc_size))
		(f==undef)?undef:
		(len(data)!=data_size)?undef:
		[
			let (
				ecc_state=(pass==data_size-1)?
					[for (j=[1:ecc_size]) 0]:
					rs285_ecc(data,data_size,ecc_size,pass+1),
				t=xor(data[data_size-1-pass],ecc_state[0])
			)
			for (i=[0:1:ecc_size-1])
				let (t2=(t==0)?0:rs285_multg(t,f[ecc_size-i-1]))
					(i==ecc_size-1)?t2:xor(ecc_state[i+1],t2)
		];

echo("*** rs285_ecc() testcases ***");

/* invalid size=4 */
echo(rs285_ecc([10,20,30],3,4)==undef);

/* invalid data too short */
echo(rs285_ecc([10,20],9,17)==undef);

/*
Version 1 - High ECC
data size: 9
ecc size: 17
data: [64,69,102,87,35,16,236,17,236] //bytes "Ver1" + pad x3
ecc: [150,106,201,175,226,23,128,154,76,96,209,69,45,171,227,182,8]
*/
echo(rs285_ecc([64,69,102,87,35,16,236,17,236],9,17)==[150,106,201,175,226,23,128,154,76,96,209,69,45,171,227,182,8]);

/*
Version 2 - High ECC
data size: 16
ecc size: 28
//bytes "Version 2" + pad x5
data: [64,149,102,87,39,54,150,246,226,3,32,236,17,236,17,236]
ecc: [12,90,228,61,30,76,144,103,28,197,74,44,221,2,42,183,254,214,200,42,77,17,77,9,55,60,28,170]
*/
echo(rs285_ecc([64,149,102,87,39,54,150,246,226,3,32,236,17,236,17,236],
	16,28)==
	[12,90,228,61,30,76,144,103,28,197,74,44,221,2,42,183,254,214,200,42,77,17,77,9,55,60,28,170]);

/*
Version 3 - Low ECC
data size: 55
ecc size: 15
//bytes "Mr. Watson, come here - I want to see you." + pad x11
data: [66,164,215,34,226,5,118,23,71,54,246,226,194,6,54,246,214,82,6,134,87,38,82,2,210,4,146,7,118,22,231,66,7,70,242,7,54,86,82,7,150,247,82,224,236,17,236,17,236,17,236,17,236,17,236]
ecc: [245,110,212,149,155,206,0,119,199,83,226,36,62,177,49]
*/
echo(rs285_ecc([66,164,215,34,226,5,118,23,71,54,246,226,194,6,54,246,214,82,6,134,87,38,82,2,210,4,146,7,118,22,231,66,7,70,242,7,54,86,82,7,150,247,82,224,236,17,236,17,236,17,236,17,236,17,236],
	55,15)==
	[245,110,212,149,155,206,0,119,199,83,226,36,62,177,49]);
