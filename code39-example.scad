/* See API documentation in barcodes/code39.scad for more details */
/* Note: Currently the characters '$', '/', '+', and '%' are not supported. */
use <barcodes/code39.scad>
code39("*A-123*", height=40, text="centered");
