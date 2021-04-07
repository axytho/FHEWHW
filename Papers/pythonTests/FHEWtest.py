import FHEW

N = 1024
psi = 282116
omega = 133754304
modulus = 134215681

accumulator = [[N * [0] for i in range(2)] for _ in range(2)]
result = [[N * [0] for i in range(2)] for _ in range(2)]
# print(accumulator)
secretKey = [[N * [0] for i in range(2)] for _ in range(8)]

Accumulator = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/ACCUMULATOR.txt",
    'r')
SecretKey = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/SECRETKEY.txt",
    'r')
Result = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/RESULT.txt",
    'r')
AccHex = Accumulator.readlines()
SecretHex = SecretKey.readlines()
ResultHex = Result.readlines()

for j in range(2):
    for k in range(N):
        accumulator[0][j][k] = int(AccHex[j * N * 8 + k],
                                   16)  # accumulator contains the same 1024 repeated values by accident but whatever

for i in range(8):
    for j in range(2):
        for l in range(N):
            secretKey[i][j][l] = int(SecretHex[8 * N * j + N * i + l], 16)
# print(hex(secretKey[2][1][4]))
for j in range(2):
    for k in range(N):
        result[0][j][k] = int(ResultHex[j * N * 8 + k],
                              16)  # accumulator contains the same 1024 repeated values by accident but whatever



resultAccumulator = FHEW.addToACAP(N, modulus, omega, psi, secretKey, accumulator)
# print(result[0][0][0], result[0][1][0])
def smallDecompose(t, modulus):
    result = list()
    d=0
    baseG = 7
    Qhalf= modulus >> 1
    print(hex(t), hex(Qhalf))
    if (t < Qhalf):
        d += t
    else:
        d += t - modulus
    #if (1):
    #    print("THISTOO", hex(d))
    for l in range(4):
        r = d % 2 ** baseG

        if (r > 2 ** (baseG - 1) - 1):
            r -= 2 ** baseG

        d -= r

        d >>= baseG
        if (r >= 0):
            result.append(hex(r))
        else:
            result.append(hex(r + modulus))
    return result


#print(smallDecompose(97734392, modulus))
for j in range(2):
    for k in range(N):
        pass
        #print("Index: ", j * N + k, "Python: ", resultAccumulator[0][j][k], "Palisade: ", result[0][j][k])
#print([j for (i, j) in
#       zip([abs(resultAccumulator[0][i % 2][i // 2] - result[0][i % 2][i // 2]) for i in range(2 * N)], range(2 * N)) if
#       i > 0])
