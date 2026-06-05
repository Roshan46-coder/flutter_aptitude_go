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
    filename = f"cog_sc2_{h}.svg"
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

print("Generating scalable abstract wave 3 (Target ~350)...")

# 1. Gears Rotation
for _ in range(120):
    num_gears = random.randint(3, 8)
    # 0 is CW, 1 is CCW
    start_dir = random.choice([0, 1])
    
    svg = f'<svg width="{num_gears*80+40}" height="100" xmlns="http://www.w3.org/2000/svg">'
    for i in range(num_gears):
        cx = 50 + i * 80
        svg += f'<circle cx="{cx}" cy="50" r="30" fill="none" stroke="black" stroke-width="2"/>'
        # Add teeth
        svg += f'<circle cx="{cx}" cy="50" r="35" fill="none" stroke="black" stroke-width="1" stroke-dasharray="10"/>'
        svg += f'<text x="{cx-5}" y="55" font-weight="bold">{chr(65+i)}</text>'
        
    # Draw arrow on first gear
    dir_text = "Clockwise" if start_dir == 0 else "Counter-Clockwise"
    y_arr = 10 if start_dir == 0 else 90
    svg += f'<path d="M 40,{y_arr} Q 50,0 60,{y_arr}" fill="none" stroke="red" stroke-width="3"/>'
    svg += '</svg>'
    fname = save_svg(svg)
    
    end_dir = start_dir if (num_gears - 1) % 2 == 0 else 1 - start_dir
    ans = "Clockwise" if end_dir == 0 else "Counter-Clockwise"
    d1 = "Counter-Clockwise" if start_dir == 0 else "Clockwise"
    
    target_char = chr(65 + num_gears - 1)
    q_txt = f"A series of interlocked gears is shown below. If Gear A turns {dir_text}, which direction will Gear {target_char} turn?<br><img src='images/{fname}' style='max-width:100%;'>"
    opts = [ans, d1, "It will not turn", "Alternates direction"]
    if opts[0] == opts[1]: opts[1] = "None"
    shuffle_and_add(q_txt, opts[0], opts[1], opts[2], opts[3])

# 2. Domino Math Sequence
for _ in range(120):
    start_top = random.randint(0, 3)
    start_bot = random.randint(0, 3)
    step_top = random.choice([1, 2, -1, -2])
    step_bot = random.choice([1, 2, -1, -2])
    
    def render_dots(val, px, py):
        v = val % 7 # standard domino 0-6
        if v < 0: v += 7
        dots = ""
        coords = {
            1: [(15,15)],
            2: [(5,5), (25,25)],
            3: [(5,5), (15,15), (25,25)],
            4: [(5,5), (25,5), (5,25), (25,25)],
            5: [(5,5), (25,5), (15,15), (5,25), (25,25)],
            6: [(5,5), (25,5), (5,15), (25,15), (5,25), (25,25)]
        }
        if v in coords:
            for cx, cy in coords[v]:
                dots += f'<circle cx="{px+cx}" cy="{py+cy}" r="3" fill="black"/>'
        return dots

    def render_domino(top, bot, px):
        return f'''
        <rect x="{px}" y="10" width="30" height="60" fill="white" stroke="black" stroke-width="2" rx="3"/>
        <line x1="{px}" y1="40" x2="{px+30}" y2="40" stroke="black"/>
        {render_dots(top, px, 10)}
        {render_dots(bot, px, 40)}
        '''
        
    svg = f'<svg width="250" height="80" xmlns="http://www.w3.org/2000/svg">'
    for i in range(3):
        t = (start_top + i*step_top) % 7
        b = (start_bot + i*step_bot) % 7
        if t < 0: t += 7
        if b < 0: b+= 7
        svg += render_domino(t, b, 10 + i*50)
        
    # the 4th domino is blank representing the question
    svg += f'''
        <rect x="160" y="10" width="30" height="60" fill="none" stroke="black" stroke-dasharray="4" rx="3"/>
        <text x="170" y="45" font-size="20">?</text>
    </svg>'''
    
    fname = save_svg(svg)
    ans_t = (start_top + 3*step_top) % 7
    ans_b = (start_bot + 3*step_bot) % 7
    if ans_t < 0: ans_t += 7
    if ans_b < 0: ans_b += 7
    
    ans = f"Top: {ans_t}, Bottom: {ans_b}"
    
    opts = [ans]
    while len(opts) < 4:
        cand_t = random.randint(0, 6)
        cand_b = random.randint(0, 6)
        cand = f"Top: {cand_t}, Bottom: {cand_b}"
        if cand not in opts: opts.append(cand)
        
    q_txt = f"Find the dots on the next domino in the sequence (assuming blank=0, values loop from 0-6):<br><img src='images/{fname}' style='max-width:100%;'>"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

# 3. Shape Grid Counting (Rectangles / Triangles approximation via grid)
for _ in range(120):
    rows = random.randint(2, 5)
    cols = random.randint(2, 5)
    
    svg = f'<svg width="{cols*30 + 20}" height="{rows*30 + 20}" xmlns="http://www.w3.org/2000/svg">'
    for r in range(rows):
        for c in range(cols):
            svg += f'<rect x="{10 + c*30}" y="{10 + r*30}" width="30" height="30" fill="none" stroke="black"/>'
    svg += '</svg>'
    
    fname = save_svg(svg)
    
    ans = str((rows*(rows+1)//2) * (cols*(cols+1)//2))
    opts = [ans]
    while len(opts) < 4:
        cand = str(random.randint(4, 200))
        if cand not in opts: opts.append(cand)
        
    q_txt = f"How many total rectangles (of any size) can be formed in this grid?<br><img src='images/{fname}' style='max-width:100%;'>"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

print(f"Adding {len(questions)} wave 3 cognitive variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done mass generating cognitive abstract combinations.")
