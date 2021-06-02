import FHEW
import math
N = 1024
psi = 282116
omega = 133754304
modulus = 134215681
K = math.ceil(math.log(modulus,2))
#print(K)
R       = 2**((int(math.log(N,2))+1) * int(math.ceil((1.0*K)/(1.0*((int(math.log(N,2))+1))))))
#print(((int(math.log(N,2))+1) * int(math.ceil((1.0*K)/(1.0*((int(math.log(N,2))+1)))))))
accumulator = [[N * [0] for i in range(2)] for _ in range(2)]
a = [2 * [0] for i in range(512)]
result = [[N * [0] for i in range(2)] for _ in range(2)]
# print(accumulator)
secretKey = [[[[[N * [0] for i in range(2)] for _0 in range(8)] for _1 in range(2)] for _2 in range(22)] for _3 in range(32)]
#print(len(secretKey))

Accumulator = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/STARTACCUMULATOR.txt",
    'r')
AccVerilog = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/ACCVERILOG.txt",
    'w')
SecretKey = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PYTHONSECRET.txt",
    'r')
A_vector = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/AVECTOR.txt",
    'r')
#SecretKeyVerilog = open(
#    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/SECRETVERILOG.txt.txt",
#    'w')
Result = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/RESULTACC.txt",
    'r')
AccHex = Accumulator.readlines()
SecretHex = SecretKey.readlines()
#print(len(SecretHex))
ResultHex = Result.readlines()
AHex = A_vector.readlines()



for j in range(2):
    for k in range(N):
        accumulator[0][j][k] = int(AccHex[j * N + k],16)
        #Accumulator.write(hex( accumulator[0][j][k]).replace("L", "")[2:] + "\n")# accumulator contains the same 1024 repeated values by accident but whatever

AccVerilog.write("u32 acc_list[2048] = {\n")
for j in range(32):
    for i in range(32):
        AccVerilog.write("0x00000000, ")
    AccVerilog.write("\n")
for j in range(32):
    for i in range(32):
        if (i==31 and j==31):
            newString = "0x{0} ".format(AccHex[N + 32*j+i].rstrip())
            AccVerilog.write(newString)
        else:
            anotherString = "0x{0}, ".format(AccHex[N + 32*j+i].rstrip())
            AccVerilog.write(anotherString)
            print(anotherString+ anotherString)
    AccVerilog.write("\n")
AccVerilog.write("};\n")

for i_LWE in range(32):
    for k in range(2):
        for a0 in range(22):
            for i in range(8):
                for j in range(2):
                    for l in range(N):
                        secretKey[i_LWE][a0][k][i][j][l] = int(SecretHex[2*8*N*22*2*i_LWE + 2*8*N*22*k + 2*8*N*a0  +8 * N * j + N * i + l], 16)

for j in range(512):
    for k in range(2):
        a[j][k] =int( AHex[j*2+k], 16)



#512*2*23 times this will be run
"""for j_part_mult in range(2):#this is the j_part for the l in 2*digitsG, which is dependent on which NTT result you're multiplying with
    #whereas the j underneath here is used as j==0 and j==1 with the same NTT
    for j in range(2):#32 cycles with the secret key for the j=0, 32 cycle with the secret key for j=1
        for EVENODD in range (2): # 16 cycle with the even BRAM's, 16 cycle with the odd BRAM's
            for PE_cycle_BRAM_EVENODD in range(16): #part of the cycles, first 16 cycles with the even BRAM's
                for NTT_NUMBER in range(4): #part of the block: 4*32*27
                    for PE_NUMBER in range(32):
                        SecretKeyVerilog.write(format( secretKey[NTT_NUMBER*2 + j_part_mult][j][(PE_NUMBER<<1)+(PE_cycle_BRAM_EVENODD<<6)+EVENODD] , '027b'))
                SecretKeyVerilog.write("\n")

"""
# print(hex(secretKey[2][1][4]))
for j in range(2):
    for k in range(N):
        result[0][j][k] = int(ResultHex[j * N + k],
                              16)  # accumulator contains the same 1024 repeated values by accident but whatever


#print(secretKey[0][19][0][2][1][4])
resultAccumulator = FHEW.accumulation(N, modulus, omega, psi, secretKey, accumulator , a)
# print(result[0][0][0], result[0][1][0])



#print(smallDecompose(97734392, modulus))
for j in range(2):
    for k in range(N):
        pass
        #print("Index: ", j * N + k, "Python: ", resultAccumulator[0][j][k], "Palisade: ", result[0][j][k])
#print([j for (i, j) in
#       zip([abs(resultAccumulator[0][i % 2][i // 2] - result[0][i % 2][i // 2]) for i in range(2 * N)], range(2 * N)) if
#       i > 0])
