/* Unit Test 19: Canonical Example with center=true */
use <../upc.scad>
EAN_13("5901234123457>", bar=6, space=2, quiet_zone=1, center=true);
//EAN_13("5901234123457>", bar="black", center=true);

/* indicate where the origin is since the images don't show the axes */
cylinder(15, 1, center=true, $fn=100);
