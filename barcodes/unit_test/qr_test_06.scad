/* Unit Test 06: Version 6, Mask 4, ECC Qual */
/* From https://commons.wikimedia.org/wiki/File:Qr_code-Main_Page_en.svg */
use <../quick_response.scad>
use <../../util/stringlib.scad>

// This example has some strange white-space characters and inverted
// remainder pattern.
quick_response(
	qr_bytes(ascii_to_vec("Welcome to Wikipedia,\r\nthe free encyclopedia \r\nthat anyone can edit.")),
	mask=4, ecc_level=2,
	mark="black");

