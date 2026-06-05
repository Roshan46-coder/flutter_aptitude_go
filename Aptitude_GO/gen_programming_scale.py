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

print("Generating scalable algorithmic variations for Programming Aptitude (Target: 350+)...")

# 1. Pointers & References (C/C++)
# Example predicting output of pointer arithmetic
for _ in range(70):
    val = random.randint(10, 99)
    # ptr arithmetic offset
    offset = random.choice([1, 2, 3])
    arr = [val, val + random.randint(1,10), val + random.randint(10,20), val + random.randint(20,30)]
    
    arr_str = ", ".join(map(str, arr))
    q_txt = f"What is the output of the C++ code?<br><code>int arr[] = {{{arr_str}}};<br>int *ptr = arr;<br>ptr += {offset};<br>cout << *ptr;</code>"
    
    correct = str(arr[offset])
    dummies = list(set([str(arr[0]), str(arr[1] if offset != 1 else arr[2]), str(arr[3] if offset != 3 else arr[0])]))
    if correct in dummies:
        dummies.remove(correct)
    while len(dummies) < 3:
        cand = f"Compile Error {random.randint(1,100)}"
        if cand not in dummies:
            dummies.append(cand)
    
    shuffle_and_add(q_txt, correct, dummies[0], dummies[1], dummies[2])

# 2. Bitwise Operators (Java/C/Python)
for _ in range(60):
    op = random.choice(["&", "|", "^", "<<", ">>"])
    n1 = random.choice([2, 4, 8, 16])
    n2 = random.choice([1, 2, 4, 8])
    
    # Python/C bitwise output
    if op == "&": ans = n1 & n2
    elif op == "|": ans = n1 | n2
    elif op == "^": ans = n1 ^ n2
    elif op == "<<": ans = n1 << n2
    elif op == ">>": ans = n1 >> n2
    
    q_txt = f"What is the output of the bitwise operation?<br><code>int a = {n1};<br>int b = {n2};<br>print(a {op} b);</code>"
    
    opts = list(set([str(n1+n2), str(n1*n2), str(random.randint(0, 32))]))
    if str(ans) in opts:
        opts.remove(str(ans))
    while len(opts) < 3:
        num = str(random.randint(0, 100))
        if num != str(ans) and num not in opts:
            opts.append(num)
    
    dummies = opts[:3]
    shuffle_and_add(q_txt, str(ans), dummies[0], dummies[1], dummies[2])

# 3. Object-Oriented Concepts (Java/Python Basics)
oop_questions = [
    ("Which of the following describes {} in OOP?", 
     [("Encapsulation", "Wrapping data and functions into a single unit", "Hiding implementation details", "Creating multiple forms of a function"),
      ("Inheritance", "Acquiring properties of an existing class", "Hiding implementation details", "Function overloading"),
      ("Polymorphism", "Having many forms of a method", "Restricting access to variables", "Memory allocation"),
      ("Abstraction", "Hiding the implementation complexity", "Wrapping data and functions", "Combining multiple classes")])
]

for _ in range(50):
    concept = random.choice(oop_questions[0][1])
    q_txt = f"Which of the following describes {concept[0]} in Object-Oriented Programming? (Variation {_})"
    correct = concept[1]
    d1 = concept[2]
    d2 = concept[3]
    d3 = "None of the above"
    shuffle_and_add(q_txt, correct, d1, d2, d3)

# 4. Exception Handling (Java/Python)
for _ in range(60):
    dividend = random.choice([10, 20, 50, 100])
    try_block = f"try {{\n  int a = {dividend} / 0;\n  print(\"A\");\n}} catch (Exception e) {{\n  print(\"B\");\n}} finally {{\n  print(\"C\");\n}}"
    q_txt = f"What is the output of this exception handling block?<br><code>{try_block}</code>"
    
    # Division by zero hits catch, then finally. So BC.
    shuffle_and_add(q_txt, "B C", "A B C", "A C", "B")

# 5. String Methods / Array Indexing (Python)
for _ in range(60):
    # e.g., string search
    words = ["programming", "developer", "algorithm", "database", "aptitude"]
    word = random.choice(words)
    target = random.choice([word[1], word[3], word[5], "z"])
    
    method = random.choice(["find", "index"])
    # in python find returns -1 if not found, index throws ValueError
    if target == "z":
        if method == "find": ans = "-1"
        else: ans = "ValueError"
    else:
        ans = str(word.find(target))
        
    q_txt = f"Predict the output of the Python code:<br><code>s = \"{word}\"<br>print(s.{method}(\"{target}\"))</code>"
    
    if ans == "-1": dummies = ["0", "ValueError", str(len(word))]
    elif ans == "ValueError": dummies = ["-1", "0", str(len(word))]
    else: dummies = ["-1", str(int(ans)+1), str(int(ans)-1)]
    
    shuffle_and_add(q_txt, ans, dummies[0], dummies[1], dummies[2])
    
# 6. Basic Math/Logic in Java Outputs
for _ in range(80):
    a = random.randint(3, 9)
    b = random.randint(2, 5)
    c = random.randint(1, 4)
    q_txt = f"What is the output in Java?<br><code>int res = {a} + {b} * {c};<br>System.out.println(res);</code>"
    ans = str(a + b * c)
    d1 = str((a + b) * c)
    d2 = str(a * b + c)
    d3 = str(random.randint(10, 50))
    shuffle_and_add(q_txt, ans, d1, d2, d3)

print(f"Adding {len(questions)} mass variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done mass generating programming variations.")
