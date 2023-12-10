/* Unit Test 05: Example from Wikipedia - centered */
use <../code39.scad>
linear_extrude(6, center=true)
code39("*WIKIPEDIA*", text="char", height=40, center=true);

/* indicate where the origin is since the images don't show the axes */
cylinder(15, 1, center=true, $fn=100);
