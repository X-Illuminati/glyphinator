/* Unit Test 01: Version 1, Mask 1, ECC High */
/* From https://en.wikipedia.org/wiki/File:Qr-1.png */
use <../quick_response.scad>
use <../../util/stringlib.scad>
quick_response(
	qr_bytes(ascii_to_vec("Ver1")),
	mask=1, ecc_level=3,
	mark="black");

