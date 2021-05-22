import math
import NTTMYTEST


def accumulation(N, modulus, rootOfUnity, psi, secretKey, accumulator, a):
    for i_FHEW in range(32):
        for k in range(2):
            a0 = a[i_FHEW][k]
            #print(a0)
            #print(((k==0) and (i_FHEW ==0)), a0)
            if (a0!=0):
                accumulator = addToACAP(N, modulus, rootOfUnity, psi, secretKey[i_FHEW][a0 -1][k], accumulator, ((k==1) and (i_FHEW ==31)), True) #-1 because we only save 22 values.
    return accumulator


def addToACAP(N, modulus, rootOfUnity, psi, secretKeyInput, accumulator, printThis, hwCheck):

    originalSecret = 88888888 #TODO: REMOVE
    #assert(pow(psi,2,modulus)==rootOfUnity)
    baseG = 7
    w_inv = modinv(rootOfUnity, modulus)
    psi_inv = pow(psi, 2**(N*2)-1, modulus) #correct
    digitsG = math.ceil(math.log2(modulus)/baseG)
    ct = list(accumulator[0])
    #[print(hex(element)) for element in ct[0]]
    accumulator[0] = [N*[0] for _ in range(2)]
    #The multiplication will be done before this, so no problem
    #for i in range(2*N,N,-1):
        #ct[i] *= pow(psi, i, q)
    ctEvaluation = [list() for _ in range(2)]
    #modified = [list() for _ in range(2)]
    #hwResult = list()
    #for j in range(2):
     #   modified[j] = IterativeInverseNTTHardware(list(ct[j]) , modulus, psi_inv)
    #ModifiedNTT = open(
    #    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/MODIFIED.txt",
    #    'w')
    #resultINTT = open(
    #    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/RESULTINTT.txt",
    #    'w')
    #for k in range(N):
        #bitReversedModified= indexReverse(modified[0], 10)
        #ModifiedNTT.write(hex(bitReversedModified[k]).replace("L", "")[2:] + "\n")
        #hwResult.append(modified[0][512*(k%2)+(k>>1)])
    #for k in range(N):
    #    resultINTT.write(hex(hwResult[k]).replace("L", "")[2:] + "\n")

    if (False):
        for j in range(2):
            for i in range(1024):
                print("Value we want:",i, "so: ", hex(ct[j][i]))


    for j in range(2):
        ctEvaluation[j] = indexReverse(IterativeInverseNTT(list(indexReverse(list(ct[j]), 10)), modulus, w_inv), 10)
        for a,b in zip(range(2 * N, N, -1), range(N)):
            ctEvaluation[j][b] = (pow(psi, a, modulus) * ctEvaluation[j][b]) % modulus

    if (False):
        for j in range(2):
            for i in range(1024):
                print("Value we want:",i, "so: ", hex(ctEvaluation[j][i]))
    #print([j for (i, j) in
    #       zip([abs(modified[0][i] - ctEvaluation[0][i]) for i in range(N)], range(N)) if i > 0])

    #print("What", hex(ctEvaluation[1][0]),  hex(ctEvaluation[1][64]))
        #print(hex(ctEvaluation[1][900-1]))

    dct = signedDigitDecompose(ctEvaluation,N, modulus, baseG)

    if (False):
        for start in range(32):
            for i in range(512+ start,0,-32):
                print("Value we want:",i, "so: ", hex(dct[6][i]))
    #print(hex(dct[0][0]), hex(dct[2][0]), hex(dct[4][0]), hex(dct[6][0]))
    #print([abs(NTTMYTEST.NTTPoly[i] - dct[0][i]) for i in range(N)])
    #print([ j for (i,j) in zip([abs(NTTMYTEST.NTTPoly[i] - dct[0][i]) for i in range(N)],range(N)) if i > 0 ])
    #[print(hex(element)) for element in dct[0]]#CORRECT!
    #if (False):
    #    for i in range(1024):
    #        print("Value we want:",i, "so: ", hex(dct[1][i]))
    if (printThis):
        TESTVECTOR = open(
            "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/TESTVECTOR.txt",
            'w')
        for l in range(2):
            for k in range(N):
                TESTVECTOR.write(hex(ctEvaluation[l][k]).replace("L", "")[2:] + "\n")


        DCT_IN = open(
            "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/DCT_IN.txt",
            'w')
        for l in range(8):
            for k in range(N):
                DCT_IN.write(hex(dct[l][k]).replace("L", "")[2:] + "\n")


    modifiedDCT = [N*[0] for _ in range(2*digitsG)]
    hwEvaluateDCT = [N * [0] for _ in range(2 * digitsG)]
    evaluateDCT = [N * [0] for _ in range(2 * digitsG)]
    for j in range(2*digitsG):
        for i in range(N):
            modifiedDCT[j][i] = pow(psi, i, modulus) * dct[j][i] % modulus
        evaluateDCT[j] = IterativeForwardNTT(list(modifiedDCT[j]), modulus, 133754304)
        #hwEvaluateDCT[j] = IterativeForwardCT(list(dct[j]), modulus, psi)
    #[print("Index: ", i, "element:", hex(evaluateDCT[0][i]), "check", hex(hwEvaluateDCT[0][i])) for i in range(N)]
    #print([j for (i, j) in
     #      zip([abs(evaluateDCT[0][i] - hwEvaluateDCT[0][i]) for i in range(N)], range(N)) if i > 0])

    ##NTT_OUT = open(
    ##    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PYTHON_NTT_OUT.txt",
    ##    'w')
    ##for k in range(N):
    ##    NTT_OUT.write(hex(evaluateDCT[0][k]).replace("L", "")[2:] + "\n")

    #[print("Index: ", i , "element:" ,hex(evaluateDCT[0][i])) for i in range(N)] #CORRECT
    #print(dct[1][0], NTTMYTEST.SIGNED_IN[2048])
    #for k in range(8):#range(digitsG*2):
        #print(sum([abs(NTTMYTEST.DCT[1024*k+i] - evaluateDCT[k][i]) for i in range(N)]))
        #print(sum([abs(NTTMYTEST.DCT_IN[1024 * k + i] - dct[k][i]) for i in range(N)]))
        #print([j for (i, j) in zip([abs(NTTMYTEST.SIGNED_IN[1024 * k + i] - ctEvaluation[k][i]) for i in range(N)], range(N)) if i > 0])
        #print([j for (i, j) in
               #zip([abs(NTTMYTEST.DCT_OUT[1024 * k + i] - evaluateDCT[k][i]) for i in range(N)], range(N)) if i > 0])
    if (printThis):
        ACC_TEMP = open(
            "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports"
            "/VerilogThesis/test/SECRET_PRODUCT.txt", 'w')
    #print([ j for (i,j) in zip([abs(NTTMYTEST.PALISADE[i] - evaluateDCT[0][i]) for i in range(N)],range(N)) if i > 0 ])
    for j in range(2):
        for l in range(digitsG*2):
            for m in range(N):
               # if (j==0 and l ==1 and m ==0):
               #     print(accumulator[0][j][m], evaluateDCT[j][m], secretKeyInput[l][j][m],
               #           (accumulator[0][j][m] + evaluateDCT[j][m] * secretKeyInput[l][j][m]) % modulus )


                if (printThis and m==0):
                    lResult = 3
                    jResult = 0
                    part = 0
                    add =1
                    for value in range(0,1024,64):
                        pass
                        #print(hex(evaluateDCT[part+2*lResult][value]), hex((secretKeyInput[part+2*lResult][jResult][value]<<33) % modulus),
                        #      hex((evaluateDCT[part+2*lResult][value]*secretKeyInput[part+2*lResult][jResult][value])%modulus),
                        #      hex((evaluateDCT[part+2*lResult][value]*secretKeyInput[part+2*lResult][jResult][value] +  evaluateDCT[part+2*lResult+add][value]*secretKeyInput[part+2*lResult+add][jResult][value])%modulus)  )
                    acc = 0
                    acc2 = 0
                    value = 0
                    for thing in range(4,6,1):
                        acc += evaluateDCT[thing][value]*secretKeyInput[thing][jResult][value]
                    for thing in range(6,8,1):
                        acc2 += evaluateDCT[thing][value]*secretKeyInput[thing][jResult][value]
                    #print("Accumulator:", hex(acc%modulus))
                    #print("Accumulator:", hex(acc2%modulus))
                if (printThis and m==1023 and False):
                    value = 1
                    print(hex(evaluateDCT[1][value]), hex((secretKeyInput[1][0][value]<<33) % modulus), hex((evaluateDCT[1][value]*secretKeyInput[1][0][value])%modulus))
                if (hwCheck):
                    accumulator[0][j][m] = (accumulator[0][j][m] + evaluateDCT[l][m] * originalSecret) % modulus
                else:
                    accumulator[0][j][m] = (accumulator[0][j][m] + evaluateDCT[l][m] * secretKeyInput[l][j][m]) % modulus
                # Secret key structure in memory:
                # Pieces of 4*32*27 bits
               # for the whole ACCloop:
                # for m in range N>>PE:
                #    for l in range digitsG:
                #    blocks of

    for j in range(2):
        for m in range(N):
            if (printThis):
                ACC_TEMP.write(hex(accumulator[0][j][m]).replace("L", "")[2:] + "\n")

    return accumulator




def signedDigitDecompose(ct,N, modulus, baseG):
    #baseG = 7
    decomposedCt= [N*[0] for _ in range(math.ceil(math.log2(modulus)/baseG)*2)]
    d = 0
    Qhalf = math.floor(modulus >> 1)
    for j in range(2):
        for k in range(N):
            t = ct[j][k]


            if (t < Qhalf):
                d += t
            else:
                d += t-modulus
      #      if (j==0 and k==0):
      #          print("THIS", hex(d))
            for l in range(math.ceil(math.log2(modulus)/baseG)):
                r = d % 2**baseG
                if (r > 2**(baseG-1)-1):
                    r -= 2**baseG
                d -= r
                d >>= baseG
            #    if ((j+2*l == 2) and (k==0)):
            #        print("NOT TWICE", l)
            #        print(hex(r), hex(r+modulus))
                if (r>=0):
                    decomposedCt[j + 2*l][k] += r
                else:
                    decomposedCt[j + 2 * l][k] += r + modulus
            d = 0
    return decomposedCt
"""
def signedDigitDecomposeHWSTYLE(ct,N, modulus, baseG):
    #baseG = 7
    decomposedCt= [N*[0] for _ in range(math.ceil(math.log2(modulus)/baseG)*2)]
    d = 0
    Qhalf = math.floor(modulus >> 1)
    for j in range(2):
        for k in range(N):
            t = ct[j][k]
            tSelect = (t - modulus//2) < 0
            tMinusQ = t - modulus
            if (tSelect == 1):
                tOut = tMinusQ
            elif (tSelect == 0):
                tOut = t
            else:
                print("SHOULDN4T HAPPENB")
                raise
            rLowest = tOut % 128
            rSelectLow = (rLowest - 64) < 0
            rLowMinusBasePlusModulus = rLowest + (modulus - 128)
            if (rSelectLow):
                rLowWriteback = rLowMinusBasePlusModulus
            else:
                rLowWriteback = rLowest


            decomposedCt[j][k]
            decomposedCt[j+2][k]
            decomposedCt[j+4][k]
            decomposedCt[j+6][k]

    return decomposedCt
"""
def IterativeForwardNTT(arrayIn, P, W):
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


    return arrayOut


def IterativeForwardCT(arrayIn, P, psi):
    arrayOut = [0] * len(arrayIn)
    N = len(arrayIn)
    for idx in range(N):
        arrayOut[idx] = arrayIn[idx]
    v = int(math.log(N, 2))

    # 0....
    #
    for i in range(0, v):

        for j in range(0, (2 ** i)):
            for k in range(0, (2 ** (v - i - 1))):
                s = j * (2 ** (v - i)) + k
                t = s + (2 ** (v - i - 1))


                index = intReverse(2**i+j, v)
                w = pow(psi, index, P)
                as_temp = arrayOut[s]
                temp = arrayOut[t]
                at_temp = arrayOut[t] * w

                arrayOut[s] = (as_temp + at_temp) % P
                arrayOut[t] = ((as_temp - at_temp) ) % P

                if (i==0 and j==0 and k==0):
                    print(index)
                    print(hex(as_temp), hex(temp), hex(at_temp % P), hex(arrayOut[s]), hex(arrayOut[t]))
                    # you cannot compare w!!!


    return arrayOut

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

#DIT == Cooley Tukey, DIF == Gentleman Sande, this is the latter
def IterativeInverseNTTMODIFIED(arrayIn, P, psiInverse):
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
                sBitReversed = intReverse(s, v)
                tBitReversed = intReverse(t, v)
                index = (1 + 2 * k) << i
                w = pow(psiInverse, index ,  P)


                as_temp = arrayOut[sBitReversed]
                at_temp = arrayOut[tBitReversed]

                arrayOut[sBitReversed] = (as_temp + at_temp) % P
                arrayOut[tBitReversed] = ((as_temp - at_temp) * w) % P


    N_inv = modinv(N, P)
    for i in range(N):
        arrayOut[i] = (arrayOut[i] * N_inv) % P #divide by N mod P
    return arrayOut

def IterativeInverseNTTHardware(arrayIn, P, psiInverse):
    arrayOut = [0] * len(arrayIn)
    N = len(arrayIn)
    v = int(math.log(N, 2))
    arrayOut = indexReverse(list(arrayIn), v)




    for i in range(0, v):
        for j in range(0, (2 ** i)):
            for k in range(0, (2 ** (v - i - 1))):
                s = j * (2 ** (v - i)) + k
                t = s + (2 ** (v - i - 1))
                index = ((1 + 2 * k) % N) << i
                w = pow(psiInverse, index ,  P)


                as_temp = arrayOut[s]
                at_temp = arrayOut[t]

                arrayOut[s] = (as_temp + at_temp) % P
                arrayOut[t] = ((as_temp - at_temp) * w) % P


    N_inv = modinv(N, P)
    for i in range(N):
        arrayOut[i] = (arrayOut[i] * N_inv) % P #divide by N mod P
    return indexReverse(list(arrayOut), v)

def omegaBitReversed(psi, N,q):
    #bitinverse is a reversible operation
    omegaNormal = N * [0]
    for i in range(N):
        omegaNormal[i] = pow(psi, i, q)
    return indexReverse(omegaNormal, math.floor(math.log2(N)))

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

"""
N = 1024
psi = 282116
omega = 133754304
modulus = 134215681




resultAccumulator = addToACAP(N, modulus, omega, psi, secretKey, accumulator)
print(resultAccumulator)
"""