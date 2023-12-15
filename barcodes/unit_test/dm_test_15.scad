/* Unit Test 15: same as test case 04, center=true */
use <../datamatrix.scad>
data_matrix(
	concat(
		c40_mode(),
		dm_c40("TELESI"),
		ascii_mode(),
		dm_ascii("S1")
	),
	mark="black", center=true);

/* indicate where the origin is since the images don't show the axes */
cylinder(15, 1, center=true, $fn=100);

