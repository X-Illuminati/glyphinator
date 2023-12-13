/* Unit Test 09: Version 5/6, Mask 3, ECC High */
/* From https://commons.wikimedia.org/wiki/File:QR_code_on_oBike.jpg */
use <../quick_response.scad>
use <../../util/stringlib.scad>

// This example is mirrored and is actually short enough to be
// version 5. Presumably, they force it to be version 6 in order to
// future-proof their serial number.
mirror([1,0,0])
quick_response(
	concat(
		qr_bytes(ascii_to_vec("http://www.o.bike/download/app.html?m=")),
		qr_numeric([8,8,6,5,0,8,5,4,7])
	),
	mask=3, ecc_level=3, version=6,
	mark="black");

