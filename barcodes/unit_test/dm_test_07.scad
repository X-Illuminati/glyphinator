/* Unit Test 07: 20x20 - 22 data bytes, 18 ecc bytes - fnc1 mode */
use <../datamatrix.scad>
data_matrix(
	concat(
		[fnc1_mode()],
		dm_ascii("01034531200000111709112510ABCD1234")
	),
	mark="black");

