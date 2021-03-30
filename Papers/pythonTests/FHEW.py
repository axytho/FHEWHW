import math

def addToACAP(N, modulus, rootOfUnity, psi, secretKeyInput, accumulator):
    assert(pow(psi,2,modulus)==rootOfUnity)
    baseG = 7
    w_inv = modinv(rootOfUnity, modulus)
    digitsG = math.ceil(math.log2(modulus)/baseG)
    ct = list(accumulator[0])
    #[print(hex(element)) for element in ct[0]]
    accumulator[0] = [N*[0] for _ in range(2)]
    #The multiplication will be done before this, so no problem
    #for i in range(2*N,N,-1):
        #ct[i] *= pow(psi, i, q)
    ctEvaluation = [list() for _ in range(2)]
    for j in range(2):
        ctEvaluation[j] = indexReverse(IterativeInverseNTT(list(indexReverse(list(ct[j]), 10)), modulus, w_inv), 10)
        for a,b in zip(range(2 * N, N, -1), range(N)):
            ctEvaluation[j][b] = (pow(psi, a, modulus) * ctEvaluation[j][b]) % modulus
            #print(hex(ctEvaluation[j][b]))


    dct = signedDigitDecompose(ctEvaluation,N, modulus, baseG)
    #CORRECT!
    evaluateDCT = [N*[0] for _ in range(2*digitsG)]
    for j in range(2*digitsG):
        for i in range(N):
            evaluateDCT[j][i] = pow(psi, i, modulus) * dct[j][i] % modulus
        evaluateDCT[j] = IterativeForwardNTT(list(dct[j]), modulus, rootOfUnity)
    [print(hex(element)) for element in evaluateDCT[1]]
    for j in range(2):
        for l in range(digitsG*2):
            for m in range(N):
                accumulator[0][j][m] = (accumulator[0][j][m] + evaluateDCT[j][m] * secretKeyInput[l][j][m]) % modulus
    return accumulator


def signedDigitDecompose(ct,N, modulus, baseG):
    #baseG = 7
    decomposedCt= [N*[0] for _ in range(math.ceil(math.log2(modulus)/baseG)*2)]
    d = 0
    for j in range(2):
        for k in range(N):
            t = ct[j][k]
            if (t < modulus/2):
                d += t
            else:
                d = t-modulus
            for l in range(math.ceil(math.log2(modulus)/baseG)):
                r = d % 2**baseG
                if (r > 2**(baseG-1)):
                    r -= 2**baseG
                d -= r
                d >>= baseG
                if (r>=0):
                    decomposedCt[j + 2*l][k] += r
                else:
                    decomposedCt[j + 2 * l][k] += r + modulus
    return decomposedCt


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