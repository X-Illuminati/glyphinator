/* Unit Test 03: Version 3, Mask 1, ECC High */
/* From https://en.wikipedia.org/wiki/File:Qr-3.png */
use <../quick_response.scad>
use <../../util/stringlib.scad>
quick_response(
	qr_bytes(ascii_to_vec("Version 3 QR Code")),
	mask=1, ecc_level=3,
	mark="black");

