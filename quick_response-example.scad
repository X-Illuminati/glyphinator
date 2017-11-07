/* See API documentation in barcodes/quick_response.scad for more details. */
use <barcodes/quick_response.scad>

/* simple example */
//quick_response(qr_numeric([0,1,2,3,4,5,6,7,8,9]), mark="black");

/* typical bytes example */
use <util/stringlib.scad>
quick_response(
	qr_bytes(
		ascii_to_vec("https://github.com/X-Illuminati/glyphinator/")
	),
	mark="black"
);

/* more compact version */
//quick_response(qr_alphanum("HTTPS://GITHUB.COM/X-ILLUMINATI/GLYPHINATOR/"), ecc_level=0, mark="black");
