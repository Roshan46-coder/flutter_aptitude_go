import csv
import os
import random

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\debugging_and_code_logic"
CSV_PATH = os.path.join(BASE_DIR, "debugging_and_code_logic.csv")

questions = []

def add_q(text, a, b, c, d, ans):
    text = text.replace(";", ",")
    questions.append(f"{text};{a};{b};{c};{d};{ans},,,,,,,,")

def shuffle_and_add(text, correct, dummy1, dummy2, dummy3):
    opts = [correct, dummy1, dummy2, dummy3]
    random.shuffle(opts)
    ans_idx = opts.index(correct)
    ans_char = chr(65 + ans_idx)
    add_q(text, opts[0], opts[1], opts[2], opts[3], ans_char)

print("Generating third wave of scalable Debugging & Code Logic variations...")

# 1. Pointer Dereference Tracking (C)
for _ in range(80):
    val = random.randint(10, 50)
    add = random.randint(2, 9)
    code = f"int a = {val};\nint *p = &a;\n*p = *p + {add};\nprintf(\"%d\", a);"
    ans = str(val + add)
    
    q_txt = f"Trace the output of this C pointer operation:<br><code>{code}</code>"
    opts = [ans, str(val), f"Memory Address of 'a'", str(random.randint(5, 100))]
    if ans in opts: opts.remove(ans)
    while len(opts) < 3: opts.append(str(random.randint(10, 100)))
    
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 2. 2D Array Tracing (Java)
for _ in range(80):
    rows = random.randint(2, 4)
    cols = random.randint(2, 4)
    target_row = random.randint(0, rows-1)
    target_col = random.randint(0, cols-1)
    
    # Intentionally initialize matrix randomly
    matrix = [[random.randint(1, 10) for _ in range(cols)] for _ in range(rows)]
    matrix_str = "{" + ", ".join(["{" + ", ".join(map(str, row)) + "}" for row in matrix]) + "}"
    
    ans = str(matrix[target_row][target_col])
    
    code = f"int[][] mat = {matrix_str};\nSystem.out.println(mat[{target_row}][{target_col}]);"
    q_txt = f"What is printed by this Java code?<br><code>{code}</code>"
    
    opts = list(set([ans, str(matrix[0][0]), str(matrix[-1][-1]), "IndexOutOfBoundsException"]))
    if ans in opts: opts.remove(ans)
    while len(opts) < 3:
        cand = str(random.randint(1, 15))
        if cand != ans and cand not in opts: opts.append(cand)
        
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 3. Object Reference Mutation Trace (Python)
for _ in range(80):
    init_val = random.randint(5, 15)
    append_val = random.randint(20, 30)
    
    code = f"def update_list(lst):\n  lst.append({append_val})\n\nmy_list = [{init_val}]\nupdate_list(my_list)\nprint(my_list)"
    ans = f"[{init_val}, {append_val}]"
    d1 = f"[{init_val}]"
    d2 = f"[{append_val}]"
    d3 = "SyntaxError"
    
    q_txt = f"Identify the output of this Python script:<br><code>{code}</code>"
    shuffle_and_add(q_txt, ans, d1, d2, d3)

# 4. Off-by-one String Length checks (C/C++)
for _ in range(80):
    word = random.choice(["Debugging", "Tracing", "Platform", "Aptitude", "Django"])
    code = f"char str[] = \"{word}\";\nfor(int i = 0; i <= strlen(str); i++) {{\n  if(str[i] == '\\0') printf(\"End\");\n}}"
    ans = "Prints 'End' normally because the loop accesses the null terminator at index strlen(str)"
    d1 = "Segmentation Fault (Out of Bounds)"
    d2 = "Infinite Loop"
    d3 = "Prints Nothing"
    
    q_txt = f"Evaluate the behavior of this loop over a C string:<br><code>{code}</code>"
    shuffle_and_add(q_txt, ans, d1, d2, d3)

print(f"Adding {len(questions)} wave 3 debugging variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done mass generating wave 3 debugging variations.")
