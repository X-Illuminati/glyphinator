/* See API documentation in barcodes/datamatrix.scad for more details. */
use <barcodes/datamatrix.scad>

/* simple example */
//data_matrix(dm_ascii("1234"), mark="black");

/* base-256 mode example */
//data_matrix(dm_base256_append([base256_mode()],[72,101,108,108,111,32,87,111,114,108,100]), mark="black");

/* typical ascii example */
data_matrix(dm_ascii("https://github.com/X-Illuminati/glyphinator/"), mark="black");

/* more compact version */
//data_matrix(concat(text_mode(),dm_text("https://github.com/X-Illuminati/glyphinato"),dm_ascii("r")), mark="black");
