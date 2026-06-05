import random
import os

csv_path = r"d:\aptitude preparation plaform\question_bank\clean_general_aptitude_dataset\clean_general_aptitude_dataset.csv"

questions = []

# Template 1: Basic probability (Colored balls)
def gen_prob_balls():
    c1 = random.choice(['black', 'red', 'blue'])
    c2 = random.choice(['white', 'green', 'yellow'])
    n1 = random.randint(3, 15)
    n2 = random.randint(3, 15)
    total = n1 + n2
    
    q_text = f"A bag contains {n1} {c1} and {n2} {c2} balls. One ball is drawn at random. What is the probability that the ball drawn is {c2}?"
    ans_str = f"{n2}/{total}"
    
    # Fake options
    opts = [f"{n2}/{total}", f"{n1}/{total}", f"{(n2-1) if n2>1 else 1}/{total}"]
    while len(opts) < 4:
        val = f"{random.randint(1, total-1)}/{total}"
        if val not in opts: opts.append(val)
    
    opts = list(set(opts))
    while len(opts) < 4:
        opts.append(f"{random.randint(10, 20)}/{total+10}")
        opts = list(set(opts))

    random.shuffle(opts)
    letters = ['A', 'B', 'C', 'D']
    ans_letter = letters[opts.index(ans_str)]
    
    return f"{q_text};{opts[0]};{opts[1]};{opts[2]};{opts[3]};{ans_letter},,,,,,,,"

# Template 2: Simple Interest
def gen_simple_interest():
    p = random.randint(100, 1000) * 100
    r = random.randint(5, 18)
    t = random.randint(2, 8)
    si = (p * r * t) // 100
    
    q_text = f"Find the simple interest on Rs. {p} at {r}% per annum for {t} years."
    ans_str = f"{si}"
    
    opts = [ans_str, f"{si + random.randint(5, 50)*10}", f"{max(0, si - random.randint(5, 50)*10)}"]
    while len(opts) < 4:
        val = f"{si + random.randint(1, 100)*10}"
        if val not in opts: opts.append(val)
    
    opts = list(set(opts))

    random.shuffle(opts)
    letters = ['A', 'B', 'C', 'D']
    ans_letter = letters[opts.index(ans_str)]
    
    return f"{q_text};{opts[0]};{opts[1]};{opts[2]};{opts[3]};{ans_letter},,,,,,,,"

# Template 3: Relative Speed (Two trains opposite direction)
def gen_opposite_trains():
    l1 = random.randint(10, 30) * 10
    l2 = random.randint(10, 30) * 10
    s1 = random.randint(40, 80) # km/h
    s2 = random.randint(40, 80) # km/h
    
    total_dist = l1 + l2
    rel_speed_mps = (s1 + s2) * (5/18)
    time_sec = round(total_dist / rel_speed_mps, 2)
    
    q_text = f"Two trains of lengths {l1} m and {l2} m are running in opposite directions on parallel tracks at {s1} km/hr and {s2} km/hr respectively. The time taken to cross each other is approximately:"
    ans_str = f"{time_sec} sec"
    
    opts = [ans_str, f"{round(time_sec + 2.5, 2)} sec", f"{max(0.1, round(time_sec - 1.25, 2))} sec", f"{round(time_sec * 1.5, 2)} sec"]
    opts = list(set(opts))
    while len(opts) < 4:
         opts.append(f"{round(time_sec + random.random()*10, 2)} sec")
         opts = list(set(opts))

    random.shuffle(opts)
    letters = ['A', 'B', 'C', 'D']
    ans_letter = letters[opts.index(ans_str)]
    
    return f"{q_text};{opts[0]};{opts[1]};{opts[2]};{opts[3]};{ans_letter},,,,,,,,"

# Template 4: Work and Time
def gen_work_time():
    a_days = random.randint(10, 30)
    b_days = random.randint(15, 40)
    
    together = round((a_days * b_days) / (a_days + b_days), 2)
    
    q_text = f"A can do a piece of work in {a_days} days and B can do the same work in {b_days} days. How many days will they take to complete the work together?"
    ans_str = f"{together} days"
    
    opts = [ans_str, f"{round(together + 2, 2)} days", f"{max(0.1, round(together - 1.5, 2))} days", f"{a_days + b_days} days"]
    opts = list(set(opts))
    while len(opts) < 4:
         opts.append(f"{round(together + random.random()*10, 2)} days")
         opts = list(set(opts))

    random.shuffle(opts)
    letters = ['A', 'B', 'C', 'D']
    ans_letter = letters[opts.index(ans_str)]
    
    return f"{q_text};{opts[0]};{opts[1]};{opts[2]};{opts[3]};{ans_letter},,,,,,,,"

# Template 5: Mixture and Alligation
def gen_mixture():
    c1 = random.randint(15, 30)
    c2 = random.randint(45, 80) # Ensured gap
    cm = random.randint(c1 + 5, c2 - 5)
    
    r1 = c2 - cm
    r2 = cm - c1
    
    q_text = f"In what ratio must a grocer mix two varieties of items costing Rs. {c1} and Rs. {c2} per kg respectively so as to get a mixture worth Rs. {cm} per kg?"
    ans_str = f"{r1}:{r2}"
    
    opts = [ans_str, f"{r2}:{r1}"]
    if r1+1 != r2: opts.append(f"{r1+1}:{r2}")
    if r1 != r2+1: opts.append(f"{r1}:{r2+1}")
    
    opts = list(set(opts))
    while len(opts) < 4:
         opts.append(f"{random.randint(1,10)}:{random.randint(1,10)}")
         opts = list(set(opts))

    random.shuffle(opts)
    letters = ['A', 'B', 'C', 'D']
    ans_letter = letters[opts.index(ans_str)]
    
    return f"{q_text};{opts[0]};{opts[1]};{opts[2]};{opts[3]};{ans_letter},,,,,,,,"


# Generate 50 of each type
for _ in range(50):
    questions.append(gen_prob_balls())
    questions.append(gen_simple_interest())
    questions.append(gen_opposite_trains())
    questions.append(gen_work_time())
    questions.append(gen_mixture())

# Append to file
try:
    with open(csv_path, "r", encoding="utf-8") as f:
        needs_newline = not f.read().endswith('\n')
except:
    needs_newline = False

with open(csv_path, "a", encoding="utf-8") as f:
    if needs_newline:
        f.write("\n")
    for q in questions:
        f.write(q + "\n")

print(f"Generated and appended {len(questions)} algorithmic questions.")
