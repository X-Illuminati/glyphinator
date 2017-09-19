/*****************************************************************************
 * Reed-Solomon ECC Library
 * Generates Data Matrix ECC bytes
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
 *   ecc(data, data_size, ecc_size)
 *     Generate a vector of ecc_size bytes over data (which is vector of byte
 *     values with length data_size). Calculation is performed using
 *     Reed-Solomon error correction on GF(2^8) with polynomial 301.
 *     data_size is provided as a security measure. If len(data) != data_size
 *     the function will return undef rather than a vector.
 *
 * TODO:
 *  - Currently only applies for datamatrix; not very generic
 *  - Change echos to asserts (future OpenSCAD version)
 *
 *****************************************************************************/
use <bitlib.scad>

// calculate Galois-field log function on n
function logg(n)=
	let (galois_log_table=[
		-255, 255,   1, 240,   2, 225, 241,  53,   3,  38, 226, 133, 242,  43,  54, 210,
		   4, 195,  39, 114, 227, 106, 134,  28, 243, 140,  44,  23,  55, 118, 211, 234,
		   5, 219, 196,  96,  40, 222, 115, 103, 228,  78, 107, 125, 135,   8,  29, 162,
		 244, 186, 141, 180,  45,  99,  24,  49,  56,  13, 119, 153, 212, 199, 235,  91,
		   6,  76, 220, 217, 197,  11,  97, 184,  41,  36, 223, 253, 116, 138, 104, 193,
		 229,  86,  79, 171, 108, 165, 126, 145, 136,  34,   9,  74,  30,  32, 163,  84,
		 245, 173, 187, 204, 142,  81, 181, 190,  46,  88, 100, 159,  25, 231,  50, 207,
		  57, 147,  14,  67, 120, 128, 154, 248, 213, 167, 200,  63, 236, 110,  92, 176,
		   7, 161,  77, 124, 221, 102, 218,  95, 198,  90,  12, 152,  98,  48, 185, 179,
		  42, 209,  37, 132, 224,  52, 254, 239, 117, 233, 139,  22, 105,  27, 194, 113,
		 230, 206,  87, 158,  80, 189, 172, 203, 109, 175, 166,  62, 127, 247, 146,  66,
		 137, 192,  35, 252,  10, 183,  75, 216,  31,  83,  33,  73, 164, 144,  85, 170,
		 246,  65, 174,  61, 188, 202, 205, 157, 143, 169,  82,  72, 182, 215, 191, 251,
		  47, 178,  89, 151, 101,  94, 160, 123,  26, 112, 232,  21,  51, 238, 208, 131,
		  58,  69, 148,  18,  15,  16,  68,  17, 121, 149, 129,  19, 155,  59, 249,  70,
		 214, 250, 168,  71, 201, 156,  64,  60, 237, 130, 111,  20,  93, 122, 177, 150])
		galois_log_table[n];

// calculate Galois-field anti-log function on n
function alogg(n)=
	let (galois_antilog_table=[
		  1,   2,   4,   8,  16,  32,  64, 128,  45,  90, 180,  69, 138,  57, 114, 228,
		229, 231, 227, 235, 251, 219, 155,  27,  54, 108, 216, 157,  23,  46,  92, 184,
		 93, 186,  89, 178,  73, 146,   9,  18,  36,  72, 144,  13,  26,  52, 104, 208,
		141,  55, 110, 220, 149,   7,  14,  28,  56, 112, 224, 237, 247, 195, 171, 123,
		246, 193, 175, 115, 230, 225, 239, 243, 203, 187,  91, 182,  65, 130,  41,  82,
		164, 101, 202, 185,  95, 190,  81, 162, 105, 210, 137,  63, 126, 252, 213, 135,
		 35,  70, 140,  53, 106, 212, 133,  39,  78, 156,  21,  42,  84, 168, 125, 250,
		217, 159,  19,  38,  76, 152,  29,  58, 116, 232, 253, 215, 131,  43,  86, 172,
		117, 234, 249, 223, 147,  11,  22,  44,  88, 176,  77, 154,  25,  50, 100, 200,
		189,  87, 174, 113, 226, 233, 255, 211, 139,  59, 118, 236, 245, 199, 163, 107,
		214, 129,  47,  94, 188,  85, 170, 121, 242, 201, 191,  83, 166,  97, 194, 169,
		127, 254, 209, 143,  51, 102, 204, 181,  71, 142,  49,  98, 196, 165, 103, 206,
		177,  79, 158,  17,  34,  68, 136,  61, 122, 244, 197, 167,  99, 198, 161, 111,
		222, 145,  15,  30,  60, 120, 240, 205, 183,  67, 134,  33,  66, 132,  37,  74,
		148,   5,  10,  20,  40,  80, 160, 109, 218, 153,  31,  62, 124, 248, 221, 151,
		  3,   6,  12,  24,  48,  96, 192, 173, 119, 238, 241, 207, 179,  75, 150,   1])
		galois_antilog_table[n];

// perform Galois-field multiplication of a*b
// using the Galois log and anti-log functions above
function multg(a,b)= alogg((logg(a)+logg(b)) % 255);

function factor_table(s) =
	// Factor table for 5 ecc bytes
	(s==5)?[228,48,15,111,62]:
	// Factor table for 7 ecc bytes
	(s==7)?[23,68,144,134,240,92,254]:
	// Factor table for 10 ecc bytes
	(s==10)?[28,24,185,166,223,248,116,255,110,61]:
	// Factor table for 12 ecc bytes
	(s==12)?[41,153,158,91,61,42,142,213,97,178,100,242]:
	// Factor table for 20 ecc bytes
	(s==20)?[15,195,244,9,233,71,168,2,188,160,153,145,253,79,108,82,27,174,186,172]:
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
function ecc(data,data_size,ecc_size,pass=0)=
	let (f=factor_table(ecc_size))
		(f==undef)?undef:
		(len(data)!=data_size)?undef:
		[
			let (
				ecc_state=(pass==data_size-1)?
					[for (j=[1:ecc_size]) 0]:
					ecc(data,data_size,ecc_size,pass+1),
				t=xor(data[data_size-1-pass],ecc_state[0])
			)
			for (i=[0:1:ecc_size-1])
				let (t2=(t==0)?0:multg(t,f[ecc_size-i-1]))
					(i==ecc_size-1)?t2:xor(ecc_state[i+1],t2)
		];

echo("*** ecc() testcases ***");

/* invalid size=4 */
echo(ecc([10,20,30],3,4)==undef);

/* invalid data too short */
echo(ecc([10,20],3,5)==undef);

/*
10x10
data size: 3
ecc size: 5
data: [142,164,186] //ascii 123456
ecc: [114,25,5,88,102]
*/
echo(ecc([142,164,186],3,5)==[114,25,5,88,102]);

/*
12x12
data size: 5
ecc size: 7
data: [147,130,141,194,129] //ascii 17001164 + pad x1
ecc: [147,186,88,236,56,227,209]
data: [230,132,4,160,212] //c40 H0VLP7
ecc: [233,64,92,242,191,149,241]
*/
echo(ecc([147,130,141,194,129],5,7)==[147,186,88,236,56,227,209]);
echo(ecc([230,132,4,160,212],5,7)==[233,64,92,242,191,149,241]);

/*
14x14
data size: 8
ecc size: 10
data: [230,209,42,117,151,254,84,50] //c40 TELESIS1
ecc: [190,141,4,125,151,139,66,53,80,70]
*/
echo(ecc([230,209,42,117,151,254,84,50],8,10)
	==[190,141,4,125,151,139,66,53,80,70]);

/*
16x16
data size: 12
ecc size: 12
data: [88,106,108,106,113,102,101,106,98,129,251,147] //ascii Wikipedia + pad x3
ecc: [104,216,88,39,233,202,71,217,26,92,25,232]
*/
echo(ecc([88,106,108,106,113,102,101,106,98,129,251,147],12,12)
	==[104,216,88,39,233,202,71,217,26,92,25,232]);

/*
22x22
data size: 30
ecc size: 20
//ascii http://www.idautomation.com + pad x3
data: [105,117,117,113,59,48,48,120,120,120,47,106,101,98,118,117,112,110,98,117,106,112,111,47,100,112,110,129,150,45]
ecc: [64,198,150,168,121,187,207,220,110,53,82,43,31,69,26,15,7,4,101,131]
//text Wikipedia, the free encyclopedia + pad x5
data: [239,16,47,153,142,115,63,87,180,23,254,113,12,196,163,21,172,106,1,160,190,115,63,254,98,129,104,254,150,45]
ecc: [20,78,91,227,88,60,21,174,213,62,93,103,126,46,56,95,247,47,22,65]
*/
echo(ecc([105,117,117,113,59,48,48,120,120,120,47,106,101,98,118,117,112,110,98,117,106,112,111,47,100,112,110,129,150,45],
	30, 20)==
	[64,198,150,168,121,187,207,220,110,53,82,43,31,69,26,15,7,4,101,131]);
echo(ecc([239,16,47,153,142,115,63,87,180,23,254,113,12,196,163,21,172,106,1,160,190,115,63,254,98,129,104,254,150,45],
	30, 20)==
	[20,78,91,227,88,60,21,174,213,62,93,103,126,46,56,95,247,47,22,65]);
