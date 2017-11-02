/*****************************************************************************
 * String Manipulation Library
 * Provides some useful string manipulation functions.
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
 *   atoi(a)
 *     Convert the string of numerals, a, to a vector of individual decimal
 *     numbers.
 *
 *   ascii_to_vec(a)
 *     Convert the ASCII string, a, into a vector of decimal numbers.
 *
 * TODO:
 *  - Change echos to asserts (future OpenSCAD version)
 *
 *****************************************************************************/

/*
 * atoi - convert ASCII numerals to a vector of individual decimal numbers
 *
 * a - the ASCII string of numerals
 */
function atoi(a) = (len(a)==undef)?undef:
[
	let (val = search(a, "0123456789"))
		for (i = [0:1:len(a) - 1])
			val[i]
];

echo("*** atoi() testcases ***");
echo(ascii_to_vec(undef)==undef);
echo(ascii_to_vec(true)==undef);
echo(ascii_to_vec(false)==undef);
echo(ascii_to_vec("")==[]);
echo(atoi("0")==[0]);
echo(atoi("1")==[1]);
echo(atoi("2")==[2]);
echo(atoi("3")==[3]);
echo(atoi("4")==[4]);
echo(atoi("5")==[5]);
echo(atoi("6")==[6]);
echo(atoi("7")==[7]);
echo(atoi("8")==[8]);
echo(atoi("9")==[9]);
echo(atoi("123")==[1,2,3]);
echo(atoi("1a23b")==[1,2,3,undef,undef]); //degenerate case, don't really care about the result

/*
 * ascii_to_vec - convert ASCII string to decimal vector
 *
 * a - the ASCII string to vectorize
 */
function ascii_to_vec(a) = (len(a)==undef)?undef:
[
	let (val = search(a, "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7f"))
		for (i = [0:1:len(a) - 1])
			val[i]+1
];

echo("*** ascii_to_vec() testcases ***");
echo(ascii_to_vec(undef)==undef);
echo(ascii_to_vec(true)==undef);
echo(ascii_to_vec(false)==undef);
echo(ascii_to_vec("")==[]);
echo(ascii_to_vec("0")==[48]);
echo(ascii_to_vec("a")==[97]);
echo(ascii_to_vec("0123456789")==[48,49,50,51,52,53,54,55,56,57]);
echo(ascii_to_vec("The quick brown fox jumped over the lazy dog.")
	==[84,104,101,32,113,117,105,99,107,32,98,114,111,119,110,32,102,111,120,32,106,117,109,112,101,100,32,111,118,101,114,32,116,104,101,32,108,97,122,121,32,100,111,103,46]);
