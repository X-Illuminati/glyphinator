/* Unit Test 10: FNC4 High ASCII */
use <../code128.scad>

code_128(cs128_a(str(
		"ABC",
		FNC4(), cs128_fnc4_high_helper("¡"),
		"!",
		cs128_fnc4_high_helper(str(
			FNC4(), FNC4(), "¢£¤¥Þ", FNC4()
		)), "^",
		cs128_fnc4_high_helper("ÀÁÂÃ"), FNC4(), FNC4(),
		"XYZ"
	)),
	bar="black");
