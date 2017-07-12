/*
 * @file 
 * @author  TPOC: palisade@njit.edu
 *
 * @copyright Copyright (c) 2017, New Jersey Institute of Technology (NJIT)
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice, this
 * list of conditions and the following disclaimer in the documentation and/or other
 * materials provided with the distribution.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
 /*
This code exercises the Proxy Re-Encryption capabilities of the NJIT Lattice crypto library.
In this code we:
- Generate a key pair.
- Encrypt a string of data.
- Decrypt the data.
- Generate a new key pair.
- Generate a proxy re-encryption key.
- Re-Encrypt the encrypted data.
- Decrypt the re-encrypted data.
We configured parameters (namely the ring dimension and ciphertext modulus) to provide a level of security roughly equivalent to a root hermite factor of 1.007 which is generally considered secure and conservatively comparable to AES-128 in terms of computational work factor and may be closer to AES-256.

*/

#include <iostream>
#include <fstream>


#include "palisade.h"


#include "cryptocontexthelper.h"

#include "encoding/byteplaintextencoding.h"
#include "encoding/packedintplaintextencoding.h"

#include "utils/debug.h"
#include <random>

#include "math/nbtheory.h"

using namespace std;
using namespace lbcrypto;


#include <iterator>

void ArbLTVInnerProductPackedArray();
void ArbBVInnerProductPackedArray();
void ArbFVInnerProductPackedArray();
void ArbFVEvalMultPackedArray();

int main() {

	//LTVAutomorphismIntArray();

	std::cout << "\n===========LTV TESTS (INNER-PRODUCT-ARBITRARY)===============: " << std::endl;

	ArbLTVInnerProductPackedArray();

	std::cout << "\n===========BV TESTS (INNER-PRODUCT-ARBITRARY)===============: " << std::endl;

	ArbBVInnerProductPackedArray();

	std::cout << "\n===========FV TESTS (INNER-PRODUCT-ARBITRARY)===============: " << std::endl;

	ArbFVInnerProductPackedArray();

	std::cout << "\n===========FV TESTS (EVALMULT-ARBITRARY)===============: " << std::endl;

	ArbFVEvalMultPackedArray();

	std::cout << "Please press any key to continue..." << std::endl;

	cin.get();
	return 0;
}

void ArbBVInnerProductPackedArray() {

	usint m = 22;
	usint p = 89;
	BigInteger modulusP(p);
	/*BigInteger modulusQ("577325471560727734926295560417311036005875689");
	BigInteger squareRootOfRoot("576597741275581172514290864170674379520285921");*/
	BigInteger modulusQ("955263939794561");
	BigInteger squareRootOfRoot("941018665059848");
	//BigInteger squareRootOfRoot = RootOfUnity(2*m,modulusQ);
	//std::cout << squareRootOfRoot << std::endl;
	BigInteger bigmodulus("80899135611688102162227204937217");
	BigInteger bigroot("77936753846653065954043047918387");
	//std::cout << bigroot << std::endl;

	auto cycloPoly = GetCyclotomicPolynomial<BigVector, BigInteger>(m, modulusQ);
	ChineseRemainderTransformArb<BigInteger, BigVector>::GetInstance().SetCylotomicPolynomial(cycloPoly, modulusQ);

	PackedIntPlaintextEncoding::SetParams(modulusP, m);

	float stdDev = 4;

	usint batchSize = 8;

	shared_ptr<ILParams> params(new ILParams(m, modulusQ, squareRootOfRoot, bigmodulus, bigroot));

	shared_ptr<EncodingParams> encodingParams(new EncodingParams(modulusP,PackedIntPlaintextEncoding::GetAutomorphismGenerator(modulusP),batchSize));

	shared_ptr<CryptoContext<Poly>> cc = CryptoContextFactory<Poly>::genCryptoContextBV(params, encodingParams, 8, stdDev);

	cc->Enable(ENCRYPTION);
	cc->Enable(SHE);

	// Initialize the public key containers.
	LPKeyPair<Poly> kp = cc->KeyGen();

	vector<shared_ptr<Ciphertext<Poly>>> ciphertext1;
	vector<shared_ptr<Ciphertext<Poly>>> ciphertext2;

	std::vector<usint> vectorOfInts1 = { 1,2,3,4,5,6,7,8,0,0 };
	PackedIntPlaintextEncoding intArray1(vectorOfInts1);

	std::cout << "Input array 1 \n\t" << intArray1 << std::endl;


	std::vector<usint> vectorOfInts2 = { 1,2,3,2,1,2,1,2,0,0 };
	PackedIntPlaintextEncoding intArray2(vectorOfInts2);

	std::cout << "Input array 2 \n\t" << intArray2 << std::endl;

	cc->EvalSumKeyGen(kp.secretKey);
	cc->EvalMultKeyGen(kp.secretKey);

	ciphertext1 = cc->Encrypt(kp.publicKey, intArray1, false);
	ciphertext2 = cc->Encrypt(kp.publicKey, intArray2, false);

	auto result = cc->EvalInnerProduct(ciphertext1[0], ciphertext2[0], batchSize);

	vector<shared_ptr<Ciphertext<Poly>>> ciphertextSum;

	ciphertextSum.push_back(result);

	PackedIntPlaintextEncoding intArrayNew;

	cc->Decrypt(kp.secretKey, ciphertextSum, &intArrayNew, false);

	std::cout << "Sum = " << intArrayNew[0] << std::endl;

	std::cout << "All components (other slots randomized) = " << intArrayNew << std::endl;

}


void ArbLTVInnerProductPackedArray() {

	usint m = 22;
	usint p = 89;
	BigInteger modulusP(p);
	/*BigInteger modulusQ("577325471560727734926295560417311036005875689");
	BigInteger squareRootOfRoot("576597741275581172514290864170674379520285921");*/
	//BigInteger modulusQ("955263939794561");
	//BigInteger squareRootOfRoot("941018665059848");
	BigInteger modulusQ("1267650600228229401496703214121");
	BigInteger squareRootOfRoot("498618454049802547396506932253");

	//BigInteger squareRootOfRoot = RootOfUnity(2*m,modulusQ);
	//std::cout << squareRootOfRoot << std::endl;
	//BigInteger bigmodulus("80899135611688102162227204937217");
	//BigInteger bigroot("77936753846653065954043047918387");
	BigInteger bigmodulus("1645504557321206042154969182557350504982735865633579863348616321");
	BigInteger bigroot("201473555181182026164891698186176997440470643522932663932844212");
	//std::cout << bigroot << std::endl;

	auto cycloPoly = GetCyclotomicPolynomial<BigVector, BigInteger>(m, modulusQ);
	ChineseRemainderTransformArb<BigInteger, BigVector>::GetInstance().SetCylotomicPolynomial(cycloPoly, modulusQ);

	PackedIntPlaintextEncoding::SetParams(modulusP, m);

	float stdDev = 4;

	usint batchSize = 8;

	shared_ptr<ILParams> params(new ILParams(m, modulusQ, squareRootOfRoot, bigmodulus, bigroot));

	shared_ptr<EncodingParams> encodingParams(new EncodingParams(modulusP, PackedIntPlaintextEncoding::GetAutomorphismGenerator(modulusP), batchSize));

	shared_ptr<CryptoContext<Poly>> cc = CryptoContextFactory<Poly>::genCryptoContextLTV(params, encodingParams, 16, stdDev);

	cc->Enable(ENCRYPTION);
	cc->Enable(SHE);

	// Initialize the public key containers.
	LPKeyPair<Poly> kp = cc->KeyGen();

	vector<shared_ptr<Ciphertext<Poly>>> ciphertext1;
	vector<shared_ptr<Ciphertext<Poly>>> ciphertext2;

	std::vector<usint> vectorOfInts1 = { 1,2,3,4,5,6,7,8,0,0 };
	PackedIntPlaintextEncoding intArray1(vectorOfInts1);

	std::cout << "Input array 1 \n\t" << intArray1 << std::endl;


	std::vector<usint> vectorOfInts2 = { 1,2,3,2,1,2,1,2,0,0 };
	PackedIntPlaintextEncoding intArray2(vectorOfInts2);

	std::cout << "Input array 2 \n\t" << intArray2 << std::endl;

	cc->EvalSumKeyGen(kp.secretKey,kp.publicKey);
	cc->EvalMultKeyGen(kp.secretKey);

	ciphertext1 = cc->Encrypt(kp.publicKey, intArray1, false);
	ciphertext2 = cc->Encrypt(kp.publicKey, intArray2, false);

	auto result = cc->EvalInnerProduct(ciphertext1[0], ciphertext2[0], batchSize);

	vector<shared_ptr<Ciphertext<Poly>>> ciphertextSum;

	ciphertextSum.push_back(result);

	PackedIntPlaintextEncoding intArrayNew;

	cc->Decrypt(kp.secretKey, ciphertextSum, &intArrayNew, false);

	std::cout << "Sum = " << intArrayNew[0] << std::endl;

	std::cout << "All components (other slots randomized) = " << intArrayNew << std::endl;

}

void ArbFVInnerProductPackedArray() {

	usint m = 22;
	usint p = 2333; // we choose s.t. 2m|p-1 to leverage CRTArb
	BigInteger modulusQ("1152921504606847009");
	BigInteger modulusP(p);
	BigInteger rootOfUnity("1147559132892757400");

	BigInteger bigmodulus("42535295865117307932921825928971026753");
	BigInteger bigroot("13201431150704581233041184864526870950");

	auto cycloPoly = GetCyclotomicPolynomial<BigVector, BigInteger>(m, modulusQ);
	//ChineseRemainderTransformArb<BigInteger, BigVector>::GetInstance().PreCompute(m, modulusQ);
	ChineseRemainderTransformArb<BigInteger, BigVector>::SetCylotomicPolynomial(cycloPoly, modulusQ);

	float stdDev = 4;

	shared_ptr<ILParams> params(new ILParams(m, modulusQ, rootOfUnity, bigmodulus, bigroot));

	BigInteger bigEvalMultModulus("42535295865117307932921825928971026753");
	BigInteger bigEvalMultRootOfUnity("22649103892665819561201725524201801241");
	BigInteger bigEvalMultModulusAlt("115792089237316195423570985008687907853269984665640564039457584007913129642241");
	BigInteger bigEvalMultRootOfUnityAlt("37861550304274465568523443986246841530644847113781666728121717722285667862085");

	auto cycloPolyBig = GetCyclotomicPolynomial<BigVector, BigInteger>(m, bigEvalMultModulus);
	//ChineseRemainderTransformArb<BigInteger, BigVector>::GetInstance().PreCompute(m, modulusQ);
	ChineseRemainderTransformArb<BigInteger, BigVector>::SetCylotomicPolynomial(cycloPolyBig, bigEvalMultModulus);

	PackedIntPlaintextEncoding::SetParams(modulusP, m);

	usint batchSize = 8;

	shared_ptr<EncodingParams> encodingParams(new EncodingParams(modulusP, PackedIntPlaintextEncoding::GetAutomorphismGenerator(modulusP), batchSize));

	BigInteger delta(modulusQ.DividedBy(modulusP));

	//genCryptoContextFV(shared_ptr<typename Element::Params> params,
	//	shared_ptr<typename EncodingParams> encodingParams,
	//	usint relinWindow, float stDev, const std::string& delta,
	//	MODE mode = RLWE, const std::string& bigmodulus = "0", const std::string& bigrootofunity = "0",
	//	int depth = 0, int assuranceMeasure = 0, float securityLevel = 0,
	//	const std::string& bigmodulusarb = "0", const std::string& bigrootofunityarb = "0")

	shared_ptr<CryptoContext<Poly>> cc = CryptoContextFactory<Poly>::genCryptoContextFV(params, encodingParams, 1, stdDev, delta.ToString(), OPTIMIZED,
		bigEvalMultModulus.ToString(), bigEvalMultRootOfUnity.ToString(), 1, 9, 1.006, bigEvalMultModulusAlt.ToString(), bigEvalMultRootOfUnityAlt.ToString());

	//BigInteger modulusQ("955263939794561");
	//BigInteger squareRootOfRoot("941018665059848");

	cc->Enable(ENCRYPTION);
	cc->Enable(SHE);

	// Initialize the public key containers.
	LPKeyPair<Poly> kp = cc->KeyGen();

	vector<shared_ptr<Ciphertext<Poly>>> ciphertext1;
	vector<shared_ptr<Ciphertext<Poly>>> ciphertext2;

	std::vector<usint> vectorOfInts1 = { 1,2,3,4,5,6,7,8,0,0 };
	PackedIntPlaintextEncoding intArray1(vectorOfInts1);

	std::cout << "Input array 1 \n\t" << intArray1 << std::endl;


	std::vector<usint> vectorOfInts2 = { 1,2,3,2,1,2,1,2,0,0 };
	PackedIntPlaintextEncoding intArray2(vectorOfInts2);

	std::cout << "Input array 2 \n\t" << intArray2 << std::endl;

	cc->EvalSumKeyGen(kp.secretKey);
	cc->EvalMultKeyGen(kp.secretKey);

	ciphertext1 = cc->Encrypt(kp.publicKey, intArray1, false);
	ciphertext2 = cc->Encrypt(kp.publicKey, intArray2, false);

	auto result = cc->EvalInnerProduct(ciphertext1[0], ciphertext2[0], batchSize);

	vector<shared_ptr<Ciphertext<Poly>>> ciphertextSum;

	ciphertextSum.push_back(result);

	PackedIntPlaintextEncoding intArrayNew;

	cc->Decrypt(kp.secretKey, ciphertextSum, &intArrayNew, false);

	std::cout << "Sum = " << intArrayNew[0] << std::endl;

	std::cout << "All components (other slots randomized) = " << intArrayNew << std::endl;

}


void ArbFVEvalMultPackedArray() {

	PackedIntPlaintextEncoding::Destroy();

	usint m = 22;
	usint p = 89; // we choose s.t. 2m|p-1 to leverage CRTArb
	BigInteger modulusQ("72385066601");
	BigInteger modulusP(p);
	BigInteger rootOfUnity("69414828251");
	BigInteger bigmodulus("77302754575416994210914689");
	BigInteger bigroot("76686504597021638023705542");

	auto cycloPoly = GetCyclotomicPolynomial<BigVector, BigInteger>(m, modulusQ);
	//ChineseRemainderTransformArb<BigInteger, BigVector>::GetInstance().PreCompute(m, modulusQ);
	ChineseRemainderTransformArb<BigInteger, BigVector>::SetCylotomicPolynomial(cycloPoly, modulusQ);

	float stdDev = 4;

	shared_ptr<ILParams> params(new ILParams(m, modulusQ, rootOfUnity, bigmodulus, bigroot));

	BigInteger bigEvalMultModulus("37778931862957161710549");
	BigInteger bigEvalMultRootOfUnity("7161758688665914206613");
	BigInteger bigEvalMultModulusAlt("1461501637330902918203684832716283019655932547329");
	BigInteger bigEvalMultRootOfUnityAlt("570268124029534407621996591794583635795426001824");

	auto cycloPolyBig = GetCyclotomicPolynomial<BigVector, BigInteger>(m, bigEvalMultModulus);
	//ChineseRemainderTransformArb<BigInteger, BigVector>::GetInstance().PreCompute(m, modulusQ);
	ChineseRemainderTransformArb<BigInteger, BigVector>::SetCylotomicPolynomial(cycloPolyBig, bigEvalMultModulus);

	PackedIntPlaintextEncoding::SetParams(modulusP, m);

	usint batchSize = 8;

	shared_ptr<EncodingParams> encodingParams(new EncodingParams(modulusP, PackedIntPlaintextEncoding::GetAutomorphismGenerator(modulusP), batchSize));

	BigInteger delta(modulusQ.DividedBy(modulusP));

	//genCryptoContextFV(shared_ptr<typename Element::Params> params,
	//	shared_ptr<typename EncodingParams> encodingParams,
	//	usint relinWindow, float stDev, const std::string& delta,
	//	MODE mode = RLWE, const std::string& bigmodulus = "0", const std::string& bigrootofunity = "0",
	//	int depth = 0, int assuranceMeasure = 0, float securityLevel = 0,
	//	const std::string& bigmodulusarb = "0", const std::string& bigrootofunityarb = "0")

	shared_ptr<CryptoContext<Poly>> cc = CryptoContextFactory<Poly>::genCryptoContextFV(params, encodingParams, 1, stdDev, delta.ToString(), OPTIMIZED,
		bigEvalMultModulus.ToString(), bigEvalMultRootOfUnity.ToString(), 1, 9, 1.006, bigEvalMultModulusAlt.ToString(), bigEvalMultRootOfUnityAlt.ToString());

	cc->Enable(ENCRYPTION);
	cc->Enable(SHE);

	// Initialize the public key containers.
	LPKeyPair<Poly> kp = cc->KeyGen();

	vector<shared_ptr<Ciphertext<Poly>>> ciphertext1;
	vector<shared_ptr<Ciphertext<Poly>>> ciphertext2;
	vector<shared_ptr<Ciphertext<Poly>>> ciphertextResult;

	std::vector<usint> vectorOfInts1 = { 1,2,3,4,5,6,7,8,9,10 };
	PackedIntPlaintextEncoding intArray1(vectorOfInts1);

	std::vector<usint> vectorOfInts2 = { 10,9,8,7,6,5,4,3,2,1 };
	PackedIntPlaintextEncoding intArray2(vectorOfInts2);

	std::vector<usint> vectorOfIntsMult;
	std::transform(vectorOfInts1.begin(), vectorOfInts1.end(), vectorOfInts2.begin(), std::back_inserter(vectorOfIntsMult), std::multiplies<usint>());

	ciphertext1 = cc->Encrypt(kp.publicKey, intArray1, false);
	ciphertext2 = cc->Encrypt(kp.publicKey, intArray2, false);

	cc->EvalMultKeyGen(kp.secretKey);

	auto ciphertextMult = cc->EvalMult(ciphertext1.at(0), ciphertext2.at(0));
	ciphertextResult.insert(ciphertextResult.begin(), ciphertextMult);
	PackedIntPlaintextEncoding intArrayNew;

	cc->Decrypt(kp.secretKey, ciphertextResult, &intArrayNew, false);

	std::cout << "Actual = " << intArrayNew << std::endl;

	std::cout << "Expected = " << PackedIntPlaintextEncoding(vectorOfIntsMult) << std::endl;

}