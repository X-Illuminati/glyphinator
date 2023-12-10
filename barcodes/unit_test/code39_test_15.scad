/* Unit Test 15: "0", "J", "T", "*" */
use <../code39.scad>
// * in the middle is not technically valid,
// but good to know if the behavior changes
code39("*0*JT*", text="char", height=40);
