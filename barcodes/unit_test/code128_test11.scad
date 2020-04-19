/* Unit Test 11: Expert mode */
use <../code128.scad>

code_128([QUIET(),START_A(),48,42,42,17,18,19,35,54,STOP(),QUIET()],
		bar="black", expert_mode=true);
