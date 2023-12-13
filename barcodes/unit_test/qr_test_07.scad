/* Unit Test 07: Version 3, Mask 7, ECC Low */
/* From https://en.wikipedia.org/wiki/File:QRCode-1-Intro.png */
use <../quick_response.scad>
use <../../util/stringlib.scad>
quick_response(
	qr_bytes(ascii_to_vec("Mr. Watson, come here - I want to see you.")),
	mask=7, ecc_level=0,
	mark="black");

