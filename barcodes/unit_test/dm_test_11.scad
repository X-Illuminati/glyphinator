/* Unit Test 11: 22x22 - 30 data bytes, 20 ecc bytes - expert_mode example */
/* This is the same as unit test 9 but using expert_mode */
/* padding and ecc bytes completely manually instead of using dm_pad() */
use <../datamatrix.scad>
data_matrix(
	concat(
		text_mode(),
		dm_text("Wikipedia, the free encyclopedi"),
		ascii_mode(),
		dm_ascii("a"),
		EOM(),
		[104,254,150,45,20,78,91,227,88,60,21,174,213,62,93,103,126,46,
			56,95,247,47,22,65]
	),
	mark="black", expert_mode=true);

