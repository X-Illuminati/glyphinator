/* Unit Test 16: same as test case 05, center=true */
use <../datamatrix.scad>
data_matrix(dm_ascii("Wikipedia"), mark="black", center=true);

/* indicate where the origin is since the images don't show the axes */
cylinder(15, 1, center=true, $fn=100);

