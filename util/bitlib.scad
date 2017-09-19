/*****************************************************************************
 * Bit Manipulation Library
 * Provides some useful bit manipulation functions.
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
 *   bit(v,b)
 *     Return the truth value of the b'th bit of v.
 *
 *   check_bit_size(v,b,signed=false)
 *     Determine whether the value v can be represented with b bits (b must
 *     be positive).
 *     The signed flag indicates whether to include the sign bit in the
 *     determination; otherwise negative values will result in undef being
 *     returned.
 *
 *   xor(a,b)
 *     Return the value of a xor b.
 *     Handles arbitrary size values for a and b.
 *     Handles negative values as expected (a positive result will be returned
 *     unless a and b have differing signs).
 *
 * TODO:
 *  - Change echos to asserts (future OpenSCAD version)
 *  - Add more functions
 *
 *****************************************************************************/

//Return the truth value of the b'th bit of v
function bit(v,b) =
	((v==undef)||(b==undef)||(b<0))?undef:
	(floor(v / pow(2, b)) % 2)?true:false;

echo("*** bit() testcases ***");
echo(0,bit(0,0)==false);
echo(1,bit(-1,0)==true);
echo(2,bit(1,0)==true);
echo(3,[for (i=[0:63]) bit(0,i)]==[for (i=[0:63]) false]); //0=0...0
echo(4,[for (i=[0:63]) bit(-1,i)]==[for (i=[0:63]) true]); //-1=1...1
echo(5,[for (i=[1:63]) bit(1,i)]==[for (i=[1:63]) false]); //1=0...01
echo(6,[for (i=[0:7]) bit(85,i)?1:0]==[1,0,1,0,1,0,1,0]); //85=01010101
echo(7,[for (i=[0:7]) bit(170,i)?1:0]==[0,1,0,1,0,1,0,1]); //170=10101010
echo(8,[for (i=[0:7]) bit(165,i)?1:0]==[1,0,1,0,0,1,0,1]); //165=10100101
echo(9,[for (i=[0:7]) bit(56,i)?1:0]==[0,0,0,1,1,1,0,0]); //56=00111000
echo(10,[for (i=[0:7]) bit(-3,i)?1:0]==[1,0,1,1,1,1,1,1]); //-3=1...101
//(2^64)=0...01 0...0
echo(11,bit(pow(2,64),64)==true);
echo(12,[for (i=[0:63]) bit(pow(2,64),i)]==[for (i=[0:63]) false]);
echo(13,[for (i=[65:127]) bit(pow(2,64),i)]==[for (i=[1:63]) false]);
//-(2^64)=1...1 0...0
echo(14,[for (i=[0:63]) bit(-pow(2,64),i)]==[for (i=[0:63]) false]);
echo(15,[for (i=[64:127]) bit(-pow(2,64),i)]==[for (i=[0:63]) true]);
echo(16,bit(10,-1)==undef);
echo(17,bit(10,undef)==undef);
echo(18,bit(undef,3)==undef);

//return true if v can be represented in b bits
//if signed flag is set. the result will be adjusted
//to account for the needed sign bit
function check_bit_size(v,b,signed=false) =
	(b<0)?undef:
	(v==undef)?undef:
	(b==0)?false:
	(v==0)?true: //(b>0)
	(signed)?
		(v<0)?(-pow(2,b-1)<(v+1)):
			(pow(2,b-1)>(v+1)):
		(v<0)?undef:
			(pow(2,b)>v);

echo("*** check_bit_size() testcases ***");
echo(0,check_bit_size(-1,2)==undef);
echo(1,check_bit_size(2,-4)==undef);
echo(2,check_bit_size(2,-4,signed=true)==undef);
echo(3,check_bit_size(0,0)==false);
echo(4,check_bit_size(0,1)==true);
echo(5,check_bit_size(1,0)==false);
echo(6,check_bit_size(1,1)==true);
echo(7,check_bit_size(7,3)==true);
echo(8,check_bit_size(8,3)==false);
echo(9,check_bit_size(1,3)==true);
echo(10,check_bit_size(256,8)==false);
echo(11,check_bit_size(255,8)==true);
echo(12,check_bit_size(10,2)==false);
echo(13,check_bit_size(10,4)==true);
echo(14,check_bit_size(-10,2,signed=true)==false);
echo(15,check_bit_size(-10,4,signed=true)==false);
echo(16,check_bit_size(-10,5,signed=true)==true);
echo(17,check_bit_size(-1,0,signed=true)==false);
echo(18,check_bit_size(-1,1,signed=true)==true);
echo(19,check_bit_size(0,0,signed=true)==false);
echo(20,check_bit_size(0,1,signed=true)==true);
echo(21,check_bit_size(-2,2,signed=true)==true);
echo(22,check_bit_size(-3,2,signed=true)==false);
echo(23,check_bit_size(-3,3,signed=true)==true);
echo(24,check_bit_size(-8,3,signed=true)==false);
echo(25,check_bit_size(-8,4,signed=true)==true);
echo(26,check_bit_size(undef,4)==undef);
echo(27,check_bit_size(undef,4,signed=true)==undef);

//return the value of a xor b
//runs recursively until all bits of a and b are exhausted
function xor(a,b,i=0) =
	((a==undef)||(b==undef))?undef:
	let (c=bit(a,i), d=bit(b,i),
		 v=((c||d) && !(c&&d))?pow(2,i):0)
		(check_bit_size(a,i,signed=true) &&
		 check_bit_size(b,i,signed=true))?
			-v: //special case for sign bit
			v+xor(a,b,i+1); //recursively add powers of 2

echo("*** xor() testcases ***");
echo(0,xor(42,0)==42);
echo(1,xor(42,42)==0);
echo(2,xor(169,238)==71); //10101001^11101110=01000111=71
echo(3,xor(238,169)==71);
echo(4,xor(42,238)==196); //00101010^11101110=11000100=196
echo(5,xor(169,42)==131); //10101001^00101010=10000011=131
echo(6,xor(-8,-10)==14); //11000^10110=01110=14
echo(7,xor(-7,-10)==15); //11001^10110=01111=15
echo(8,xor(9,-10)==-1); //01001^10110=11111=-1
echo(9,xor(9,-12)==-3); //01001^10100=11101=-3
echo(10,xor(undef,0)==undef);
