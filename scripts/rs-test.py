#!/usr/bin/python3
###############################################################################
# rs-test.py -- reed solomon test calculator
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

import binascii

##10x10 example - 3 data, 5 ecc:
##Codeword  1   2   3 (  4  5  6  7   8)
##Decimal 142 164 186 (114 25  5 88 102)
##Hex      8E  A4  BA ( 72 19 05 58  66)
data=bytearray((142,164,186))
data_size=3
ecc_size=5

# A = 66 (129 70) +138 234 82 82 95
data=bytearray("A", encoding="ascii")
for i in range(len(data)): data[i]=data[i]+1
data_size=3
ecc_size=5

##12x12 example - 5 data, 7 ecc:
#1 =10010011=0x93=147="17"
#2 =10000010=0x82=130="00"
#3 =10001101=0x8D=141="11"
#4 =11000010=0xC2=194="64"
#5 =10000001=0x81=129
#e1=10010011=0x93=147
#e2=10111010=0xBA=186
#e3=01011000=0x58=88
#e4=11101100=0xEC=236
#e5=00111000=0x38=56
#e6=11100011=0xE3=227
#e7=11010001=0xD1=209
data=bytearray((147,130,141,194))
data_size=5
ecc_size=7

##14x14 example - 8 data, 10 ecc
data=bytearray((230, 209, 42, 117, 151, 254, 84, 50))
data_size=8
ecc_size=10

##16x16 example - 12 data, 12 ecc:
data=bytearray("Wikipedia", encoding="ascii")
for i in range(len(data)): data[i]=data[i]+1
data_size=12
ecc_size=12

##18x18 example - 18 data, 14 ecc
data=bytearray("Hourez Jonathan", encoding="ascii")
for i in range(len(data)): data[i]=data[i]+1
data_size=18
ecc_size=14

##20x20 example - 22 data, 18 ecc
#FNC1+01034531200000111709112510ABCD1234
data=bytearray((232,131,133,175,161,150,130,130,141,147,139,141,155,140,66,67,68,69,142,164))
data_size=22
ecc_size=18

##22x22 example - 30 data, 20 ecc:
#data=bytearray("http://www.idautomation.com", encoding="ascii")
#for i in range(len(data)): data[i]=data[i]+1
#data_size=30
#ecc_size=20

#these are computed factor table for GF(2^8) poly 301
#the key is the number of ecc bytes
factor_tables={
5:bytes((228,48,15,111,62)), # Factor table for 5 ecc bytes
7:bytes((23,68,144,134,240,92,254)), # Factor table for 7 ecc bytes
10:bytes((28,24,185,166,223,248,116,255,110,61)),
12:bytes((41,153,158,91,61,42,142,213,97,178,100,242)),
14:bytes((156,97,192,252,95,9,157,119,138,45,18,186,83,185)),
18:bytes((83,195,100,39,188,75,66,61,241,213,109,129,94,254,225,48,90,188)),
20:bytes((15,195,244,9,233,71,168,2,188,160,153,145,253,79,108,82,27,174,186,172)),
}

print("data bytes:", end=" ");print(binascii.b2a_hex(data))
print("decimal:", end=" ")
for i in data: print(i,end=",")
print()


# The algorithms
# based on notes from [grandzebu.net](http://grandzebu.net/informatique/codbar-en/datamatrix.htm)
# and [barcode-coder.com](http://barcode-coder.com/en/datamatrix-specification-104.html)

pad_start=len(data)
ecc=bytearray(ecc_size)
t=0

# Calculate padding bytes
for i in range(pad_start,data_size):
	if (i==pad_start):
		data.append(129)
	else:
		p=((((149*(i+1))%253)+130)%254)
		data.append(254 if (p==0) else p)

print("pad bytes:", end=" ");print(binascii.b2a_hex(data[pad_start:data_size]))
print("decimal:", end=" ")
for i in data[pad_start:data_size]: print(i,end=",")
print()

# The datamatrix reed-solomon calculations operate in a Galois Field,
# GF(2^8) with polynomial 301.
# The arithmetic operations are XOR and Multiplication

# Multiplication implemented with Galois log and antilog.
# Mult(a,b) = Alog((Log(a) + Log(b)) Mod 255)
# Precomputed arrays:
galois_log=(-255, 255, 1, 240, 2, 225, 241, 53, 3, 38, 226, 133, 242, 43, 54, 210, 4, 195,39, 114, 227, 106, 134, 28, 243, 140, 44, 23, 55, 118, 211, 234, 5, 219, 196, 96, 40, 222, 115, 103, 228, 78, 107, 125, 135, 8, 29, 162, 244, 186, 141, 180, 45, 99, 24, 49, 56, 13, 119, 153, 212, 199, 235, 91, 6, 76, 220, 217, 197, 11, 97,184, 41, 36, 223, 253, 116, 138, 104, 193, 229, 86, 79, 171, 108, 165, 126, 145, 136, 34, 9, 74, 30, 32, 163, 84, 245, 173, 187, 204, 142, 81, 181, 190, 46, 88, 100, 159, 25, 231, 50, 207, 57, 147, 14, 67, 120, 128, 154, 248, 213, 167, 200, 63, 236, 110, 92, 176, 7, 161, 77, 124, 221, 102, 218, 95, 198, 90, 12, 152, 98, 48, 185, 179, 42, 209, 37, 132, 224, 52, 254, 239, 117, 233, 139, 22, 105, 27, 194, 113, 230, 206, 87, 158, 80, 189, 172, 203, 109, 175, 166, 62, 127, 247, 146, 66, 137, 192, 35, 252, 10, 183, 75, 216, 31, 83, 33, 73, 164, 144, 85, 170, 246, 65, 174, 61, 188, 202, 205, 157, 143, 169, 82, 72, 182, 215, 191, 251, 47, 178, 89, 151, 101, 94, 160, 123, 26, 112, 232, 21, 51, 238, 208, 131, 58, 69, 148, 18, 15, 16, 68, 17, 121, 149, 129, 19, 155, 59, 249, 70, 214, 250, 168, 71, 201, 156, 64, 60, 237, 130, 111, 20, 93, 122, 177, 150)
galois_antilog=(1, 2, 4, 8, 16, 32, 64, 128, 45, 90, 180, 69, 138, 57, 114, 228, 229, 231, 227, 235, 251, 219, 155, 27, 54, 108, 216, 157, 23, 46, 92, 184, 93, 186, 89, 178, 73, 146, 9, 18, 36, 72, 144, 13, 26, 52, 104, 208, 141, 55, 110, 220, 149, 7, 14, 28, 56, 112, 224, 237, 247, 195, 171, 123, 246, 193, 175, 115, 230, 225, 239, 243, 203, 187, 91, 182, 65, 130, 41, 82, 164, 101, 202, 185, 95, 190, 81, 162, 105, 210, 137, 63, 126, 252, 213, 135, 35, 70, 140, 53, 106, 212, 133, 39, 78, 156, 21, 42, 84, 168, 125, 250, 217, 159, 19, 38, 76, 152, 29, 58, 116, 232, 253, 215, 131, 43, 86, 172, 117, 234, 249, 223, 147, 11, 22, 44, 88, 176, 77, 154, 25, 50, 100, 200, 189, 87, 174, 113, 226, 233, 255, 211, 139, 59, 118, 236, 245, 199, 163, 107, 214, 129, 47, 94, 188, 85, 170, 121, 242, 201, 191, 83, 166, 97, 194, 169, 127, 254, 209, 143, 51, 102, 204, 181, 71, 142, 49, 98, 196, 165, 103, 206, 177, 79, 158, 17, 34, 68, 136, 61, 122, 244, 197, 167, 99, 198, 161, 111, 222, 145, 15, 30, 60, 120, 240, 205, 183, 67, 134, 33, 66, 132, 37, 74, 148, 5, 10, 20, 40, 80, 160, 109, 218, 153, 31, 62, 124, 248, 221, 151, 3, 6, 12, 24, 48,96, 192, 173, 119, 238, 241, 207, 179, 75, 150, 1)

def galois_mult(a, b):
	return galois_antilog[(galois_log[a]+galois_log[b])%255]

def galois_pow(a, b):
	if (b==0): return 1
	if (b==1): return a
	r=a
	for i in range(b-1):
		r=galois_mult(r,a)
	return r

# generate a factor table if it doesn't already exist
def factor_table(ecc_size):
	try:
		return factor_tables[ecc_size]
	except(KeyError):
		factors=bytearray(ecc_size)
		for i in range(ecc_size+1):
			for j in range(i-1,-1,-1):
				factors[j]=galois_mult(factors[j],galois_pow(2,i))
				if (j>0):
					factors[j]=factors[j] ^ factors[j-1]
		print("**generator factors: ", end=" ");
		print(binascii.b2a_hex(factors))
		print("**decimal:", end=" ")
		for i in factors: print(i,end=",")
		print()
		return factors

f=factor_table(ecc_size)

# calculate RS ECC - modified to result in forward byte order
for i in range(data_size):
	t=data[i] ^ ecc[0]
	for j in range(ecc_size):
		if (t==0):
			ecc[j]=0
		else:
			ecc[j]=galois_antilog[(galois_log[t]+galois_log[f[ecc_size-j-1]])%255]
		if ((j+1)<ecc_size):
			ecc[j]=ecc[j+1]^ecc[j]
	#print("int(%d):"%i, end=" ")
	#for k in ecc: print(k,end=" ")
	#print()

print("ecc bytes: ", end=" ");print(binascii.b2a_hex(ecc))
print("decimal:", end=" ")
for i in ecc: print(i,end=",")
print()
