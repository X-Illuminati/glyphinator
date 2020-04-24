/*****************************************************************************
 * Code 128 Symbol Library
 * Generates Code 128 / GS1-128 Barcodes
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
 * Depends on the compat.scad and bitmap.scad library.
 *
 * API:
 *   code_128(codepoints, mark=1, space=0, quiet_zone=0, vector_mode=false,
       expert_mode=false)
 *     Generates a Code 128 symbol with contents specified by the codepoints
 *     vector.
 *     The mark, space, and quiet_zone parameters can be used to change the
 *     appearance of the symbol. See the bitmap library for more details.
 *     The vector_mode flag determines whether to create 2D vector artwork
 *     instead of 3D solid geometry. See notes/caveats in the bitmap library.
 *     The expert_mode flag should only be used by experts.
 *
 *   cs128_a(string, concatenating=false)
 *     Returns a vector representing the string encoded in code set A,
 *     suitable for passing to code_128() above.
 *     If concatenating is set to true, the code A switch symbol will not be
 *     prepended and it is assumed you are already in code set A mode.
 *     Notes about special characters in string:
 *       Use "\x01" - "\x1F" (or standard substitutes like \t) for the ASCII
 *       control codes.
 *       Use "\uE000" for NUL (\0).
 *       Use "\uE001" - "\uE004" for FNC1 - FNC4.
 *     See also cs128_shift_a() below.
 *
 *   cs128_b(string, concatenating=false)
 *     Returns a vector representing the string encoded in code set B,
 *     suitable for passing to code_128() above.
 *     If concatenating is set to true, the code B switch symbol will not be
 *     prepended and it is assumed you are already in code set B mode.
 *     Notes about special characters in string:
 *       Use "\x7F" for the ASCII DEL character.
 *       Use "\uE001" - "\uE004" for FNC1 - FNC4.
 *     See also cs128_shift_b() below.
 *
 *   cs128_c(digits, concatenating=false)
 *     Returns a vector representing the digits vector encoded in code set C,
 *     suitable for passing to code_128() above.
 *     If concatenating is set to true, the code C switch symbol will not be
 *     prepended and it is assumed you are already in code set C mode.
 *     Only digits 0 - 9 should be placed in the digits vector.
 *     There must be an even number of such digits in the vector (any extra
 *     odd-digit will be dropped).
 *     However, it is allowed to use the special character value, "\uE001", to
 *     encode FNC1 and this will count as 2 digits.
 *
 *   cs128_shift_a(character)
 *     Returns a vector composed of the Shift A symbol followed by character
 *     encoded in code set A.
 *     This is only valid while in code set B mode.
 *
 *   cs128_shift_b(character)
 *     Returns a vector composed of the Shift B symbol followed by character
 *     encoded in code set B.
 *     This is only valid while in code set A mode.
 *
 *   cs128_fnc4_high_helper(string)
 *     This function can help encode high ASCII characters (128-255) for use
 *     with FNC4. This use of FNC4 is not widely supported and non-standard
 *     for GS1-128. The details of its use are also somewhat tricky.
 *     Therefore, the use of this function is not recommended and is for
 *     experts only.
 *     This function subtracts 128 from each of the ASCII characters in string
 *     and returns the result as a string that is suitable for passing to
 *     either cs_128a() or cs_128b() above.
 *     "\u0080" - "\u00FF" can be used to encode the characters in string.
 *     "\uE000" - "\uE004" will be unmodified by the function.
 *     It is expected that the expert will include the appropriate FNC4 shift
 *     or mode switch markers (either in the supplied string or concatenated
 *     with the result of this function).
 *
 *****************************************************************************/
use <../util/compat.scad>
use <../util/bitmap.scad>


/* Some potentially useful definitions */
function NUL()  = "\uE000";
function FNC1() = "\uE001";
function FNC2() = "\uE002";
function FNC3() = "\uE003";
function FNC4() = "\uE004";

/* Some additional constants */
function START_A() = 103;
function START_B() = 104;
function START_C() = 105;
function CODE_A()  = 101;
function CODE_B()  = 100;
function CODE_C()  = 99;
function SHIFT_A() = 98;
function SHIFT_B() = 98;
function STOP()    = 106;
function QUIET()   = 107;

/*
 * symbol definitions arranged in a convenient array
 * 1 indicates bar
 * 0 indicates space
 *
 * symbols:
 * 00-102 - normal symbols
 * 103-105 - start symbols
 * 106 - stop pattern
 * 107 - quiet zone spacing
 */
symbol_vector = [
	[1,1,0,1,1,0,0,1,1,0,0],     //  0 -         /         / 00
	[1,1,0,0,1,1,0,1,1,0,0],     //  1 -     !   /    !    / 01
	[1,1,0,0,1,1,0,0,1,1,0],     //  2 -     "   /    "    / 02
	[1,0,0,1,0,0,1,1,0,0,0],     //  3 -     #   /    #    / 03
	[1,0,0,1,0,0,0,1,1,0,0],     //  4 -     $   /    $    / 04
	[1,0,0,0,1,0,0,1,1,0,0],     //  5 -     %   /    %    / 05
	[1,0,0,1,1,0,0,1,0,0,0],     //  6 -     &   /    &    / 06
	[1,0,0,1,1,0,0,0,1,0,0],     //  7 -     '   /    '    / 07
	[1,0,0,0,1,1,0,0,1,0,0],     //  8 -     (   /    (    / 08
	[1,1,0,0,1,0,0,1,0,0,0],     //  9 -     )   /    )    / 09
	[1,1,0,0,1,0,0,0,1,0,0],     // 10 -     *   /    *    / 10
	[1,1,0,0,0,1,0,0,1,0,0],     // 11 -     +   /    +    / 11
	[1,0,1,1,0,0,1,1,1,0,0],     // 12 -     ,   /    ,    / 12
	[1,0,0,1,1,0,1,1,1,0,0],     // 13 -     -   /    -    / 13
	[1,0,0,1,1,0,0,1,1,1,0],     // 14 -     .   /    .    / 14
	[1,0,1,1,1,0,0,1,1,0,0],     // 15 -     /   /    /    / 15
	[1,0,0,1,1,1,0,1,1,0,0],     // 16 -     0   /    0    / 16
	[1,0,0,1,1,1,0,0,1,1,0],     // 17 -     1   /    1    / 17
	[1,1,0,0,1,1,1,0,0,1,0],     // 18 -     2   /    2    / 18
	[1,1,0,0,1,0,1,1,1,0,0],     // 19 -     3   /    3    / 19
	[1,1,0,0,1,0,0,1,1,1,0],     // 20 -     4   /    4    / 20
	[1,1,0,1,1,1,0,0,1,0,0],     // 21 -     5   /    5    / 21
	[1,1,0,0,1,1,1,0,1,0,0],     // 22 -     6   /    6    / 22
	[1,1,1,0,1,1,0,1,1,1,0],     // 23 -     7   /    7    / 23
	[1,1,1,0,1,0,0,1,1,0,0],     // 24 -     8   /    8    / 24
	[1,1,1,0,0,1,0,1,1,0,0],     // 25 -     9   /    9    / 25
	[1,1,1,0,0,1,0,0,1,1,0],     // 26 -     :   /    :    / 26
	[1,1,1,0,1,1,0,0,1,0,0],     // 27 -     ;   /    ;    / 27
	[1,1,1,0,0,1,1,0,1,0,0],     // 28 -     <   /    <    / 28
	[1,1,1,0,0,1,1,0,0,1,0],     // 29 -     =   /    =    / 29
	[1,1,0,1,1,0,1,1,0,0,0],     // 30 -     >   /    >    / 30
	[1,1,0,1,1,0,0,0,1,1,0],     // 31 -     ?   /    ?    / 31
	[1,1,0,0,0,1,1,0,1,1,0],     // 32 -     @   /    @    / 32
	[1,0,1,0,0,0,1,1,0,0,0],     // 33 -     A   /    A    / 33
	[1,0,0,0,1,0,1,1,0,0,0],     // 34 -     B   /    B    / 34
	[1,0,0,0,1,0,0,0,1,1,0],     // 35 -     C   /    C    / 35
	[1,0,1,1,0,0,0,1,0,0,0],     // 36 -     D   /    D    / 36
	[1,0,0,0,1,1,0,1,0,0,0],     // 37 -     E   /    E    / 37
	[1,0,0,0,1,1,0,0,0,1,0],     // 38 -     F   /    F    / 38
	[1,1,0,1,0,0,0,1,0,0,0],     // 39 -     G   /    G    / 39
	[1,1,0,0,0,1,0,1,0,0,0],     // 40 -     H   /    H    / 40
	[1,1,0,0,0,1,0,0,0,1,0],     // 41 -     I   /    I    / 41
	[1,0,1,1,0,1,1,1,0,0,0],     // 42 -     J   /    J    / 42
	[1,0,1,1,0,0,0,1,1,1,0],     // 43 -     K   /    K    / 43
	[1,0,0,0,1,1,0,1,1,1,0],     // 44 -     L   /    L    / 44
	[1,0,1,1,1,0,1,1,0,0,0],     // 45 -     M   /    M    / 45
	[1,0,1,1,1,0,0,0,1,1,0],     // 46 -     N   /    N    / 46
	[1,0,0,0,1,1,1,0,1,1,0],     // 47 -     O   /    O    / 47
	[1,1,1,0,1,1,1,0,1,1,0],     // 48 -     P   /    P    / 48
	[1,1,0,1,0,0,0,1,1,1,0],     // 49 -     Q   /    Q    / 49
	[1,1,0,0,0,1,0,1,1,1,0],     // 50 -     R   /    R    / 50
	[1,1,0,1,1,1,0,1,0,0,0],     // 51 -     S   /    S    / 51
	[1,1,0,1,1,1,0,0,0,1,0],     // 52 -     T   /    T    / 52
	[1,1,0,1,1,1,0,1,1,1,0],     // 53 -     U   /    U    / 53
	[1,1,1,0,1,0,1,1,0,0,0],     // 54 -     V   /    V    / 54
	[1,1,1,0,1,0,0,0,1,1,0],     // 55 -     W   /    W    / 55
	[1,1,1,0,0,0,1,0,1,1,0],     // 56 -     X   /    X    / 56
	[1,1,1,0,1,1,0,1,0,0,0],     // 57 -     Y   /    Y    / 57
	[1,1,1,0,1,1,0,0,0,1,0],     // 58 -     Z   /    Z    / 58
	[1,1,1,0,0,0,1,1,0,1,0],     // 59 -     [   /    [    / 59
	[1,1,1,0,1,1,1,1,0,1,0],     // 60 -     \   /    \    / 60
	[1,1,0,0,1,0,0,0,0,1,0],     // 61 -     ]   /    ]    / 61
	[1,1,1,1,0,0,0,1,0,1,0],     // 62 -     ^   /    ^    / 62
	[1,0,1,0,0,1,1,0,0,0,0],     // 63 -     _   /    _    / 63
	[1,0,1,0,0,0,0,1,1,0,0],     // 64 -   NUL   /    `    / 64
	[1,0,0,1,0,1,1,0,0,0,0],     // 65 -   SOH   /    a    / 65
	[1,0,0,1,0,0,0,0,1,1,0],     // 66 -   STX   /    b    / 66
	[1,0,0,0,0,1,0,1,1,0,0],     // 67 -   ETX   /    c    / 67
	[1,0,0,0,0,1,0,0,1,1,0],     // 68 -   EOT   /    d    / 68
	[1,0,1,1,0,0,1,0,0,0,0],     // 69 -   ENQ   /    e    / 69
	[1,0,1,1,0,0,0,0,1,0,0],     // 70 -   ACK   /    f    / 70
	[1,0,0,1,1,0,1,0,0,0,0],     // 71 -   BEL   /    g    / 71
	[1,0,0,1,1,0,0,0,0,1,0],     // 72 -    BS   /    h    / 72
	[1,0,0,0,0,1,1,0,1,0,0],     // 73 -    HT   /    i    / 73
	[1,0,0,0,0,1,1,0,0,1,0],     // 74 -    LF   /    j    / 74
	[1,1,0,0,0,0,1,0,0,1,0],     // 75 -    VT   /    k    / 75
	[1,1,0,0,1,0,1,0,0,0,0],     // 76 -    FF   /    l    / 76
	[1,1,1,1,0,1,1,1,0,1,0],     // 77 -    CR   /    m    / 77
	[1,1,0,0,0,0,1,0,1,0,0],     // 78 -    SO   /    n    / 78
	[1,0,0,0,1,1,1,1,0,1,0],     // 79 -    SI   /    o    / 79
	[1,0,1,0,0,1,1,1,1,0,0],     // 80 -   DLE   /    p    / 80
	[1,0,0,1,0,1,1,1,1,0,0],     // 81 -   DC1   /    q    / 81
	[1,0,0,1,0,0,1,1,1,1,0],     // 82 -   DC2   /    r    / 82
	[1,0,1,1,1,1,0,0,1,0,0],     // 83 -   DC3   /    s    / 83
	[1,0,0,1,1,1,1,0,1,0,0],     // 84 -   DC4   /    t    / 84
	[1,0,0,1,1,1,1,0,0,1,0],     // 85 -   NAK   /    u    / 85
	[1,1,1,1,0,1,0,0,1,0,0],     // 86 -   SYN   /    v    / 86
	[1,1,1,1,0,0,1,0,1,0,0],     // 87 -   ETB   /    w    / 87
	[1,1,1,1,0,0,1,0,0,1,0],     // 88 -   CAN   /    x    / 88
	[1,1,0,1,1,0,1,1,1,1,0],     // 89 -    EM   /    y    / 89
	[1,1,0,1,1,1,1,0,1,1,0],     // 90 -   SUB   /    z    / 90
	[1,1,1,1,0,1,1,0,1,1,0],     // 91 -   ESC   /    {    / 91
	[1,0,1,0,1,1,1,1,0,0,0],     // 92 -    FS   /    |    / 92
	[1,0,1,0,0,0,1,1,1,1,0],     // 93 -    GS   /    }    / 93
	[1,0,0,0,1,0,1,1,1,1,0],     // 94 -    RS   /    ~    / 94
	[1,0,1,1,1,1,0,1,0,0,0],     // 95 -    US   / DEL     / 95
	[1,0,1,1,1,1,0,0,0,1,0],     // 96 - FNC 3   / FNC 3   / 96
	[1,1,1,1,0,1,0,1,0,0,0],     // 97 - FNC 2   / FNC 2   / 97
	[1,1,1,1,0,1,0,0,0,1,0],     // 98 - Shift B / Shift A / 98
	[1,0,1,1,1,0,1,1,1,1,0],     // 99 - Code C  / Code C  / 99
	[1,0,1,1,1,1,0,1,1,1,0],     //100 - Code B  / FNC 4   / Code B
	[1,1,1,0,1,0,1,1,1,1,0],     //101 - FNC 4   / Code A  / Code A
	[1,1,1,1,0,1,0,1,1,1,0],     //102 - FNC 1   / FNC 1   / FNC 1
	[1,1,0,1,0,0,0,0,1,0,0],     //103 - Start Code A
	[1,1,0,1,0,0,1,0,0,0,0],     //104 - Start Code B
	[1,1,0,1,0,0,1,1,1,0,0],     //105 - Start Code C
	[1,1,0,0,0,1,1,1,0,1,0,1,1], //106 - Stop Pattern
	[0,0,0,0,0,0,0,0,0,0],       //107 - Quiet Zone
];

/*
 * cs128_a - convert ASCII string to vector encode in Code Set 128A
 *
 * string - the ASCII string to encode
 *          characters 1-95 are allowed with \ue000-\ue004 used to encode
 *          \0, FNC1, FNC2, FNC3, FNC4 respectively
 * concatenating - if true, don't prepend Code A/Start A symbol
 */
function cs128_a(string, concatenating=false) =
	concat(concatenating?[]:[103],
		[
			let (val = search(string, " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\ue000\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\ue003\ue002\ue004\ue001"))
				for (i=val) (i>97)?i+3:i
		]
	);

/**** cs128_a() unit-tests ****/
do_assert(cs128_a("ABCD !")                         == [103,33,34,35,36,0,1],
	"cs128_a test 00");
do_assert(cs128_a("ABCD !", true)                   == [33,34,35,36,0,1],
	"cs128_a test 01");
do_assert(cs128_a("Z[\\]^_")                        == [103,58,59,60,61,62,63],
	"cs128_a test 02");
do_assert(cs128_a("\ue000")                         == [103,64],
	"cs128_a test 03");
do_assert(cs128_a("\x01\x02\x03\x04")               == [103,65,66,67,68],
	"cs128_a test 04");
do_assert(cs128_a(str(FNC1(),FNC2(),FNC3(),FNC4())) == [103,102,97,96,101],
	"cs128_a test 05");
do_assert(cs128_a(" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\ue000\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\ue003\ue002\ue004\ue001")
	== [103,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,101,102],
	"cs128_a test 06");

/*
 * cs128_b - convert ASCII string to vector encode in Code Set 128B
 *
 * string - the ASCII string to encode
 *          characters 32-127 are allowed with \ue001-\ue004 used to encode
 *          FNC1, FNC2, FNC3, FNC4 respectively
 * concatenating - if true, don't prepend Code B/Start B symbol
 */
function cs128_b(string, concatenating=false) =
	concat(concatenating?[]:[104],
		[
			let (val = search(string, " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7f\ue003\ue002\ue004\ue001"))
				for (i=val)
					(i==98)?i+2:
					(i>=99)?i+3:
					i
		]
	);

/**** cs128_b() unit-tests ****/
do_assert(cs128_b("ABCD !")                         == [104,33,34,35,36,0,1],
	"cs128_b test 00");
do_assert(cs128_b("ABCD !", true)                   == [33,34,35,36,0,1],
	"cs128_b test 01");
do_assert(cs128_b("Z[\\]^_")                        == [104,58,59,60,61,62,63],
	"cs128_b test 02");
do_assert(cs128_b("`")                              == [104,64],
	"cs128_b test 03");
do_assert(cs128_b("abcd")                           == [104,65,66,67,68],
	"cs128_b test 04");
do_assert(cs128_b(str(FNC1(),FNC2(),FNC3(),FNC4())) == [104,102,97,96,100],
	"cs128_b test 05");
do_assert(cs128_b(" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7f\ue003\ue002\ue004\ue001")
	== [104,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,100,102],
	"cs128_b test 06");

/*
 * cs128_c - convert ASCII string to vector encode in Code Set 128C
 *
 * digits - the vector of digits to encode
 *          there must be an even number of digits in the vector
 *          only single digits 0-9 are allowed
 *          "\ue001" is also allowed to encode FNC1
 * concatenating - if true, don't prepend Code C/Start C symbol
 */
function cs128_c(digits, concatenating=false) =
	concat(concatenating?[]:[105], cs128_c_helper(digits));

// helper function to pair up digits and handle \ue001
// i is the recursion parameter and indexes into the digits array
function cs128_c_helper(digits, i=0) =
	(i>=len(digits))? []: //terminate recursion
	(digits[i]==FNC1())? //special case
		concat(102, cs128_c_helper(digits, i+1)):
	(digits[i]==10 && digits[i+1]==2)? //similar special case
		concat(102, cs128_c_helper(digits, i+2)):
	((digits[i]<10 && digits[i]>=0) && (digits[i+1]<10 && digits[i+1]>=0))?
		//normal case, pair digits
		concat(digits[i]*10+digits[i+1], cs128_c_helper(digits, i+2)):
	cs128_c_helper(digits, i+1); //skip current invalid or unpaired digit

/**** cs128_c() unit-tests ****/
do_assert(cs128_c([0,1,2])            == [105,1],         "cs128_c test 00");
do_assert(cs128_c([0,1,2,3])          == [105,1,23],      "cs128_c test 01");
do_assert(cs128_c([0,1,2,3], true)    == [1,23],          "cs128_c test 02");
do_assert(cs128_c([0,0,0,1,0,2])      == [105,0,1,2],     "cs128_c test 03");
do_assert(cs128_c([9,8,6,7,0,0])      == [105,98,67,0],   "cs128_c test 04");
do_assert(cs128_c([1,3,FNC1(),2,1])   == [105,13,102,21], "cs128_c test 05");
do_assert(cs128_c([1,3,FNC1(),FNC1(),2,1]) == [105,13,102,102,21],
	"cs128_c test 06");
do_assert(cs128_c([1,3,FNC1(),4])     == [105,13,102],    "cs128_c test 07");
do_assert(cs128_c([7,FNC1(),2,1])     == [105,102,21],    "cs128_c test 08");
do_assert(cs128_c([7,FNC1(),4])       == [105,102],       "cs128_c test 09");
do_assert(cs128_c([7,FNC1(),FNC1(),4]) == [105,102,102],
	"cs128_c test 10");
do_assert(cs128_c([1,3,10,2,2,1])     == [105,13,102,21], "cs128_c test 11");
do_assert(cs128_c([1,3,10,2,10,2,2,1]) == [105,13,102,102,21],
	"cs128_c test 12");
do_assert(cs128_c([1,3,10,2,4])       == [105,13,102],    "cs128_c test 13");
do_assert(cs128_c([7,10,2,2,1])       == [105,102,21],    "cs128_c test 14");
do_assert(cs128_c([7,10,2,4])         == [105,102],       "cs128_c test 15");
do_assert(cs128_c([7,10,2,10,2,4])    == [105,102,102],   "cs128_c test 16");

/*
 * cs128_shift_a - encode the ASCII character in Code Set 128A with prepended
 *   Shift A symbol
 *
 * character - the character to be shifted, see rules for cs128_a()
 *
 * This is only valid while in code set B mode.
 */
function cs128_shift_a(character) =
	let ( symbol=cs128_a(character, concatenating=true) )
		[ 98, symbol[0] ];

/**** cs128_a() unit-tests ****/
do_assert(cs128_shift_a("A")      == [98, 33],  "cs128_shift_a test 00");
do_assert(cs128_shift_a(" ")      == [98, 0],   "cs128_shift_a test 01");
do_assert(cs128_shift_a(NUL())    == [98, 64],  "cs128_shift_a test 02");
do_assert(cs128_shift_a("\t")     == [98, 73],  "cs128_shift_a test 03");
do_assert(cs128_shift_a("\x1F")   == [98, 95],  "cs128_shift_a test 04");
do_assert(cs128_shift_a(FNC1())   == [98, 102], "cs128_shift_a test 05");
do_assert(cs128_shift_a(FNC2())   == [98, 97],  "cs128_shift_a test 06");
do_assert(cs128_shift_a(FNC3())   == [98, 96],  "cs128_shift_a test 07");
do_assert(cs128_shift_a(FNC4())   == [98, 101], "cs128_shift_a test 08");

/*
 * cs128_shift_b - encode the ASCII character in Code Set 128B with prepended
 *   Shift B symbol
 *
 * character - the character to be shifted, see rules for cs128_b()
 *
 * This is only valid while in code set A mode.
 */
function cs128_shift_b(character) =
	let ( symbol=cs128_b(character, concatenating=true) )
		[ 98, symbol[0] ];

/**** cs128_a() unit-tests ****/
do_assert(cs128_shift_b("A")      == [98, 33],  "cs128_shift_b test 00");
do_assert(cs128_shift_b(" ")      == [98, 0],   "cs128_shift_b test 01");
do_assert(cs128_shift_b("`")      == [98, 64],  "cs128_shift_b test 02");
do_assert(cs128_shift_b("i")      == [98, 73],  "cs128_shift_b test 03");
do_assert(cs128_shift_b("\x7F")   == [98, 95],  "cs128_shift_b test 04");
do_assert(cs128_shift_b(FNC1())   == [98, 102], "cs128_shift_b test 05");
do_assert(cs128_shift_b(FNC2())   == [98, 97],  "cs128_shift_b test 06");
do_assert(cs128_shift_b(FNC3())   == [98, 96],  "cs128_shift_b test 07");
do_assert(cs128_shift_b(FNC4())   == [98, 100], "cs128_shift_b test 08");

/*
 * cs128_fnc4_high_helper - helper for high-ASCII characters encoded with FNC4
 *
 * string - string of high-ASCII characters
 *
 * Returns a string with all of the characters shifted down by 128.
 * "\uE000" - "\uE004" will be unmodified by the function.
 */
function cs128_fnc4_high_helper(string) =
	chr(
		[
			let (val = search(string, "\u0080\u0081\u0082\u0083\u0084\u0085\u0086\u0087\u0088\u0089\u008A\u008B\u008C\u008D\u008E\u008F\u0090\u0091\u0092\u0093\u0094\u0095\u0096\u0097\u0098\u0099\u009A\u009B\u009C\u009D\u009E\u009F\u00A0¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ\uE000\uE001\uE002\uE003\uE004"))
			for (i = val)
				(i==0)?57344:        //special case - would encode as \0
				(i>127)?57344+i-128: //pass through our custom-use \uE000-\uE004
				i                    //position in search string is ord-128
		]
	);

/**** cs128_fnc4_high_helper() unit-tests ****/
do_assert(cs128_fnc4_high_helper("¡þÁÂÃ") == "!~ABC",
	"cs128_fnc4_high_helper test 00");
do_assert(cs128_fnc4_high_helper("\u0080") == "\uE000",
	"cs128_fnc4_high_helper test 01");
do_assert(cs128_fnc4_high_helper(str(FNC1(),FNC2(),FNC3(),FNC4()))
	== "\ue001\ue002\ue003\ue004",
	"cs128_fnc4_high_helper test 02");
do_assert(cs128_fnc4_high_helper("\u0081\u0082\u0083\u0084\u0085\u0086\u0087\u0088\u0089\u008A\u008B\u008C\u008D\u008E\u008F\u0090\u0091\u0092\u0093\u0094\u0095\u0096\u0097\u0098\u0099\u009A\u009B\u009C\u009D\u009E\u009F\u00A0¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ")
	== "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7f",
	"cs128_fnc4_high_helper test 03");


/*
 * calculate_checkdigit - calculate the checkdigit
 *
 * symbols - vector of symbols for the Code 128 barcode
 *
 * Recursively add the weighted values for the symbols vector and calculate
 * the remainder modulo 103.
 * i is the recursion index and is incremented from 0 to len(symbols)-1.
 * i=-1 is used to calculate the remainder after the recursive addition phase.
 */
function calculate_checkdigit(symbols, i=-1) =
	(i==len(symbols)-1)?
		symbols[i]*i:
	(i==-1)?
		(calculate_checkdigit(symbols, i=0)%103):
	symbols[i]*((i==0)?1:i) + calculate_checkdigit(symbols, i+1);

/*
 * code_128 - Generate a Code 128 / GS1-128 barcode
 *
 * codepoints - vector of codepoints to encode
 *   see the API at the top of the file for the helper functions to generate
 *   this vector
 *
 * bar - bar representation
 * space - space representation
 * quiet_zone - representation for quiet zone
 * (see documentation in bitmap.scad)
 *
 * vector_mode - create a 2D vector drawing instead of 3D extrusion
 * expert_mode - only use this if you are an expert
 */
module code_128(codepoints, bar=1, space=0, quiet_zone=0, vector_mode=false,
	expert_mode=false)
{
	start_check = codepoints[0] != START_A()
		&& codepoints[0] != START_B()
		&& codepoints[0] != START_C();

	if (!expert_mode)
		do_assert(!start_check, "Code 128 does not begin with a valide START symbol");

	//normalize the vector by replacing start symbols in the middle of the
	//vector with switch symbols
	norm_vec = (expert_mode)?
		codepoints
		:
		[
			for(i=[0:len(codepoints)-1])
				(i>0 && codepoints[i]==START_A())? CODE_A():
				(i>0 && codepoints[i]==START_B())? CODE_B():
				(i>0 && codepoints[i]==START_C())? CODE_C():
				codepoints[i]
		];

	//add the checkdigit and wrapping quiet zone and stop symbols
	c128_vec = (expert_mode)?
		codepoints
		:
		concat(
			QUIET(),
			[ for(i=norm_vec) i ],
			calculate_checkdigit(norm_vec),
			STOP(),
			QUIET()
		);

	//replace the symbol numbers with the modules from symbol_vector
	//and concatenates them together
	//modules are also replaced with the provided bar/space/quiet_zone
	module_vector = [
		for (i=c128_vec)
			for (j=symbol_vector[i])
				(i==107)?quiet_zone:
				(j)?bar:space
	];

	//draw the resulting vector
	scale([0.495, 12.7, 1])
		1dbitmap(module_vector, vector_mode=vector_mode);
}


/* Examples */
example=1;
//example  0 - 128B/C - RI476394652CH - Real world example from Wikipedia
//example  1 - 128B - Wikipedia - Schematic example from Wikipedia, vector mode example
//example  2 - 128A - PJJ123C - Checksum calculation example from Wikipedia
//example  3 - 128C/A - 42184020500 - FNC1 example from Wikipedia
//example  4 - 128B - Wikipedia - concatenation flag example
//example  5 - 128A/B - Wikipedia - mixed a/b example
//example  6 - 128B - WikiPedia - shift example
//example  7 - 128B - X00Y - length optimization example from Wikipedia
//example  8 - 128B/C - X00Y - length optimization example from Wikipedia
//example  9 - 128A - ABC¡!¢£¤¥Þ^ÀÁÂÃXYZ - FNC4 high-ASCII example
//example 10 - 128A - PJJ123C - expert mode example
//example 11 - Invalid - test assert for invalid start symbol
//example 12 - Invalid - expert mode allows generating an invalid barcode

if (example==0)
	code_128(concat(cs128_b("RI"),
			cs128_c([4,7,6,3,9,4,6,5,]),
			cs128_b("2CH")),
		bar="black");

if (example==1)
	//checkdigit 88
	code_128(cs128_b("Wikipedia"), bar="black", vector_mode=true);

if (example==2)
	//checkdigit 54
	code_128(cs128_a("PJJ123C"), bar="black");

if (example==3)
	//checkdigit 92
	code_128(concat(cs128_c([FNC1(), 4,2, 1,8, 4,0, 2,0, 5,0]), cs128_a("0")),
		bar="black");

//same as example 1 - uses unnecessary concatenation to show the use of the
//concatenating flag
if (example==4)
	code_128(concat(cs128_b("W"), cs128_b("ikipedia", concatenating=true)),
		bar="black");

//similar to example 1 - unnecessarily starts with 128A to show the use of
//mixed code types
if (example==5)
	code_128(concat(cs128_a("W"), cs128_b("ikipedia")), bar="black");

if (example==6)
	code_128(concat(cs128_b("Wiki"),
			cs128_shift_a("P"),
			cs128_b("edia", concatenating=true)),
		bar="black");

if (example==7)
	code_128(cs128_b("X00Y"), bar="black");

//similar to example 7 - use of 128C here is paradoxically larger
if (example==8)
	code_128(concat(cs128_b("X"), cs128_c([0,0]), cs128_b("Y")), bar="black");


//high-ASCII example - this is supposedly very non-standard, but 3 out-of-4
//android apps that I tried were able to decode it as ABC¡!¢£¤¥Þ^ÀÁÂÃXYZ
if (example==9)
	code_128(cs128_a(str("ABC", FNC4(), cs128_fnc4_high_helper("¡"), "!",
		cs128_fnc4_high_helper(str(FNC4(), FNC4(), "¢£¤¥Þ", FNC4())), "^",
		cs128_fnc4_high_helper("ÀÁÂÃ"), FNC4(), FNC4(), "XYZ")),
		bar="black");

//same as example 2, uses expert mode to manually specify all code points
if (example==10)
	code_128([QUIET(),START_A(),48,42,42,17,18,19,35,54,STOP(),QUIET()],
		bar="black", expert_mode=true);

//Invalid Start - Should assert
if (example==11)
	code_128([1, 16, 33, 73, 99, 58], bar="black");

//same as example 11 - expert mode allows module generation anyway
if (example==12)
	code_128([1, 16, 33, 73, 99, 58], bar="black", expert_mode=true);
