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

print("Generating second wave of scalable Debugging & Code Logic variations...")

# 1. Tracing Nested Loop Accumulators
for _ in range(80):
    outer = random.randint(2, 5)
    inner = random.randint(2, 5)
    # The code:
    # int count = 0;
    # for(int i=0; i<outer; i++)
    #   for(int j=0; j<inner; j++) count++;
    code = f"int count = 0;\nfor(int i=0; i<{outer}; i++) {{\n  for(int j=0; j<{inner}; j++) {{\n    count++;\n  }}\n}}"
    ans = str(outer * inner)
    q_txt = f"Trace the final value of <code>count</code> after this nested loop executes:<br><code>{code}</code>"
    
    opts = [ans, str(outer + inner), str(outer * inner - 1), str(outer * inner + 1)]
    opts = list(set(opts))
    opts.remove(ans)
    while len(opts) < 3: opts.append(str(random.randint(4, 30)))
    
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 2. String Concatenation vs Addition Trace (Java)
for _ in range(80):
    n1 = random.randint(2, 9)
    n2 = random.randint(2, 9)
    # the classic system out "result: " + n1 + n2
    code = f"System.out.println(\"Result is: \" + {n1} + {n2});"
    ans = f"Result is: {n1}{n2}"
    
    q_txt = f"What is the exact output of this Java statement?<br><code>{code}</code>"
    d1 = f"Result is: {n1+n2}"
    d2 = f"{n1}{n2} is the Result"
    d3 = "Compilation Error"
    
    shuffle_and_add(q_txt, ans, d1, d2, d3)

# 3. Off-by-one substring index Python
for _ in range(80):
    idx = random.randint(2, 6)
    # s = "Debugging"; s[:idx] actually goes up to idx-1
    code = f"s = \"AptitudeTest\"\nprint(s[:{idx}])"
    text_val = "AptitudeTest"
    actual = text_val[:idx]
    wrong_1 = text_val[:idx+1]
    wrong_2 = text_val[1:idx]
    
    q_txt = f"Trace the python slice output:<br><code>{code}</code>"
    
    opts = [actual, wrong_1, wrong_2, "IndexError"]
    opts = list(set(opts))
    if actual in opts: opts.remove(actual)
    while len(opts) < 3: opts.append("SyntaxError")
    
    shuffle_and_add(q_txt, actual, opts[0], opts[1], opts[2])

print(f"Adding {len(questions)} wave 2 debugging variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done mass generating wave 2 debugging variations.")
