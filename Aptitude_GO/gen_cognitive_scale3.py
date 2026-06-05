import os
import csv
import random
import hashlib

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\cognitive_ability"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "cognitive_ability.csv")

questions = []

def save_svg(svg_content):
    h = hashlib.md5(svg_content.encode('utf-8')).hexdigest()[:10]
    filename = f"cog_sc3_{h}.svg"
    filepath = os.path.join(IMAGES_DIR, filename)
    with open(filepath, "w", encoding='utf-8') as f:
        f.write(svg_content)
    return filename

def add_q(text, a, b, c, d, ans):
    text = str(text).replace(";", ",")
    questions.append(f"{text};{a};{b};{c};{d};{ans},,,,,,,,")

def shuffle_and_add(text, correct, dummy1, dummy2, dummy3):
    opts = [correct, dummy1, dummy2, dummy3]
    random.shuffle(opts)
    ans_idx = opts.index(correct)
    ans_char = chr(65 + ans_idx)
    add_q(text, opts[0], opts[1], opts[2], opts[3], ans_char)

print("Generating scalable abstract wave 4 (Target ~350)...")

# 1. Venn Diagram Syllogisms
for _ in range(120):
    a = random.randint(1, 20)
    b = random.randint(1, 20)
    c = random.randint(1, 20)
    ab = random.randint(1, 20)
    bc = random.randint(1, 20)
    ac = random.randint(1, 20)
    abc = random.randint(1, 20)
    
    svg = f'''<svg width="250" height="200" xmlns="http://www.w3.org/2000/svg">
        <!-- Circle A (Top Left) -->
        <circle cx="90" cy="80" r="60" fill="red" opacity="0.3" stroke="black"/>
        <!-- Circle B (Top Right) -->
        <circle cx="160" cy="80" r="60" fill="blue" opacity="0.3" stroke="black"/>
        <!-- Circle C (Bottom Center) -->
        <circle cx="125" cy="140" r="60" fill="green" opacity="0.3" stroke="black"/>
        
        <text x="60" y="60" font-weight="bold">X</text>
        <text x="180" y="60" font-weight="bold">Y</text>
        <text x="120" y="180" font-weight="bold">Z</text>
        
        <!-- Values -->
        <text x="60" y="80" font-size="12">{a}</text>
        <text x="180" y="80" font-size="12">{b}</text>
        <text x="120" y="160" font-size="12">{c}</text>
        <text x="120" y="70" font-size="12">{ab}</text>
        <text x="90" y="120" font-size="12">{ac}</text>
        <text x="150" y="120" font-size="12">{bc}</text>
        <text x="120" y="105" font-size="12">{abc}</text>
    </svg>'''
    fname = save_svg(svg)
    
    # Question variations
    q_type = random.choice([1, 2, 3, 4])
    if q_type == 1:
        q_txt = f"Observe the Venn diagram below. How many belong to exactly X and Y, but not Z?<br><img src='images/{fname}' style='max-width:100%;'>"
        ans = str(ab)
    elif q_type == 2:
        q_txt = f"Observe the Venn diagram below. How many belong to exactly and uniquely Z?<br><img src='images/{fname}' style='max-width:100%;'>"
        ans = str(c)
    elif q_type == 3:
        q_txt = f"Observe the Venn diagram below. How many belong to all three categories (X, Y, and Z) simultaneously?<br><img src='images/{fname}' style='max-width:100%;'>"
        ans = str(abc)
    else:
        q_txt = f"Observe the Venn diagram below. How many belong to either X or Z, but specifically excluding any intersection involving Y?<br><img src='images/{fname}' style='max-width:100%;'>"
        ans = str(a + c + ac)
        
    opts = [ans]
    while len(opts) < 4:
        cand = str(random.randint(1, 50))
        if cand not in opts: opts.append(cand)
        
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

# 2. Mathematical Symbol Grids (3x3 Sudoku logic)
for _ in range(120):
    start = random.randint(1, 10)
    step = random.randint(1, 5)
    
    # 3x3 grid filled with an arithmetic sequence
    # 0 1 2
    # 3 4 5
    # 6 7 8
    grid = [start + i*step for i in range(9)]
    # Pick a random missing index
    missing = random.randint(0, 8)
    ans = str(grid[missing])
    
    svg = f'<svg width="150" height="150" xmlns="http://www.w3.org/2000/svg">'
    for i in range(3):
        for j in range(3):
            idx = i*3 + j
            val_txt = "?" if idx == missing else str(grid[idx])
            svg += f'<rect x="{j*50}" y="{i*50}" width="50" height="50" fill="white" stroke="black" stroke-width="2"/>'
            svg += f'<text x="{j*50 + 25}" y="{i*50 + 30}" font-size="20" text-anchor="middle">{val_txt}</text>'
    svg += '</svg>'
    fname = save_svg(svg)
    
    q_txt = f"Find the missing number in the logical sequence grid below:<br><img src='images/{fname}' style='max-width:100%;'>"
    opts = [ans]
    while len(opts) < 4:
        cand = str(random.randint(1, start + 12*step))
        if cand not in opts: opts.append(cand)
        
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

# 3. Geometric Weight Equations
for _ in range(120):
    sq = random.randint(1, 10)
    tri = random.randint(1, 10)
    circ = random.randint(1, 10)
    
    svg = f'''<svg width="250" height="150" xmlns="http://www.w3.org/2000/svg">
        <rect x="10" y="10" width="20" height="20" fill="blue"/>
        <text x="35" y="25">+</text>
        <polygon points="50,10 40,30 60,30" fill="red"/>
        <text x="65" y="25">=</text>
        <text x="80" y="25">{sq+tri}</text>
        
        <circle cx="20" cy="70" r="10" fill="green"/>
        <text x="35" y="75">+</text>
        <circle cx="50" cy="70" r="10" fill="green"/>
        <text x="65" y="75">=</text>
        <text x="80" y="75">{circ*2}</text>
        
        <polygon points="20,110 10,130 30,130" fill="red"/>
        <text x="35" y="125">+</text>
        <circle cx="50" cy="120" r="10" fill="green"/>
        <text x="65" y="125">+</text>
        <rect x="80" y="110" width="20" height="20" fill="blue"/>
        <text x="105" y="125">=</text>
        <text x="120" y="125">?</text>
    </svg>'''
    fname = save_svg(svg)
    
    ans = str(sq + tri + circ)
    opts = [ans]
    while len(opts) < 4:
        cand = str(random.randint(3, 40))
        if cand not in opts: opts.append(cand)
        
    q_txt = f"Determine the value of the missing sum based on the symbol equations:<br><img src='images/{fname}' style='max-width:100%;'>"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

print(f"Adding {len(questions)} wave 4 cognitive variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done mass generating cognitive abstract combinations.")
