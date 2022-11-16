import numpy as np
from NTT import NTT
"""

M = 2013265921
N = 2048
r = ntt.NthRootOfUnity(M, N)
print("Modulus is %d" % M)
print("The number of FFT points is %d" % N)
print("The %dth root of unity is %d" % (N, r))
if ntt.isNthRootOfUnity(M, N, r):
    print("%d to power of %d is congruent to 1 modulo %d" % (r, N, M))
else:
    print("%d to power of %d is not congruent to 1 modulo %d" % (r, N, M))
"""
ntt = NTT()
M = (1<<64)-(1<<32)+1
print(hex(M))
poly_old = [1, 2, 3, 4]     # 4x^3+3x^2+2x+1
poly = [0xcef967e3e1d0860e,
0x44be7570bcd4f9df,
0xf4848ed283e858f2,
0xa3a3a47eeb6f76f6,
0xa12d1d0b69c4108b,
0xeb285d19459ef6c3,
0x10d812558ad9c103,
0xd19d3e319d1b6b4a]
for i in range(len(poly)):
    poly[i] = int(poly[i])

print("Modulus : %d" % M)
print("Polynomial : ", poly)
N = len(poly)
w = 18446744069397807105
print(hex(w))
assert(w**N%M == 1)
ntt_poly = ntt.ntt(poly, M, N, w)
for element in ntt_poly:
    print(hex(element))
#intt_poly = ntt.intt(ntt_poly, M, N, w)
print("Polynomial degree : %d" % (N - 1))
print("Primitive %dth root of unity : %d" % (N, w))
print("NTT(poly) = ", ntt_poly)
#print("Inverse NTT : ", intt_poly)
