/* Unit Test 11: Same as test case 06 with center=true */
/* From https://commons.wikimedia.org/wiki/File:Qr_code-Main_Page_en.svg */
use <../quick_response.scad>
use <../../util/stringlib.scad>

// This example has some strange white-space characters and inverted
// remainder pattern.
quick_response(
	qr_bytes(ascii_to_vec("Welcome to Wikipedia,\r\nthe free encyclopedia \r\nthat anyone can edit.")),
	mask=4, ecc_level=2,
	mark=4, space=7, quiet_zone=1, center=true);

/* indicate where the origin is since the images don't show the axes */
cylinder(15, 1, center=true, $fn=100);

