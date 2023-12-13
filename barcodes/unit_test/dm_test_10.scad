/* Unit Test 10: 22x22 - 30 data bytes, 20 ecc bytes - dm_pad example */
/* This is the same as unit test 9 but using expert_mode with dm_pad(). */
use <../datamatrix.scad>
use <../../util/datamatrix-util.scad>
data_matrix(
	dm_ecc(
		dm_pad(
			concat(
				text_mode(),
				dm_text("Wikipedia, the free encyclopedi"),
				ascii_mode(),
				dm_ascii("a")
			)
		)
	),
	mark="black", expert_mode=true);

