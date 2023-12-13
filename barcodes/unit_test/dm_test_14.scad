/* Unit Test 14: 10x10 - 3 data bytes, 5 ecc bytes - base-256 mode example */
/* This example shows use of base-256 mode. */
/* The data is a single byte (63=0x3F='?'). */
use <../datamatrix.scad>
data_matrix(
	dm_base256_append(
		[base256_mode()],
		[63],
		fills_symbol=true
	),
	mark="black");

