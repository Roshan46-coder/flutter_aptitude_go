import csv
import os
import random
import uuid
import math

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\quantitative_aptitude"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "quantitative_aptitude.csv")

if not os.path.exists(IMAGES_DIR):
    os.makedirs(IMAGES_DIR)

def save_svg(svg_content):
    filename = f"vis_{uuid.uuid4().hex[:8]}.svg"
    filepath = os.path.join(IMAGES_DIR, filename)
    with open(filepath, "w", encoding='utf-8') as f:
        f.write(svg_content)
    return filename

questions = []

def add_q(text, a, b, c, d, ans):
    text = text.replace(";", ",")
    questions.append(f"{text};{a};{b};{c};{d};{ans},,,,,,,,")

# Helper for shuffling options
def shuffle_and_add(text, correct, dummy1, dummy2, dummy3):
    opts = [correct, dummy1, dummy2, dummy3]
    random.shuffle(opts)
    ans_idx = opts.index(correct)
    ans_char = chr(65 + ans_idx)
    add_q(text, opts[0], opts[1], opts[2], opts[3], ans_char)

print("Generating numerical variations for Quantitative Aptitude...")

# 1. Percentages: Passing Marks
for _ in range(30):
    pass_pct = random.randint(30, 45)  # e.g., 33%
    max_marks = random.choice([300, 400, 500, 600, 800, 1000])
    pass_marks = int((pass_pct / 100.0) * max_marks)
    fail_by = random.randint(10, 50)
    got_marks = pass_marks - fail_by
    q_txt = f"A student has to obtain {pass_pct}% of the total marks to pass. He got {got_marks} marks and failed by {fail_by} marks. The maximum marks are:"
    shuffle_and_add(q_txt, str(max_marks), str(max_marks - 100), str(max_marks + 100), str(max_marks + 50))

# 2. Profit & Loss: Vendor Buying/Selling
for _ in range(30):
    # Buy at `b` for a rupee. Sell at `s` for a rupee to gain `g`%.
    # CP of 1 toffee = 1/b. SP of 1 toffee = 1/s.
    # Gain% = ((1/s - 1/b) / (1/b)) * 100 = (b/s - 1) * 100
    # To have clean integers, pick s and b (b > s).
    s = random.randint(3, 8)
    diff = random.choice([1, 2])
    b = s + diff
    g = int(((b / s) - 1) * 100)
    q_txt = f"A vendor bought toffees at {b} for a rupee. How many for a rupee must he sell to gain {g}%?"
    shuffle_and_add(q_txt, str(s), str(s - 1), str(s + 1), str(s + 2))

# 3. Simple Interest: Amount over years
for _ in range(30):
    P = random.choice([500, 600, 700, 800, 1000, 1200, 1500])
    R = random.randint(4, 12)
    T1 = random.randint(2, 4)
    T2 = T1 + random.randint(1, 2)
    A1 = int(P + (P * R * T1) / 100)
    A2 = int(P + (P * R * T2) / 100)
    q_txt = f"A sum of money at simple interest amounts to Rs. {A1} in {T1} years and to Rs. {A2} in {T2} years. The sum is:"
    shuffle_and_add(q_txt, f"Rs. {P}", f"Rs. {P - 50}", f"Rs. {P + 50}", f"Rs. {P + 100}")

# 4. Ages: Ratios and years later
for _ in range(30):
    # Base ratio of ages = 3:1 -> Father=3x, Son=x
    # Father is "n times" means F = n*S
    mult_now = random.choice([3, 4, 5]) 
    mult_later = mult_now - 1 # Ensure integer ratio
    S_now = random.randint(5, 15)
    F_now = S_now * mult_now
    # We want F_now + Y = mult_later * (S_now + Y)
    # => F_now - mult_later * S_now = Y * (mult_later - 1)
    # This might not yield nice integers. Let's do it constructively.
    y = random.choice([4, 5, 8, 10])
    # Assume Son is x now. F = mult_now * x.
    # In y years, F+y = mult_later * (x + y)
    # => mult_now*x + y = mult_later*x + mult_later*y
    # => x(mult_now - mult_later) = y(mult_later - 1)
    
    # Simpler construct:
    son_age = random.randint(8, 20)
    father_mult = random.choice([3, 4])
    father_age = son_age * father_mult
    y_years = random.choice([5, 10, 12])
    # We just ask for the sum of their ages after y years
    ans = (son_age + y_years) + (father_age + y_years)
    
    q_txt = f"A father's age is {father_mult} times his son's age. If the son is {son_age} years old now, what will be the sum of their ages after {y_years} years?"
    shuffle_and_add(q_txt, f"{ans} years", f"{ans - 5} years", f"{ans + 5} years", f"{ans + 10} years")

# 5. Time & Work: Two people
for _ in range(30):
    A_days = random.choice([10, 12, 15, 20])
    B_days = random.choice([20, 24, 30, 40])
    work_together = random.choice([3, 4, 5, 6])
    # Fraction of work done = work_together * (1/A + 1/B)
    # Fraction left = 1 - work_together * (A+B)/(A*B)
    frac_num = A_days * B_days - work_together * (A_days + B_days)
    frac_den = A_days * B_days
    # simplify fraction
    gcd = math.gcd(frac_num, frac_den)
    num = frac_num // gcd
    den = frac_den // gcd
    if num <= 0:
        continue # Avoid negative/zero work left
        
    ans_str = f"{num}/{den}"
    q_txt = f"A can do a work in {A_days} days and B in {B_days} days. If they work on it together for {work_together} days, then the fraction of the work that is left is:"
    opts = [ans_str, f"{abs(num-1)}/{den}", f"{num}/{den+1}", f"{num+1}/{den}"]
    random.shuffle(opts)
    add_q(q_txt, opts[0], opts[1], opts[2], opts[3], chr(65 + opts.index(ans_str)))

# 6. Trains: Speed and length crossing pole
for _ in range(30):
    kph = random.choice([54, 72, 90, 108])
    mps = int(kph * (5/18))
    sec = random.choice([8, 10, 12, 15])
    length = mps * sec
    q_txt = f"A train running at the speed of {kph} km/hr crosses a pole in {sec} seconds. What is the length of the train?"
    shuffle_and_add(q_txt, f"{length} metres", f"{length - 20} metres", f"{length + 40} metres", f"{length + 10} metres")

# 7. Probability (Coins)
for _ in range(15):
    n_coins = random.choice([3, 4])
    k_heads = random.choice([1, 2, 3])
    q_txt = f"If {n_coins} unbiased coins are tossed, what is the probability of getting exactly {k_heads} heads?"
    # P = C(n,k) / 2^n
    ways = math.comb(n_coins, k_heads)
    total = 2**n_coins
    gcd = math.gcd(ways, total)
    num = ways // gcd
    den = total // gcd
    ans = f"{num}/{den}"
    shuffle_and_add(q_txt, ans, f"{num+1}/{den}", f"{num}/{den-1}", f"{num-1}/{den}")

# 8. Geometry (Visual Pattern Scaling)
for _ in range(25):
    # Scale dimension of Rectangle diagonal
    w = random.choice([10, 12, 16, 20])
    h = random.choice([8, 9, 12, 15])
    diag = round(math.sqrt(w**2 + h**2), 2)
    # Create SVG
    geom_svg = f'''<svg width="250" height="200" xmlns="http://www.w3.org/2000/svg">
        <rect x="50" y="50" width="150" height="100" fill="none" stroke="black" stroke-width="2"/>
        <line x1="50" y1="50" x2="200" y2="150" stroke="blue" stroke-dasharray="5"/>
        <text x="120" y="40">{w} cm</text>
        <text x="5" y="105">{h} cm</text>
        <text x="120" y="95" fill="blue" transform="rotate(33, 120, 95)">d = ?</text>
    </svg>'''
    fname = save_svg(geom_svg)
    if diag.is_integer():
        ans_str = f"{int(diag)} cm"
    else:
        ans_str = f"{diag} cm"
        
    q_txt = f"Find the length of the diagonal of a rectangle whose sides are {w} cm and {h} cm.<br><img src='images/{fname}' style='max-width:100%;'>"
    shuffle_and_add(q_txt, ans_str, f"{int(diag)+2} cm", f"{int(diag)-1} cm", f"{int(diag)+4} cm")

# 9. Data Interpretation (Visual Bar Charts Scaling)
for _ in range(20):
    # Randomize y values for 2018 and 2020
    v1 = random.choice([50, 60, 80, 100])
    v2 = random.choice([120, 150, 160, 200])
    pct_inc = int(((v2 - v1) / v1) * 100)
    
    # Scale SVG heights accordingly (Hmax = 200)
    # Let max value be 200 -> H=160
    # Map: height = (v / 200) * 160 = v * 0.8
    h1 = int(v1 * 0.8)
    h2 = int(v2 * 0.8)
    
    di_svg = f'''<svg width="400" height="250" xmlns="http://www.w3.org/2000/svg">
        <text x="150" y="20" font-weight="bold">Sales Data (in 1000s)</text>
        <line x1="50" y1="200" x2="350" y2="200" stroke="black" stroke-width="2"/>
        <line x1="50" y1="200" x2="50" y2="40" stroke="black" stroke-width="2"/>
        <text x="25" y="200">0</text>
        <text x="20" y="150">50</text>
        <text x="10" y="100">100</text>
        <text x="10" y="50">150</text>

        <rect x="100" y="{200-h1}" width="40" height="{h1}" fill="steelblue"/>
        <text x="105" y="{200-h1-10}">{v1}</text>
        <text x="105" y="220">2018</text>
        
        <rect x="220" y="{200-h2}" width="40" height="{h2}" fill="darkorange"/>
        <text x="220" y="{200-h2-10}">{v2}</text>
        <text x="225" y="220">2020</text>
    </svg>'''
    fname = save_svg(di_svg)
    q_txt = f"Study the bar chart showing sales data.<br>What is the percentage increase in sales from 2018 to 2020?<br><img src='images/{fname}' style='max-width:100%;'>"
    shuffle_and_add(q_txt, f"{pct_inc}%", f"{pct_inc - 10}%", f"{pct_inc + 20}%", f"{pct_inc + 50}%")

print(f"Adding {len(questions)} variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done generating variations.")
