/* Unit Test 10: test for numeric mode and alphanum mode */
/* (also sets vector_mode for 2D rendering test) */
use <../quick_response.scad>

//unconfirmed validity
quick_response(
	concat(
		qr_alphanum("+ASDF://$ %"),
		qr_numeric([7,9,1,4,5])
	),
	mark="black",
	vector_mode=true);

