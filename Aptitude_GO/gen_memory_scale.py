import os
import csv
import random
import hashlib
import string

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\memory_and_attention"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "memory_and_attention.csv")

questions = []

def save_svg(svg_content):
    h = hashlib.md5(svg_content.encode('utf-8')).hexdigest()[:10]
    filename = f"mem_sc_{h}.svg"
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

print("Generating Memory & Attention - Scaling...")

# 1. Visual Matrix (Missing Piece Memory)
for _ in range(120):
    grid = [random.choice(['red', 'blue', 'green', 'yellow', 'purple', 'black']) for _ in range(9)]
    # Pick a random missing index
    missing = random.randint(0, 8)
    ans_color = grid[missing]
    
    svg = f'<svg width="150" height="150" xmlns="http://www.w3.org/2000/svg">'
    for i in range(3):
        for j in range(3):
            idx = i*3 + j
            color = "?" if idx == missing else grid[idx]
            if color == "?":
                svg += f'<rect x="{j*50}" y="{i*50}" width="50" height="50" fill="white" stroke="black" stroke-width="2"/>'
                svg += f'<text x="{j*50 + 25}" y="{i*50 + 30}" font-size="20" text-anchor="middle">?</text>'
            else:
                svg += f'<rect x="{j*50}" y="{i*50}" width="50" height="50" fill="{color}" stroke="black" stroke-width="2"/>'
    svg += '</svg>'
    fname = save_svg(svg)
    
    ans = ans_color.capitalize()
    opts = [ans]
    colors = ['Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Black', 'White', 'Orange']
    while len(opts) < 4:
        cand = random.choice(colors)
        if cand not in opts: opts.append(cand)
        
    q_txt = f"Test your visual memory. Assume the 3x3 colored grid is symmetric or follows a color frequency rule.<br><img src='images/{fname}' style='max-width:100%;'><br>If there must be exactly 2 of each color represented (except one which has 3), what color is missing?"
    
    # Real logic: count frequencies. Whichever color is needed to balance.
    freq = {}
    for c in grid:
        if c != grid[missing]: # don't count the missing one
            freq[c] = freq.get(c, 0) + 1
            
    # That rule is too complex and inconsistent. Let's just do a simpler attention check.
    q_txt = f"Attention check: Based on the grid below, what is the color of the square immediately to the {'right' if missing % 3 == 0 else 'left'} of the missing '?' block? (Assume standard wrap-around if on edge)<br><img src='images/{fname}' style='max-width:100%;'>"
    
    if missing % 3 == 0:
        ans_idx = (missing + 1) % 9
    else:
        ans_idx = (missing - 1) % 9
        
    ans = grid[ans_idx].capitalize()
    
    opts = [ans]
    while len(opts) < 4:
        cand = random.choice(colors)
        if cand not in opts: opts.append(cand)
    
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

# 2. Text Grid Anomaly (Attention)
for _ in range(120):
    char_map = [('b', 'd'), ('p', 'q'), ('O', 'Q'), ('S', '5'), ('1', 'l')]
    base, anomaly = random.choice(char_map)
    
    # 5x10 grid
    grid = [base for _ in range(50)]
    idx = random.randint(0, 49)
    grid[idx] = anomaly
    
    row = (idx // 10) + 1
    col = (idx % 10) + 1
    
    grid_str = ""
    for r in range(5):
        grid_str += " ".join(grid[r*10 : (r+1)*10]) + "<br>"
        
    ans = f"Row {row}, Column {col}"
    
    opts = [ans]
    while len(opts) < 4:
        r_d = random.randint(1, 5)
        c_d = random.randint(1, 10)
        cand = f"Row {r_d}, Column {c_d}"
        if cand not in opts: opts.append(cand)
        
    q_txt = f"Attention to Detail: Find the exactly 1 anomaly ('{anomaly}') hidden in the grid of '{base}'s.<br><code>{grid_str}</code><br>What are its coordinates? (Row 1 is top, Col 1 is left)"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

# 3. Object-Symbol Dictionary Memorization
for _ in range(120):
    symbols = ['@', '#', '$', '%', '&', '*', '+', '=']
    letters = random.sample(string.ascii_uppercase[:10], 4)
    mapped_syms = random.sample(symbols, 4)
    
    dict_str = " | ".join([f"{l} = {s}" for l, s in zip(letters, mapped_syms)])
    
    # Build a combo string
    length = random.randint(4, 6)
    target_letters = [random.choice(letters) for _ in range(length)]
    query = "".join(target_letters)
    
    ans = "".join([mapped_syms[letters.index(l)] for l in target_letters])
    
    opts = [ans]
    while len(opts) < 4:
        cand = "".join([random.choice(symbols) for _ in range(length)])
        if cand not in opts: opts.append(cand)
        
    q_txt = f"Memorize this cipher: <b>{dict_str}</b><br>Translate the following sequence accurately: <b>{query}</b>"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])


print(f"Adding {len(questions)} mass variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done mass generating memory variations.")
