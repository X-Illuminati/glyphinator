/* Unit Test 00: 10x10 - 3 data bytes, 5 ecc bytes - vector_mode example */
use <../datamatrix.scad>
data_matrix(dm_ascii("123456"), mark="black", vector_mode=true);

