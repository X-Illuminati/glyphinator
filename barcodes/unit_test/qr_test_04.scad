/* Unit Test 04: Version 4, Mask 6, ECC High */
/* From https://en.wikipedia.org/wiki/File:Qr-4.png */
use <../quick_response.scad>
use <../../util/stringlib.scad>
quick_response(
	qr_bytes(ascii_to_vec("Version 4 QR Code, up to 50 char")),
	mask=6, ecc_level=3,
	mark="black");

