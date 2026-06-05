import random
import math
import os

csv_path = r"d:\aptitude preparation plaform\question_bank\clean_general_aptitude_dataset\clean_general_aptitude_dataset.csv"

def gcd(a, b):
    while b:
        a, b = b, a % b
    return a

def gcd_three(a, b, c):
    return gcd(gcd(a, b), c)

questions = []

# 1. Exam Rooms
def gen_exam_rooms():
    # A - X = B + X => A - B = 2X
    # A + Y = 2(B - Y) => A - 2B = -3Y
    # B = 2X + 3Y
    # A = 4X + 3Y
    x = random.randint(5, 50)
    y = random.randint(5, 50)
    A = 4*x + 3*y
    
    q_text = f"There are two examination rooms A and B. If {x} students are sent from A to B, then the number of students in each room is the same. If {y} candidates are sent from B to A, then the number of students in A is double the number of students in B. The number of students in room A is:"
    ans_str = str(A)
    
    opts = [ans_str, str(A + random.randint(5,20)), str(max(10, A - random.randint(5,20)))]
    while len(opts) < 4:
        val = str(A + random.choice([-1, 1]) * random.randint(1, 40))
        if val not in opts: opts.append(val)
        
    random.shuffle(opts)
    ans_idx = opts.index(ans_str)
    ans_letter = ['A', 'B', 'C', 'D'][ans_idx]
    
    return f"{q_text};{opts[0]};{opts[1]};{opts[2]};{opts[3]};{ans_letter},,,,,,,,"

# 2. Algebra a, b
def gen_algebra():
    # a - b = D, a^2 + b^2 = S, find ab.
    b = random.randint(2, 20)
    a = b + random.randint(2, 20)
    D = a - b
    S = a*a + b*b
    ab = a * b
    
    q_text = f"If a - b = {D} and a² + b² = {S}, find the value of ab."
    ans_str = str(ab)
    
    opts = [ans_str, str(ab + random.randint(2,10)), str(ab - random.randint(2,10))]
    while len(opts) < 4:
        val = str(ab + random.choice([-1, 1]) * random.randint(1, 20))
        if val not in opts: opts.append(val)
        
    random.shuffle(opts)
    ans_idx = opts.index(ans_str)
    ans_letter = ['A', 'B', 'C', 'D'][ans_idx]
    
    return f"{q_text};{opts[0]};{opts[1]};{opts[2]};{opts[3]};{ans_letter},,,,,,,,"

# 3. Salary Ratio
def gen_salary_ratio():
    r1, r2, r3 = random.sample(range(1, 10), 3)
    r1, r2, r3 = sorted([r1, r2, r3])
    i1 = random.choice([10, 15, 20, 25, 30, 40, 50])
    i2 = random.choice([10, 15, 20, 25, 30, 40, 50])
    i3 = random.choice([10, 15, 20, 25, 30, 40, 50])
    
    n1 = r1 * (100 + i1)
    n2 = r2 * (100 + i2)
    n3 = r3 * (100 + i3)
    
    div = gcd_three(n1, n2, n3)
    f1, f2, f3 = n1//div, n2//div, n3//div
    
    q_text = f"The salaries A, B, and C are in the ratio {r1}:{r2}:{r3}. If increments of {i1}%, {i2}%, and {i3}% are allowed in their salaries, then what will be the new ratio of their salaries?"
    ans_str = f"{f1}:{f2}:{f3}"
    
    opts = [ans_str, f"{f1+1}:{f2}:{f3}", f"{f1}:{max(1, f2-1)}:{f3}"]
    opts = list(set(opts))
    while len(opts) < 4:
        val = f"{random.randint(max(1, f1-3), f1+5)}:{random.randint(max(1, f2-3), f2+5)}:{random.randint(max(1, f3-3), f3+5)}"
        if val not in opts and val != f"{f1}:{f2}:{f3}":
            opts.append(val)
            
    random.shuffle(opts)
    ans_idx = opts.index(ans_str)
    ans_letter = ['A', 'B', 'C', 'D'][ans_idx]
    
    return f"{q_text};{opts[0]};{opts[1]};{opts[2]};{opts[3]};{ans_letter},,,,,,,,"

# 4. Shadow
def gen_shadow():
    # H1 / S1 = H2 / S2
    ratio = random.choice([1.2, 1.5, 1.8, 2.0, 2.3, 2.5, 3.0])
    h1 = float(random.randint(10, 30))
    s1 = round(h1 * ratio, 2)
    h2 = float(random.randint(15, 45))
    s2 = round(h2 * ratio, 2)
    
    # Just in case of floating point minor drift, format
    h1_str = f"{h1:g}"
    h2_str = f"{h2:g}"
    s1_str = f"{s1:g}"
    s2_str = f"{s2:g}"
    
    q_text = f"A flagstaff {h1_str} m high casts a shadow of length {s1_str} m. The height of a building, which casts a shadow of length {s2_str} m under similar conditions, will be:"
    ans_str = f"{h2_str} m"
    
    opts = [ans_str, f"{h2+1.5:g} m", f"{h2-2.5:g} m"]
    while len(opts) < 4:
        val = f"{h2 + random.choice([-1.5, -2, 2, 2.5, 3]):g} m"
        if val not in opts: opts.append(val)
        
    random.shuffle(opts)
    ans_idx = opts.index(ans_str)
    ans_letter = ['A', 'B', 'C', 'D'][ans_idx]
    
    return f"{q_text};{opts[0]};{opts[1]};{opts[2]};{opts[3]};{ans_letter},,,,,,,,"

# 5. Commodity Price
def gen_commodity():
    yr = random.randint(1995, 2015)
    px = random.randint(200, 600)  # in paise
    py = px + random.randint(100, 300) # y starts higher
    
    p1 = random.randint(30, 60) # x growth rate
    p2 = random.randint(10, 25) # y growth rate (slower)
    
    # Needs to cross and hit a target difference exactly.
    delta = p1 - p2
    years_passed = random.randint(5, 15)
    
    final_x = px + p1 * years_passed
    final_y = py + p2 * years_passed
    diff = final_x - final_y # target diff in paise
    
    while diff <= 0: # Ensure x overtakes y
        years_passed += 1
        final_x = px + p1 * years_passed
        final_y = py + p2 * years_passed
        diff = final_x - final_y
        
    px_str = f"{px/100:.2f}"
    py_str = f"{py/100:.2f}"
    
    ans_year = yr + years_passed
    
    q_text = f"The price of commodity X increases by {p1} paise every year, while the price of commodity Y increases by {p2} paise every year. If in {yr}, the price of commodity X was Rs. {px_str} and that of Y was Rs. {py_str}, in which year will commodity X cost {diff} paise more than commodity Y?"
    ans_str = str(ans_year)
    
    opts = [ans_str, str(ans_year + 1), str(ans_year - 1)]
    while len(opts) < 4:
        val = str(ans_year + random.randint(-4, 4))
        if val not in opts: opts.append(val)
        
    random.shuffle(opts)
    ans_idx = opts.index(ans_str)
    ans_letter = ['A', 'B', 'C', 'D'][ans_idx]
    
    return f"{q_text};{opts[0]};{opts[1]};{opts[2]};{opts[3]};{ans_letter},,,,,,,,"

for _ in range(50):
    questions.append(gen_exam_rooms())
    questions.append(gen_algebra())
    questions.append(gen_salary_ratio())
    questions.append(gen_shadow())
    questions.append(gen_commodity())

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

print(f"Generated and appended {len(questions)} original template variations.")
