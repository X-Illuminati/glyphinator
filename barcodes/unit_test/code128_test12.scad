/* Unit Test 12: Expert mode - missing start symbols */
use <../code128.scad>

code_128([1, 16, 33, 73, 99, 58], bar="black", expert_mode=true);
