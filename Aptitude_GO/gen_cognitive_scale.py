import os
import csv
import random
import uuid

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\cognitive_ability"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "cognitive_ability.csv")

questions = []

import hashlib
def save_svg(svg_content):
    h = hashlib.md5(svg_content.encode('utf-8')).hexdigest()[:10]
    filename = f"cog_sc_{h}.svg"
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

print("Generating scalable abstract combinations (Target ~350)...")

# 1. Clock Face Angle / Rotation prediction
for _ in range(80):
    start_hour = random.randint(1, 11)
    mins = random.choice([0, 15, 30, 45])
    add_mins = random.choice([45, 90, 135])
    
    # Calculate new time
    total_mins = start_hour * 60 + mins + add_mins
    new_h = (total_mins // 60) % 12
    if new_h == 0: new_h = 12
    new_m = total_mins % 60
    
    def time_to_str(h, m): return f"{h:02d}:{m:02d}"
    
    def hand_angle(hours, minutes, length, color, is_hour=False):
        # 12 is at top (0 degrees). Rotation is CW.
        if is_hour:
            angle = (hours % 12) * 30 + (minutes * 0.5)
        else:
            angle = minutes * 6
            
        svg = f'<g transform="translate(50,50) rotate({angle})">'
        svg += f'<line x1="0" y1="0" x2="0" y2="-{length}" stroke="{color}" stroke-width="3"/>'
        svg += '</g>'
        return svg
        
    svg = f'''<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
        <circle cx="50" cy="50" r="45" fill="none" stroke="black" stroke-width="2"/>
        <circle cx="50" cy="50" r="3" fill="black"/>
        {hand_angle(start_hour, mins, 20, "blue", True)}
        {hand_angle(0, mins, 35, "red", False)}
    </svg>'''
    fname = save_svg(svg)
    
    ans = time_to_str(new_h, new_m)
    
    opts = [ans]
    while len(opts) < 4:
        dummy_h = (new_h + random.randint(-3, 3)) % 12
        if dummy_h == 0: dummy_h = 12
        dummy_m = (new_m + random.choice([-15, 15, 30])) % 60
        cand = time_to_str(dummy_h, dummy_m)
        if cand not in opts: opts.append(cand)
        
    q_txt = f"A clock currently shows the time as depicted below.<br><img src='images/{fname}' style='max-width:100%;'><br>If the minute hand rotates exactly {add_mins} degrees clockwise, what time will the clock show? (Assume 1 minute = 6 degrees)"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

# 2. Sequence Progressions: Counting intersections
for _ in range(80):
    lines = random.randint(2, 5)
    polygon_sides = random.randint(3, 6)
    # E.g. 3 parallel lines intersected by 1 perpendicular line = 3 intersections
    cross_lines = random.randint(1, 3)
    
    intersections = lines * cross_lines
    
    svg = f'''<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
        <rect x="0" y="0" width="100" height="100" fill="none" stroke="black" stroke-width="2"/>
        '''
    for i in range(lines):
        y = 20 + i * (60 // max(1, lines-1))
        svg += f'<line x1="10" y1="{y}" x2="90" y2="{y}" stroke="blue" stroke-width="2"/>'
    for i in range(cross_lines):
        x = 20 + i * (60 // max(1, cross_lines-1))
        svg += f'<line x1="{x}" y1="10" x2="{x}" y2="90" stroke="red" stroke-width="2"/>'
    svg += '</svg>'
    
    fname = save_svg(svg)
    
    ans = str(intersections)
    opts = [ans]
    while len(opts) < 4:
        cand = str(random.randint(1, 15))
        if cand not in opts: opts.append(cand)
        
    q_txt = f"Observe the abstract geometric grid below.<br><img src='images/{fname}' style='max-width:100%;'><br>How many distinct intersection nodes exist between the two sets of parallel lines?"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

# 3. Mirror Line Reflections
for _ in range(90):
    char = random.choice(['F', 'R', 'P', 'L', 'G', 'B', 'K'])
    is_vertical = random.choice([True, False])
    
    if is_vertical:
        transform_rule = "scale(-1, 1)"
        mirror_line = '<line x1="100" y1="10" x2="100" y2="90" stroke="black" stroke-width="2" stroke-dasharray="4"/>'
        q_text_type = "vertical axis (left to right)"
    else:
        transform_rule = "scale(1, -1)"
        mirror_line = '<line x1="10" y1="50" x2="190" y2="50" stroke="black" stroke-width="2" stroke-dasharray="4"/>'
        q_text_type = "horizontal axis (top to bottom)"
        
    svg = f'''<svg width="200" height="100" xmlns="http://www.w3.org/2000/svg">
        {mirror_line}
        <text x="30" y="70" font-size="60" font-family="monospace">{char}</text>
        <text x="140" y="70" font-size="60" font-family="monospace" opacity="0.1">?</text>
    </svg>'''
    fname = save_svg(svg)
    
    ans = f"The character '{char}' is flipped symmetrically along the {q_text_type}."
    opts = [
        ans,
        f"The character '{char}' is rotated 180 degrees.",
        f"The character '{char}' is flipped symmetrically along the {'horizontal' if is_vertical else 'vertical'} axis.",
        f"The character '{char}' remains unchanged."
    ]
    if ans in opts: opts.remove(ans)
    
    q_txt = f"A shape is reflected across the dashed mirror line.<br><img src='images/{fname}' style='max-width:100%;'><br>Which transformation correctly describes the resulting image?"
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 4. Polygon Edge Arithmetic (Raven's Progressive Matrices proxy)
for _ in range(100):
    # Triangle(3) + Square(4) = Heptagon(7)
    s1 = random.randint(3, 5)
    s2 = random.randint(0, 4) # 0 is circle (considered 1 for this logic or 0)
    
    def get_poly_points(sides, r, cx, cy):
        import math
        if sides < 3: return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="black" stroke-width="2"/>'
        pts = []
        for i in range(sides):
            angle = 2 * math.pi * i / sides - math.pi/2
            px = cx + r * math.cos(angle)
            py = cy + r * math.sin(angle)
            pts.append(f"{px},{py}")
        return f'<polygon points="{" ".join(pts)}" fill="none" stroke="black" stroke-width="2"/>'
        
    svg = f'''<svg width="250" height="80" xmlns="http://www.w3.org/2000/svg">
        {get_poly_points(s1, 30, 40, 40)}
        <text x="85" y="45" font-size="20">+</text>
        {get_poly_points(s2, 30, 130, 40)}
        <text x="175" y="45" font-size="20">=</text>
        <text x="210" y="45" font-size="30">?</text>
    </svg>'''
    fname = save_svg(svg)
    
    val1 = s1
    val2 = s2 if s2 >= 3 else 0 # let circle = 0 edges
    total_edges = val1 + val2
    
    ans = f"A shape with {total_edges} edges"
    opts = [ans]
    while len(opts) < 4:
        cand = f"A shape with {random.randint(3, 10)} edges"
        if cand not in opts: opts.append(cand)
        
    q_txt = f"In this abstract arithmetic sequence, shapes represent their number of edges (a circle = 0 edges).<br><img src='images/{fname}' style='max-width:100%;'><br>Which outcome correctly completes the equation?"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

print(f"Adding {len(questions)} wave 2 cognitive variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done mass generating cognitive abstract combinations.")
