/* Unit Test 00: Canonical Example with mixed symbologies */
use <../code128.scad>

code_128(concat(cs128_b("RI"),
		cs128_c([4,7,6,3,9,4,6,5,]),
		cs128_b("2CH")),
	bar="black");
