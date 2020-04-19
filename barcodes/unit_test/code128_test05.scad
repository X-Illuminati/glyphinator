/* Unit Test 05: Test concatenating flag */
use <../code128.scad>

code_128(concat(
		cs128_b("W"),
		cs128_b("ikipedia", concatenating=true)),
	bar="black");
