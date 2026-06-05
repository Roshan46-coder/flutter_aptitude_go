import os
import csv
import random

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\debugging_and_code_logic"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "debugging_and_code_logic.csv")

if not os.path.exists(IMAGES_DIR):
    os.makedirs(IMAGES_DIR)

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

print("Generating ~250 distinct Debugging and Code Logic varieties...")

# 1. Identify Errors: Off-by-one in loops (C/C++/Java)
# Base logic: Trying to print 1 to N, but loop bounds are wrong.
for _ in range(30):
    lang = random.choice(["C", "C++", "Java"])
    n = random.randint(5, 10)
    loop_ops = [("<", f"Prints 1 to {n-1} instead of 1 to {n}"),
                ("<=", f"Correctly prints 1 to {n}"),
                (">", "Loop does not execute"),
                (">=", "Loop does not execute")]
    op, effect = random.choice(loop_ops)
    
    q_txt = f"Review the following {lang} snippet intended to print numbers from 1 to {n}:<br><code>for(int i = 1; i {op} {n}; i++) {{<br>&nbsp;&nbsp;print(i);<br>}}</code><br>What is the logical error, if any?"
    
    ans = effect
    opts = [eff for op_, eff in loop_ops if eff != effect]
    while len(opts) < 3:
        opts.append(f"Infinite loop due to i++")
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 2. Fix logical mistakes: Assignment vs Equality (C/C++/Java/Python)
for _ in range(30):
    val = random.randint(1, 100)
    # The classic if (x = 5) instead of (x == 5)
    q_txt = f"A developer wrote the following C code:<br><code>int x = 0;<br>if(x = {val}) {{<br>&nbsp;&nbsp;printf(\"True\");<br>}} else {{<br>&nbsp;&nbsp;printf(\"False\");<br>}}</code><br>What gets printed and why?"
    
    ans = f"Prints 'True' because x = {val} is an assignment that evaluates to {val} (truthy)."
    d1 = f"Prints 'False' because initially x is 0, which is not equal to {val}."
    d2 = "Compilation Error: Cannot use assignment in an if condition."
    d3 = "Runtime Error: Assignment in conditional expression."
    shuffle_and_add(q_txt, ans, d1, d2, d3)

# 3. Trace code execution: Missing return statement / base case in recursion (Python)
for _ in range(30):
    missing = random.choice(["base_case", "return", "increment"])
    if missing == "base_case":
        code = f"def factorial(n):\n  return n * factorial(n-1)\n\nprint(factorial(3))"
        ans = "RecursionError: maximum recursion depth exceeded (missing base case)"
    elif missing == "return":
        code = f"def add(a, b):\n  result = a + b\n\nprint(add(2, 3))"
        ans = "Prints 'None' because the function lacks a return statement"
    else:
        code = f"i = 0\nwhile i < 5:\n  print(i)\n# missing i += 1"
        ans = "Infinite loop printing 0 constantly"
        
    q_txt = f"Identify the execution issue in this Python code:<br><code>{code}</code>"
    opts = ["RecursionError: maximum recursion depth exceeded (missing base case)", 
            "Prints 'None' because the function lacks a return statement", 
            "Infinite loop printing 0 constantly", 
            "SyntaxError: Invalid syntax"]
    opts.remove(ans)
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 4. Null Pointer / Index Out of Bounds (Java)
for _ in range(35):
    err_type = random.choice(["NullPointer", "OutOfBounds"])
    size = random.randint(3, 7)
    if err_type == "NullPointer":
        code = f"String str = null;\nSystem.out.println(str.length());"
        ans = "NullPointerException"
    else:
        code = f"int[] arr = new int[{size}];\nSystem.out.println(arr[{size}]);"
        ans = "ArrayIndexOutOfBoundsException"
        
    q_txt = f"What exception does this Java code snippet throw?<br><code>{code}</code>"
    opts = ["NullPointerException", "ArrayIndexOutOfBoundsException", "StringIndexOutOfBoundsException", "Compilation Error (variable uninitialized)"]
    if ans in opts: opts.remove(ans)
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 5. Variable Scope shadowing (C++)
for _ in range(35):
    outer = random.randint(10, 20)
    inner = random.randint(30, 40)
    code = f"int x = {outer};\nif (true) {{\n  int x = {inner};\n}}\ncout << x;"
    ans = str(outer)
    d1 = str(inner)
    d2 = "Compilation Error: redefinition of x"
    d3 = "Garbage Value"
    
    q_txt = f"Trace the output of this C++ snippet:<br><code>{code}</code>"
    shuffle_and_add(q_txt, ans, d1, d2, d3)

# 6. Infinite loops due to floating point precision (Python/C)
for _ in range(30):
    code = f"float x = 0.0;\nwhile(x != 1.0) {{\n  x += 0.1;\n}}"
    ans = "It may result in an infinite loop because 0.1 cannot be represented exactly in binary floating-point."
    d1 = "It terminates normally after 10 iterations."
    d2 = "It terminates normally after 11 iterations."
    d3 = "Compilation Error: cannot use != with floats."
    
    q_txt = f"What is the most likely issue with the following loop construct?<br><code>{code}</code>"
    shuffle_and_add(q_txt, ans, d1, d2, d3)

# 7. Uninitialized Variables (C/C++)
for _ in range(30):
    code = f"int main() {{\n  int sum;\n  for(int i=1; i<=5; i++) {{\n    sum += i;\n  }}\n  printf(\"%d\", sum);\n  return 0;\n}}"
    ans = "Outputs an unpredictable (garbage) value because 'sum' is uninitialized."
    d1 = "Outputs 15."
    d2 = "Outputs 0."
    d3 = "Compilation Error: sum is uninitialized." # In C it's a warning, not strictly compilation error by default
    
    q_txt = f"Analyze the following C code:<br><code>{code}</code><br>What is the result?"
    shuffle_and_add(q_txt, ans, d1, d2, d3)

# 8. Modifying collection while iterating (Java)
for _ in range(30):
    code = f"List<Integer> list = new ArrayList<>(Arrays.asList(1, 2, 3));\nfor(Integer num : list) {{\n  if(num == 2) list.remove(num);\n}}"
    ans = "Throws ConcurrentModificationException"
    d1 = "Successfully removes 2, list becomes [1, 3]"
    d2 = "Throws IndexOutOfBoundsException"
    d3 = "Compilation Error"
    
    q_txt = f"What happens when this Java code executes?<br><code>{code}</code>"
    shuffle_and_add(q_txt, ans, d1, d2, d3)

print(f"Adding {len(questions)} distinct debugging paradigms to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    # write headers
    f.write("Question;Option A;Option B;Option C;Option D;Answer,,,,,,,,\n")
    for q in questions:
        f.write(q + "\n")

print("Done mass generating debugging distinct questions.")
