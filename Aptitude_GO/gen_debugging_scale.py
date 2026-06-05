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

print("Generating scalable algorithmic variations for Debugging targets (Target: 300+)...")

# 1. Tracing Recursive Math Errors
for _ in range(80):
    start = random.randint(3, 7)
    wrong_return = random.randint(0, 2)
    # factorial with wrong base return
    code = f"int fact(int n) {{\n  if (n == 0) return {wrong_return};\n  return n * fact(n-1);\n}}"
    
    if wrong_return == 0:
        ans = "0"
    elif wrong_return == 1:
        ans = str(math_fact(start)) if 'math_fact' in globals() else str(eval("*".join(str(i) for i in range(1, start+1))))
    else:
        ans = str(eval("*".join(str(i) for i in range(1, start+1))) * wrong_return)
        
    q_txt = f"Trace the output of <code>fact({start})</code> given this buggy C function:<br><code>{code}</code>"
    
    correct = str(ans)
    ideal = str(eval("*".join(str(i) for i in range(1, start+1))))
    opts = [correct, ideal, "Stack Overflow", str(random.randint(10, 100))]
    opts = list(set(opts))
    if correct in opts: opts.remove(correct)
    
    while len(opts) < 3:
        cand = str(random.randint(0, 100))
        if cand != correct and cand not in opts:
            opts.append(cand)
            
    shuffle_and_add(q_txt, correct, opts[0], opts[1], opts[2])

# 2. Logic Errors in Array Searches
for _ in range(80):
    arr_len = random.randint(4, 8)
    arr = sorted([random.randint(1, 50) for _ in range(arr_len)])
    target = random.choice(arr)
    # The bug: loop goes to < arr.length-1, missing last element occasionally
    code = f"int find(int[] arr, int target) {{\n  for(int i=0; i < arr.length - 1; i++) {{\n    if(arr[i] == target) return i;\n  }}\n  return -1;\n}}"
    
    idx = arr.index(target)
    if idx == arr_len - 1:
        ans = "-1 (Target missed due to loop condition)"
    else:
        ans = str(idx)
        
    q_txt = f"A developer wrote a linear search for Java. Array: <code>{arr}</code>, Target: <code>{target}</code>.<br><code>{code}</code><br>What does <code>find(arr, target)</code> return?"
    
    opts = [ans, str(arr_len - 1), str(idx), "-1", "Compilation Error"]
    opts = list(set(opts))
    opts.remove(ans)
    
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 3. Fixing the off-by-one in String reversals (Python)
for _ in range(80):
    word = random.choice(["hello", "world", "python", "debug", "logic"])
    code = f"s = \"{word}\"\nres = \"\"\nfor i in range(len(s), 0, -1):\n  res += s[i]"
    ans = "IndexError: string index out of range (s[len(s)] is invalid)"
    d1 = f"Prints '{word[::-1]}'"
    d2 = f"Prints '{word}'"
    d3 = "SyntaxError"
    
    q_txt = f"Identify the error in this Python string reversal attempt:<br><code>{code}</code>"
    shuffle_and_add(q_txt, ans, d1, d2, d3)

# 4. Math Operator Precedence bugs
for _ in range(80):
    a = random.randint(2, 5)
    b = random.randint(2, 5)
    c = random.randint(2, 5)
    # Intent: (a+b)*c
    # Code: a + b * c
    code = f"int result = {a} + {b} * {c};\n// Intended logic was ({a} + {b}) * {c}"
    ans = str(a + b * c)
    ideal = str((a + b) * c)
    
    q_txt = f"Trace the actual evaluated <code>result</code> of this code snippet:<br><code>{code}</code>"
    
    opts = [ans, ideal, str(a * b + c), str(random.randint(10, 50))]
    opts = list(set(opts))
    opts.remove(ans)
    while len(opts) < 3:
        cand = str(random.randint(5, 50))
        if cand != ans and cand not in opts: opts.append(cand)
        
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

print(f"Adding {len(questions)} mass variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done mass generating debugging variations.")
