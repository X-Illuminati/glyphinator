/* Unit Test 02: Version 2, Mask 2, ECC High */
/* From https://en.wikipedia.org/wiki/File:Qr-2.png */
use <../quick_response.scad>
use <../../util/stringlib.scad>
quick_response(
	qr_bytes(ascii_to_vec("Version 2")),
	mask=2, ecc_level=3,
	mark="black");

