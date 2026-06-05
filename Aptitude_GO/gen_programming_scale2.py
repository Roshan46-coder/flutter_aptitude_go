import csv
import os
import random

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\programming_aptitude"
CSV_PATH = os.path.join(BASE_DIR, "programming_aptitude.csv")

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

print("Generating second wave of scalable basic logic programming questions...")

# 1. Output prediction for basic while loops (Python)
for _ in range(75):
    start = random.randint(1, 100)
    cond = random.randint(start + 5, start + 25)
    step = random.randint(2, 5)
    
    # Calculate output
    out_vals = []
    i = start
    while i < cond:
        out_vals.append(str(i))
        i += step
    ans = " ".join(out_vals)
    
    q_txt = f"What gets printed?<br><code>i = {start}<br>while i &lt; {cond}:<br>&nbsp;&nbsp;print(i, end=' ')<br>&nbsp;&nbsp;i += {step}</code>"
    
    d1 = " ".join([str(x) for x in range(start, cond+step, step)]) # one extra step
    d2 = " ".join([str(x) for x in range(start+step, cond, step)]) # skip first
    d3 = " ".join([str(x) for x in range(start, cond-step, step)]) # stop early
    
    dummies = list(set([d1, d2, d3]))
    if ans in dummies: dummies.remove(ans)
    while len(dummies) < 3:
        rand_end = " ".join([str(x) for x in range(start, cond + random.randint(10,30), step)])
        if rand_end != ans and rand_end not in dummies:
            dummies.append(rand_end)
            
    shuffle_and_add(q_txt, ans, dummies[0], dummies[1], dummies[2])

# 2. Logic condition tracing (C/Java)
for _ in range(75):
    # if (x && y || z) etc.
    x = random.choice([True, False])
    y = random.choice([True, False])
    z = random.choice([True, False])
    
    q_txt = f"Given <code>boolean x = {str(x).lower()}; boolean y = {str(y).lower()}; boolean z = {str(z).lower()};</code><br>What is the value of <code>(x && y) || z</code>?"
    
    ans = (x and y) or z
    ans_str = str(ans).lower()
    
    shuffle_and_add(q_txt, ans_str, str(not ans).lower(), "Compilation Error", "Runtime Error")

# 3. Array sorting tracing (Pseudocode)
for _ in range(75):
    arr = [random.randint(1, 99) for _ in range(5)]
    target_idx = random.randint(0, 4)
    # the question asks what is at index after ascending sort
    sorted_arr = sorted(arr)
    ans = str(sorted_arr[target_idx])
    
    q_txt = f"An array initialized as <code>arr = {arr}</code> is sorted in ascending order. What will be the value at index {target_idx} (0-indexed)?"
    
    opts = list(set([str(arr[target_idx]), str(sorted_arr[0]), str(sorted_arr[-1])]))
    if ans in opts: opts.remove(ans)
    while len(opts) < 3:
        val = str(random.randint(1, 99))
        if val != ans and val not in opts:
            opts.append(val)
            
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 4. Modulo Arithmetic Programming
for _ in range(75):
    n1 = random.randint(100, 999)
    n2 = random.choice([2, 5, 10, 3, 4])
    ans = str(n1 % n2)
    
    q_txt = f"What is the output of <code>{n1} % {n2}</code>?"
    
    opts = list(set([str(n1 / n2)[:4], str(n1 // n2), str(random.randint(0, n2))]))
    if ans in opts: opts.remove(ans)
    while len(opts) < 3:
        val = str(random.randint(0, 20))
        if val != ans and val not in opts:
            opts.append(val)
            
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

print(f"Adding {len(questions)} wave 2 variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done mass generating wave 2 variations.")
