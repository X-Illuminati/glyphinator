/* Unit Test 19: Canonical Example with center=true */
use <../upc.scad>
UPC_A("012345543210", bar=6, space=2, quiet_zone=1, center=true);
//UPC_A("012345543210", bar="black", center=true);

/* indicate where the origin is since the images don't show the axes */
cylinder(15, 1, center=true, $fn=100);
