from sympy import ntt
import math
from NTT import NTT as nttJyun

def omegaBitReversed(psi, N,q):
    #bitinverse is a reversible operation
    omegaNormal = N * [0]
    for i in range(N):
        omegaNormal[i] = pow(psi, i, q)
    return indexReverse(omegaNormal, math.floor(math.log2(N)))


def ForwardTransformToBitReverse(element, modulus, psi):
    result = list(element)
    n = 1024
    t = n
    m=1
    omegaReversed = omegaBitReversed(psi, n, modulus)
    print(len(omegaReversed))
    while m < n:
        t = int(t/2)
        for i in range(0,m):
            j1 = 2*i*t
            j2 = j1 + t -1
            indexOmega = m + i
            S = omegaReversed[indexOmega]
            for j in range(j1, j2+1):
                U = result[j]
                V = result[j+t] * S
                result[j] = (U+V) % modulus
                result[j+t] = (U-V) % modulus
        #for loop
        m = m*2

    return result
            #omega = pow(rootOfUnity,  indexOmega, modulus)

def IterativeInverseNTT(arrayIn, P, W):
    arrayOut = [0] * len(arrayIn)
    N = len(arrayIn)

    for idx in range(N):
        arrayOut[idx] = arrayIn[idx]


    v = int(math.log(N, 2))

    for i in range(0, v):
        for j in range(0, (2 ** i)):
            for k in range(0, (2 ** (v - i - 1))):
                s = j * (2 ** (v - i)) + k
                t = s + (2 ** (v - i - 1))

                w = (W ** ((2 ** i) * k)) % P

                as_temp = arrayOut[s]
                at_temp = arrayOut[t]

                arrayOut[s] = (as_temp + at_temp) % P
                arrayOut[t] = ((as_temp - at_temp) * w) % P


    N_inv = modinv(N, P)
    for i in range(N):
        arrayOut[i] = (arrayOut[i] * N_inv) % P #divide by N mod P
    return arrayOut


def PalisadeInverseTransform(element, modulus, psi):
    result = list(element)
    n = 1024
    t = 1
    m=n
    omegaReversed = omegaBitReversed(pow(psi,2*n-1, modulus), n, modulus)
    while m > 1:
        j1 = 0
        h = m >> 1
        for i in range(0,h):
            j2 = j1 + t - 1
            indexOmega = h + i
            S = omegaReversed[indexOmega]
            for j in range(j1, j2+1):
                U = result[j]
                V = result[j+t]
                result[j] = (U+V) % modulus
                result[j+t] = (U-V)*S % modulus
            j1 = j1 + 2*t
        #for loop
        m >>= 1
        t <<= 1
    N_inv = modinv(n, modulus)
    for i in range(n):
        result[i] = (result[i] * N_inv) % modulus  # divide by N mod P
    return result

def modinv(a, m):
    g, x, y = egcd(a, m)
    if g != 1:
        raise Exception('Modular inverse does not exist')
    else:
        return x % m

def egcd(a, b):
    if a == 0:
        return (b, 0, 1)
    else:
        g, y, x = egcd(b % a, a)
        return (g, x - (b // a) * y, y)


def IterativeForwardNTT(arrayIn, P, W, R, DEBUG_MODE_NTT):
    #########################################################
    if DEBUG_MODE_NTT:
        A_ntt_interm_1 = open("NTT_DIN_DEBUG_1.txt","w") # Just result
        A_ntt_interm_2 = open("NTT_DIN_DEBUG_2.txt","w") # BTF inputs
    #########################################################

    arrayOut = [0] * len(arrayIn)
    N = len(arrayIn)

    for idx in range(N):
        arrayOut[idx] = arrayIn[idx]

    #########################################################
    if DEBUG_MODE_NTT:
        A_ntt_interm_1.write("------------------------------ input: \n")
        A_ntt_interm_2.write("------------------------------ input: \n")
        for idx in range(N):
            A_ntt_interm_1.write(str(arrayOut[idx])+"\n")
            A_ntt_interm_2.write(str(arrayOut[idx])+"\n")
    #########################################################

    v = int(math.log(N, 2))

    for i in range(0, v):
        #########################################################
        if DEBUG_MODE_NTT:
            A_ntt_interm_1.write("------------------------------ stage: "+str(i)+"\n")
            A_ntt_interm_2.write("------------------------------ stage: "+str(i)+"\n")
        #########################################################
        for j in range(0, (2 ** i)):
            for k in range(0, (2 ** (v - i - 1))):
                s = j * (2 ** (v - i)) + k
                t = s + (2 ** (v - i - 1))

                w = (W ** ((2 ** i) * k)) % P

                as_temp = arrayOut[s]
                at_temp = arrayOut[t]

                arrayOut[s] = (as_temp + at_temp) % P
                arrayOut[t] = ((as_temp - at_temp) * w) % P

                #########################################################
                if DEBUG_MODE_NTT:
                    A_ntt_interm_2.write((str(s)+" "+str(t)+" "+str(((2 ** i) * k))).ljust(16)+"("+str(as_temp).ljust(12)+" "+str(at_temp).ljust(12)+" "+str((w*R) % P).ljust(12)+") -> ("+str(arrayOut[s]).ljust(12)+" "+str(arrayOut[t]).ljust(12)+")"+"\n")
                #########################################################

        #########################################################
        if DEBUG_MODE_NTT:
            for idx in range(N):
                A_ntt_interm_1.write(str(arrayOut[idx])+"\n")
        #########################################################

    #########################################################
    if DEBUG_MODE_NTT:
        A_ntt_interm_1.write("------------------------------ result: \n")
        A_ntt_interm_2.write("------------------------------ result: \n")
        for idx in range(N):
            A_ntt_interm_1.write(str(arrayOut[idx])+"\n")
            A_ntt_interm_2.write(str(arrayOut[idx])+"\n")
    #########################################################

    #########################################################
    if DEBUG_MODE_NTT:
        A_ntt_interm_1.close()
        A_ntt_interm_2.close()
    #########################################################

    return arrayOut

def intReverse(a,n):
    b = ('{:0'+str(n)+'b}').format(a) # "{0:b} means print in binary
    return int(b[::-1],2)

# Bit-Reversed index
def indexReverse(a,r):
    n = len(a)
    b = [0]*n
    for i in range(n):
        rev_idx = intReverse(i,r)
        b[rev_idx] = a[i]
    return b

NTTFile = open("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/ACCUMULATOR.txt", 'r')
#NTTFile = open("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/NTTDATAPALISADE_IN.txt", 'r')
NTTHex = NTTFile.readlines()
PALISADEFile = open("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/TESTVECTOR.txt", 'r')
#PALISADEFile = open("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/NTTDATAPALISADE_OUT.txt", 'r')
PALISADEHex = PALISADEFile.readlines()
NTTPoly =[]
PALISADE =[]

for k in range(1024):
    #print(hex)
    NTTPoly.append(int(NTTHex[k], 16))
    #print(int(hex, 16))
for k in range(1024):
    PALISADE.append(int(PALISADEHex[k], 16))
modulus = 134215681
psi = 282116
newPolyN = list()
#Jyun_bitReverse = indexReverse(NTTPoly,10) # I don't know

#transform = ntt(list(NTTPoly), modulus)
Jyun = nttJyun()
transformJyun = Jyun.intt(list(NTTPoly), modulus, len(NTTPoly), 133754304)
#transformJyun2 = Jyun.intt(list(NTTPoly), modulus, len(NTTPoly), 282116)
w_inv   = modinv(133754304, modulus)
transformMert = IterativeInverseNTT(list(NTTPoly), modulus, w_inv)
pythonPalisade = PalisadeInverseTransform(list(NTTPoly), modulus, psi)
transformJyunChanged = []
transformJyunChanged2 = []
transformMertChanged = []
for i in range(1024):
    transformJyunChanged.append((pow(48329653,i, modulus)* transformJyun[i]) % modulus)
    #transformJyunChanged2.append(pow(282116, 2048-i, modulus) * transformJyun2[i] % modulus)
    transformMertChanged.append((pow(282116, 2048-i, modulus) * transformMert[i]) % modulus)


transformMertRev = indexReverse(transformMert,10)
#psiMert = IterativeForwardNTT(list(newPolyN), modulus, 133754304, 200000000, False)
#transformPalisade = ForwardTransformToBitReverse(list(NTTPoly), modulus, 282116)
#transformPalisadeRev = indexReverse(transformPalisade,10)
#r = Jyun.NthRootOfUnity(modulus, 1024)
#transformJyun3 = Jyun.ntt(list(NTTPoly), modulus, len(NTTPoly), r)
#print("Root of unity by Jyun: ", r)
for i in range(len(NTTPoly)):
    #print("Index", i , "NTTMERT: ", hex(transformMertRev[i]), "NTTPalisadePython: ", hex(transformPalisadeRev[i]), " NTTPalisade: ", hex(PALISADE[i]), "Jyun: ", hex(transformJyun[i]), "Jyun2: ", hex(transformJyun[i]))
    print("Index:", i, "NTTwithPsi:", hex(transformMertChanged[i]), "pythonPalisade: ", hex(pythonPalisade[i]), "Palisade: ", hex(PALISADE[i]), "NTTwithoutpsi: ", hex(transformMert[i]), "NTT bitreversed:",hex(transformMertRev[i]) ,"Jyunbefore: ", hex(transformJyun[i]))
          #""Jyun3: ",hex(transformJyun3[i]),  " \n")



