/* Unit Test 04: 14x14 - 8 data bytes, 10 ecc bytes - mixed-mode */
use <../datamatrix.scad>
data_matrix(
	concat(
		c40_mode(),
		dm_c40("TELESI"),
		ascii_mode(),
		dm_ascii("S1")
	),
	mark="black");

