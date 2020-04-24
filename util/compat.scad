/*****************************************************************************
 * OpenSCAD Compatibility Library
 * Provides compatible behavior between different versions of OpenSCAD
 *****************************************************************************
 * Copyright 2020 Chris Baker
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
 *   do_assert(condition, message)
 *     Trigger a compile failure if condition evaluates to false.
 *     The optional message will be printed if provided.
 *
 *   isa_num(arg)
 *     Tests the argument and returns true if it is a number.
 *
 *   isa_string(arg)
 *     Tests the argument and returns true if it is a string.
 *
 *   isa_list(arg)
 *     Tests the argument and returns true if it is a list.
 *
 *   is_indexable(arg)
 *     Tests the argument and returns true if it is a indexable.
 *     An argument is indexable if it is a non-zero length list or string.
 *
 *   clamp_nonnum(arg)
 *     If the argument is not a number, clamp it to 1 unit.
 *     Special case for nan, inf, -inf -- these are considered numbers.
 *
 *****************************************************************************/

/*
 * do_assert - trigger a compile failure if a condition evaluates to false
 *
 * condition - the condition to evaluate
 * message - optional message to print in the failure condition
 */
module do_assert(condition, message=undef)
{
	function assertfunc() = assertfunc();

	if (version_num()>20150300) {
		assert(condition, message);
	} else {
		if(!condition) {
			if (message==undef) {
				if($parent_modules > 1 && parent_module(1) != "do_assert")
					echo(str("ERROR: Assertion failed in ",  parent_module(1)));
				else
					echo("ERROR: Assertion failed in top level");
			} else {
				if($parent_modules > 1 && parent_module(1) != "do_assert")
					echo(str("ERROR: Assertion failed: ", message, " in ", parent_module(1)));
				else
					echo(str("ERROR: Assertion failed: ", message, " in top level"));
			}
			if(assertfunc()) ;;
		}
	}
}

/* *** do_assert() testcases *** */
module test_do_assert_mod(arg, msg=undef) { do_assert(arg, msg); }
do_assert(true);
do_assert(true, "test message");
do_assert(1);
do_assert(1, "test message");
do_assert("false");
do_assert("false", "test message");
do_assert([0]);
do_assert([1]);
do_assert([false]);
do_assert([true]);
do_assert([0], "test message");
do_assert([1], "test message");
do_assert([false], "test message");
do_assert([true], "test message");
test_do_assert_mod(true);
test_do_assert_mod(true, "test message");
test_do_assert_mod(1);
test_do_assert_mod(1, "test message");
test_do_assert_mod("false");
test_do_assert_mod("false", "test message");
test_do_assert_mod([0]);
test_do_assert_mod([1]);
test_do_assert_mod([false]);
test_do_assert_mod([true]);
test_do_assert_mod([0], "test message");
test_do_assert_mod([1], "test message");
test_do_assert_mod([false], "test message");
test_do_assert_mod([true], "test message");

echo("*** NOTE: uncomment do_assert() failure checks here to test ***");
//do_assert(false);
//do_assert(false, "test message");
//do_assert(0);
//do_assert(0, "test message");
//do_assert("");
//do_assert("", "test message");
//do_assert([]);
//do_assert([], "test message");
//do_assert(undef);
//do_assert(undef, "test message");
//test_do_assert_mod(false);
//test_do_assert_mod(false, "test message");
//test_do_assert_mod(0);
//test_do_assert_mod(0, "test message");
//test_do_assert_mod("");
//test_do_assert_mod("", "test message");
//test_do_assert_mod([]);
//test_do_assert_mod([], "test message");
//test_do_assert_mod(undef);
//test_do_assert_mod(undef, "test message");


/*
 * isa_num - determines whether the argument is a number
 *
 * arg - the argument to check
 */
function isa_num(arg) = (version_num()>20190100)?
	is_num(arg)
	:
	(arg==arg)?((arg+1)?true:false):false;

/* *** isa_num() testcases *** */
do_assert(isa_num(0.1)==true,          "isa_num test 00");
do_assert(isa_num(1)==true,            "isa_num test 01");
do_assert(isa_num(10)==true,           "isa_num test 02");
do_assert(isa_num(+1/0)==true,         "isa_num test 03"); //+inf
do_assert(isa_num(-1/0)==true,         "isa_num test 04"); //-inf
do_assert(isa_num(0/0)==false,         "isa_num test 05"); //nan
do_assert(isa_num((1/0)/(1/0))==false, "isa_num test 06"); //nan
do_assert(isa_num([])==false,          "isa_num test 07");
do_assert(isa_num([1])==false,         "isa_num test 08");
do_assert(isa_num(["b"])==false,       "isa_num test 09");
do_assert(isa_num("")==false,          "isa_num test 10");
do_assert(isa_num("test")==false,      "isa_num test 11");
do_assert(isa_num(true)==false,        "isa_num test 12");
do_assert(isa_num(false)==false,       "isa_num test 13");
do_assert(isa_num(undef)==false,       "isa_num test 14");


/*
 * isa_string - determines whether the argument is a string
 *
 * arg - the argument to check
 */
function isa_string(arg) = (version_num()>20190100)?
	is_string(arg)
	:
	str(arg) == arg;

/* *** isa_string() testcases *** */
do_assert(isa_string()==false,            "isa_string test 00");
do_assert(isa_string(undef)==false,       "isa_string test 01");
do_assert(isa_string(true)==false,        "isa_string test 02");
do_assert(isa_string(false)==false,       "isa_string test 03");
do_assert(isa_string("")==true,           "isa_string test 04");
do_assert(isa_string("a")==true,          "isa_string test 05");
do_assert(isa_string(2)==false,           "isa_string test 06");
do_assert(isa_string([3])==false,         "isa_string test 07");
do_assert(isa_string(["b"])==false,       "isa_string test 08");
do_assert(isa_string("test")==true,       "isa_string test 09");
do_assert(isa_string(0.1)==false,         "isa_string test 10");
do_assert(isa_string(1)==false,           "isa_string test 11");
do_assert(isa_string(10)==false,          "isa_string test 12");
do_assert(isa_string([])==false,          "isa_string test 13");
do_assert(isa_string([1])==false,         "isa_string test 14");
do_assert(isa_string(0/0)==false,         "isa_string test 15");
do_assert(isa_string((1/0)/(1/0))==false, "isa_string test 16");
do_assert(isa_string(1/0)==false,         "isa_string test 17");
do_assert(isa_string(-1/0)==false,        "isa_string test 18");


/*
 * isa_list - determines whether the argument is a list
 *
 * arg - the argument to check
 */
function isa_list(arg) = (version_num()>20190100)?
	is_list(arg)
	:
	len(arg) != undef && str(arg) != arg;

/* *** isa_list() testcases *** */
do_assert(isa_list()==false,                  "isa_list test 00");
do_assert(isa_list(undef)==false,             "isa_list test 01");
do_assert(isa_list(true)==false,              "isa_list test 02");
do_assert(isa_list(false)==false,             "isa_list test 03");
do_assert(isa_list("")==false,                "isa_list test 04");
do_assert(isa_list(0.1)==false,               "isa_list test 05");
do_assert(isa_list([])==true,                 "isa_list test 06");
do_assert(isa_list([1])==true,                "isa_list test 07");
do_assert(isa_list([1,2])==true,              "isa_list test 08");
do_assert(isa_list([true])==true,             "isa_list test 09");
do_assert(isa_list([1,2,[5,6],"test"])==true, "isa_list test 10");
do_assert(isa_list(1)==false,                 "isa_list test 11");
do_assert(isa_list(1/0)==false,               "isa_list test 12");
do_assert(isa_list(((1/0)/(1/0)))==false,     "isa_list test 13");
do_assert(isa_list("test")==false,            "isa_list test 14");
do_assert(isa_list(0/0)==false,               "isa_list test 15");
do_assert(isa_list(-1/0)==false,              "isa_list test 16");


/*
 * is_indexable - determines whether the argument is indexable
 *
 * arg - the argument to check
 */
function is_indexable(arg) = (version_num()>20190100)?
	(is_list(arg) || is_string(arg)) && len(arg)>0
	:
	len(arg)>0;

/* *** is_indexable() testcases *** */
do_assert(is_indexable()==false,            "is_indexable test 00");
do_assert(is_indexable(undef)==false,       "is_indexable test 01");
do_assert(is_indexable(true)==false,        "is_indexable test 02");
do_assert(is_indexable(false)==false,       "is_indexable test 03");
do_assert(is_indexable("")==false,          "is_indexable test 04");
do_assert(is_indexable("a")==true,          "is_indexable test 05");
do_assert(is_indexable(2)==false,           "is_indexable test 06");
do_assert(is_indexable([3])==true,          "is_indexable test 07");
do_assert(is_indexable(["b"])==true,        "is_indexable test 08");
do_assert(is_indexable("test")==true,       "is_indexable test 09");
do_assert(is_indexable(0.1)==false,         "is_indexable test 10");
do_assert(is_indexable(1)==false,           "is_indexable test 11");
do_assert(is_indexable(10)==false,          "is_indexable test 12");
do_assert(is_indexable([])==false,          "is_indexable test 13");
do_assert(is_indexable([1])==true,          "is_indexable test 14");
do_assert(is_indexable(0/0)==false,         "is_indexable test 15");
do_assert(is_indexable((1/0)/(1/0))==false, "is_indexable test 16");
do_assert(is_indexable(1/0)==false,         "is_indexable test 17");
do_assert(is_indexable(-1/0)==false,        "is_indexable test 18");


/*
 * clamp_nonnum - clamp non-numbers to 1
 * nan, inf, -inf treated as numbers
 *
 * arg - the argument to clamp
 */
function clamp_nonnum(arg) = (arg+1)?arg:1;

/* *** clamp_nonnum() testcases *** */
do_assert(clamp_nonnum(0)==0,           "clamp_nonnum test 00");
do_assert(clamp_nonnum(0.1)==0.1,       "clamp_nonnum test 01");
do_assert(clamp_nonnum(1)==1,           "clamp_nonnum test 02");
do_assert(clamp_nonnum(2)==2,           "clamp_nonnum test 03");
do_assert(clamp_nonnum()==1,            "clamp_nonnum test 04");
do_assert(clamp_nonnum(undef)==1,       "clamp_nonnum test 05");
do_assert(clamp_nonnum(true)==1,        "clamp_nonnum test 06");
do_assert(clamp_nonnum(false)==1,       "clamp_nonnum test 07");
do_assert(clamp_nonnum([])==1,          "clamp_nonnum test 08");
do_assert(clamp_nonnum([3])==1,         "clamp_nonnum test 09");
do_assert(clamp_nonnum("")==1,          "clamp_nonnum test 10");
do_assert(clamp_nonnum("a")==1,         "clamp_nonnum test 11");
//nan, inf, -inf treated as numbers for compatibility with OpenSCAD 2015.03
//nan cannot be compared to itself so is untested
do_assert(clamp_nonnum(1/0)==(1/0),     "clamp_nonnum test 12");
do_assert(clamp_nonnum(-1/0)==(-1/0),   "clamp_nonnum test 13");
