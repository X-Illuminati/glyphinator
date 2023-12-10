/* Unit Test 13: test with center=true */
use <../code128.scad>

code_128(concat(cs128_b("RI"),
		cs128_c([4,7,6,3,9,4,6,5,]),
		cs128_b("2CH")),
	bar=6, space=3, quiet_zone=1, center=true);

/* indicate where the origin is since the images don't show the axes */
cylinder(15, 1, center=true, $fn=100);
