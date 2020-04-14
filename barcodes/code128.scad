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

