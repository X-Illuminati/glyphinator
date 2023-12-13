/* Unit Test 01: 10x10 - 3 data bytes, 5 ecc bytes - expert_mode example */
use <../datamatrix.scad>
data_matrix(
	concat(
		dm_ascii("123456"),
		[114,25,5,88,102]
	),
	mark="black", expert_mode=true);

