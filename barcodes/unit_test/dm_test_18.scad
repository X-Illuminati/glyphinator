/* Unit Test 18: generalized center=true example */
/* This example shows use of base-256 mode. */
/* The data is a single byte (63=0x3F='?'). */
use <../datamatrix.scad>
data_matrix(
	dm_base256_append(
		[base256_mode()],
		[63],
		fills_symbol=true
	),
	mark=3, space=6, quiet_zone=1, center=true);

/* indicate where the origin is since the images don't show the axes */
cylinder(15, 1, center=true, $fn=100);

