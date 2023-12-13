/* Unit Test 08: Version 4, Mask 2, ECC Low */
/* From https://commons.wikimedia.org/wiki/File:Qrcode-WikiCommons-app-iOS.png */
use <../quick_response.scad>
use <../../util/stringlib.scad>

// This example has some shift-JIS encoded characters in the middle
// of the string.
// Since byte-mode is being used without an ECI directive, I suspect
// that the proper interpretation of the symbol will depend on the
// particular scanner software being used.
quick_response(
	concat(
		qr_bytes(ascii_to_vec(
			"https://itunes.apple.com/us/app/wikimedia-commons/id")),
		qr_numeric([6,3,0,9,0,1,7,8,0]),
		qr_bytes(ascii_to_vec("?mt=8"))
	),
	mask=2, ecc_level=0,
	mark="black");

