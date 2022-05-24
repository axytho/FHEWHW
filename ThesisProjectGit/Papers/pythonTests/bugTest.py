bug = [3*[0] for _ in range(2)]

for j in range(2):
    for k in range(3):
        bug[j][k] = 4*k+j
        print(bug)