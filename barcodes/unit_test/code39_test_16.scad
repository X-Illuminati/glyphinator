/* Unit Test 16: "$", "/", "+", "%" */
use <../code39.scad>
// * in the middle is not technically valid,
// but good to know if the behavior changes
code39("*$/+%*", text="char", height=40);
