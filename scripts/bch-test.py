#!/usr/bin/python3
###############################################################################
# bch-test.py -- bch test calculator
###############################################################################
# Copyright 2017 Chris Baker
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################

#calculate BCH remainder for value v using polynomial p
#vw is the bit width of v
#pw is the bit width of the polynomial
#bit width of the remainder will be less than pw-1
def calc_bch(v, vw, p, pw):
	#print("v=%X p=%X" %(v,p))
	v=v<<(pw-1)
	for i in range(vw-1,-1,-1):
		test=v^(p<<i)
		#print("%d: v`(%X) ^ p`(%X) = %X" %(i, v,p<<i,test))
		if (test<v):
			v=test
	return v


# Example for v=15, p=1335 (BCH 15,5)
#  _x3+x2__________
#g )011110000000000
#    10100110111000
#    --------------
#    01010110111000
#     1010011011100
#    --------------
#     0000101100100
#     r=x8+x6+x5+x2 = 356

# Example for v=9, p=1335 (BCH 15,5)
#  _x3+x+1_________
#g )010010000000000
#    10100110111000
#    --------------
#    00110110111000
#      101001101110
#    --------------
#      011111010110
#       10100110111
#      ------------
#       01011100001
#     r=x9+x7+x6+x5+1 = 737

p=1335

#pre-calculate result for 32 possible format codes
for i in range(32):
	print("i=%d, result=%d" % (i,calc_bch(i, 5, p, 11)))
