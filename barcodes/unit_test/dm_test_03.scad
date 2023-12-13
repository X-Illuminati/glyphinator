/* Unit Test 03: 12x12 - 5 data bytes, 7 ecc bytes - c40 mode */
use <../datamatrix.scad>
data_matrix(
		concat(
			c40_mode(),
			dm_c40("H0VLP7")
		),
		mark="black");

