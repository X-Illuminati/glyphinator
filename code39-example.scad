/* See API documentation in barcodes/code39.scad for more details */
use <barcodes/code39.scad>

/* typical example */
code39("*A-123*", height=40, text="centered");

/* centered example */
//color("black")
//	linear_extrude(3, center=true)
//		code39("*ABC123*", text="char", center=true);
