/* Unit Test 09: 22x22 - 30 data bytes, 20 ecc bytes - text mode */
/* From Wikipedia */
use <../datamatrix.scad>
data_matrix(
	concat(
		text_mode(),
		dm_text("Wikipedia, the free encyclopedi"),
		ascii_mode(),
		dm_ascii("a")
	),
	mark="black");

