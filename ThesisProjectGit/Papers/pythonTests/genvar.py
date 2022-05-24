stringthing = "5'd{0}: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*{0})+:`DATA_SIZE_ARB];\n"
result = ""
for i in range(32):
    result += stringthing.format(i)
print(result)