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

print("Generating algorithmic variations for Programming Aptitude...")

# 1. Loop Variations (C/C++/Java)
for _ in range(40):
    start = random.randint(0, 2)
    end = random.randint(3, 6)
    step = random.randint(1, 2)
    # Output of simple loop
    output = []
    for i in range(start, end, step):
        output.append(str(i))
    output_str = " ".join(output)
    
    q_txt = f"What is the output of the following C code?<br><code>#include &lt;stdio.h&gt;<br>int main() {{<br>  for(int i = {start}; i &lt; {end}; i += {step}) {{<br>    printf(\"%d \", i);<br>  }}<br>  return 0;<br>}}</code>"
    
    # Generate dummies
    d1 = " ".join([str(x) for x in range(start+1, end+1, step)])
    d2 = " ".join([str(x) for x in range(start, end+1, step)])
    d3 = " ".join([str(x) for x in range(start, end-1, step)])
    
    # Fallbacks if distinct issues arise
    if d1 == output_str: d1 += " " + str(end+1)
    if d2 == output_str: d2 += " " + str(end+step)
    if d3 == output_str: d3 = output_str[:-1] if len(output_str)>1 else "0"
    
    # Ensure they are uniquely different items in the UI options
    dummies = list(set([d1, d2, d3]))
    while len(dummies) < 3:
        dummies.append(f"Compile Error {random.randint(1,10)}")
        
    shuffle_and_add(q_txt, output_str, dummies[0], dummies[1], dummies[2])

# 2. Python Output Variations (String slicing)
for _ in range(30):
    word = random.choice(["Python", "Coding", "String", "Aptitude", "Django"])
    step = random.choice([-1, 1, 2])
    start = random.choice([0, 1])
    end = random.choice([None, 4, 5])
    
    if end is None:
        slice_str = f"[{start}::{step}]"
        ans = word[start::step]
    else:
        slice_str = f"[{start}:{end}:{step}]"
        ans = word[start:end:step]
        
    q_txt = f"Predict the Python output:<br><code>a = \"{word}\"<br>print(a{slice_str})</code>"
    
    d1 = word[::-1]
    d2 = word[1:]
    d3 = "Error"
    dummies = list(set([d1, d2, d3]))
    while len(dummies) < 3 or ans in dummies:
        dummies.append(f"Syntax Error {random.randint(1,10)}")
        
    shuffle_and_add(q_txt, ans, dummies[0], dummies[1], dummies[2])

# 3. Recursive Logic Variations
for _ in range(30):
    base_val = random.randint(0, 1)
    return_val = random.randint(1, 2)
    mult = random.randint(2, 3)
    query_val = random.randint(3, 4)
    
    # function is:
    # f(n): if n <= base_val return return_val; return mult * f(n-1)
    
    def sim_f(n):
        if n <= base_val: return return_val
        return mult * sim_f(n - 1)
        
    ans_val = sim_f(query_val)
    
    q_txt = f"Consider the recursive function:<br><code>int f(int n) {{<br>  if (n <= {base_val}) return {return_val};<br>  return {mult} * f(n-1);<br>}}</code><br>What is f({query_val})?"
    
    opts = [str(ans_val), str(ans_val - mult), str(ans_val + mult), str(ans_val * mult)]
    random.shuffle(opts)
    ans_char = chr(65 + opts.index(str(ans_val)))
    add_q(q_txt, opts[0], opts[1], opts[2], opts[3], ans_char)

# 4. Math Logic Variations (Java String Concatenation)
for _ in range(30):
    n1 = random.randint(5, 20)
    n2 = random.randint(5, 20)
    word = random.choice(["Java", "Output", "Sum", "Value"])
    order = random.choice([1, 2]) # 1: num+num+str, 2: str+num+num
    
    if order == 1:
        ans = str(n1 + n2) + word
        q_txt = f"What is the output in Java?<br><code>System.out.println({n1} + {n2} + \"{word}\");</code>"
        d1 = str(n1) + str(n2) + word
        d2 = word + str(n1 + n2)
        d3 = word + str(n1) + str(n2)
    else:
        ans = word + str(n1) + str(n2)
        q_txt = f"What is the output in Java?<br><code>System.out.println(\"{word}\" + {n1} + {n2});</code>"
        d1 = word + str(n1 + n2)
        d2 = str(n1 + n2) + word
        d3 = str(n1) + str(n2) + word
        
    dummies = list(set([d1, d2, d3]))
    while len(dummies) < 3 or ans in dummies:
        dummies.append(f"Error {len(dummies)}")
        
    shuffle_and_add(q_txt, ans, dummies[0], dummies[1], dummies[2])

print(f"Adding {len(questions)} algorithmic variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done generating programming variations.")
