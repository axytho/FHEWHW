originalSecret = 88888888
multSecret = (originalSecret * int("200000000", 16)) % 134215681
stringThing = ""
for i in range(4 * 32):
    stringThing += format(multSecret, '027b')
print(stringThing)

A_vector = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/AVECTOR.txt",
    'r')
Accumulator = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/STARTACCUMULATOR.txt",
    'r')
DUALPORTBRAM = open(
    "D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/DUALPORTBRAM.txt",
    'w')
AccumulatorList = Accumulator.readlines()
avectorList = A_vector.readlines()
for i in range(2048):
    DUALPORTBRAM.write(AccumulatorList[i])

for i in range(1024):
    DUALPORTBRAM.write(avectorList[i])

for i in range(1024*5):
    DUALPORTBRAM.write("0" + "\n")
