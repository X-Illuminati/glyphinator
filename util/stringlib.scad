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
 * Depends on compat.scad library.
 *
 * API:
 *   atoi(a)
 *     Convert the string of numerals, a, to a vector of individual decimal
 *     numbers.
 *
 *   ascii_to_vec(a)
 *     Convert the ASCII string, a, into a vector of decimal numbers.
 *
 *****************************************************************************/
use <compat.scad>

/*
 * atoi - convert ASCII numerals to a vector of individual decimal numbers
 *
 * a - the ASCII string of numerals
 */
function atoi(a) = (isa_string(a))?
	[
		let (val = search(a, "0123456789"))
			for (i = val) i
	]
	:
	undef;

/* *** atoi() testcases *** */
do_assert(atoi(undef)==undef,     "atoi test 00");
do_assert(atoi(true)==undef,      "atoi test 01");
do_assert(atoi(false)==undef,     "atoi test 02");
do_assert(atoi([])==undef,        "atoi test 03");
do_assert(atoi([1,2,3])==undef,   "atoi test 04");
do_assert(atoi("")==[],           "atoi test 05");
do_assert(atoi("0")==[0],         "atoi test 06");
do_assert(atoi("1")==[1],         "atoi test 07");
do_assert(atoi("2")==[2],         "atoi test 08");
do_assert(atoi("3")==[3],         "atoi test 09");
do_assert(atoi("4")==[4],         "atoi test 10");
do_assert(atoi("5")==[5],         "atoi test 11");
do_assert(atoi("6")==[6],         "atoi test 12");
do_assert(atoi("7")==[7],         "atoi test 13");
do_assert(atoi("8")==[8],         "atoi test 14");
do_assert(atoi("9")==[9],         "atoi test 15");
do_assert(atoi("123")==[1,2,3],   "atoi test 16");
do_assert(atoi("1a23b")==[1,2,3], "atoi test 17"); //degenerate case, don't really care too much about the result

/*
 * ascii_to_vec - convert ASCII string to decimal vector
 *
 * a - the ASCII string to vectorize
 */
function ascii_to_vec(a) = (isa_string(a))?
	[
		let (val = search(a, "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7f"))
			for (i = val) i+1
	]:
	undef;

/* *** ascii_to_vec() testcases *** */
do_assert(ascii_to_vec(undef)==undef,   "ascii_to_vec test 01");
do_assert(ascii_to_vec(true)==undef,    "ascii_to_vec test 02");
do_assert(ascii_to_vec(false)==undef,   "ascii_to_vec test 03");
do_assert(ascii_to_vec([])==undef,      "ascii_to_vec test 04");
do_assert(ascii_to_vec([1,2,3])==undef, "ascii_to_vec test 05");
do_assert(ascii_to_vec("")==[],         "ascii_to_vec test 06");
do_assert(ascii_to_vec("0")==[48],      "ascii_to_vec test 07");
do_assert(ascii_to_vec("a")==[97],      "ascii_to_vec test 08");
do_assert(ascii_to_vec("0123456789")==[48,49,50,51,52,53,54,55,56,57],
	"ascii_to_vec test 09");
do_assert(ascii_to_vec("The quick brown fox jumped over the lazy dog.")
	==[84,104,101,32,113,117,105,99,107,32,98,114,111,119,110,32,102,111,120,32,106,117,109,112,101,100,32,111,118,101,114,32,116,104,101,32,108,97,122,121,32,100,111,103,46],
	"ascii_to_vec test 10");
