/* See API documentation in barcodes/code128.scad for more details. */
use <barcodes/code128.scad>

/* simple example */
//code_128(cs128_c([1,2,3,4]), bar="black");

/* typical example */
code_128(cs128_b("https://git.io/JfUro"), bar="black");

/* typical example center=true */
//code_128(cs128_b("https://git.io/JfUro"), bar="black", center=true);

/* mixed-mode example */
//code_128(concat(cs128_c([1,2,3,4]), cs128_a("5ABC")), bar="black");
