import os
import csv
import random
import uuid

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\cognitive_ability"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "cognitive_ability.csv")

if not os.path.exists(IMAGES_DIR):
    os.makedirs(IMAGES_DIR)

questions = []

import hashlib
def save_svg(svg_content):
    h = hashlib.md5(svg_content.encode('utf-8')).hexdigest()[:10]
    filename = f"cog_{h}.svg"
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

print("Generating Abstract & Cognitive Visuals...")

# 1. Cube Folding (Spatial Reasoning)
# We generate a standard cross net. A cross net has faces:
# Top (1), Middle-Left (2), Center (3), Middle-Right (4), Bottom (5), Far-Bottom (6)
# Opposite pairs are usually: (1 & 5), (2 & 4), (3 & 6)
for _ in range(50):
    symbols = ['★', '◼', '▲', '●', '✦', '✖']
    random.shuffle(symbols)
    
    # SVG construction
    svg = f'''<svg width="200" height="250" xmlns="http://www.w3.org/2000/svg">
        <rect x="75" y="25" width="50" height="50" fill="white" stroke="black" stroke-width="2"/>
        <text x="100" y="55" font-size="24" text-anchor="middle">{symbols[0]}</text>
        
        <rect x="25" y="75" width="50" height="50" fill="white" stroke="black" stroke-width="2"/>
        <text x="50" y="105" font-size="24" text-anchor="middle">{symbols[1]}</text>
        
        <rect x="75" y="75" width="50" height="50" fill="white" stroke="black" stroke-width="2"/>
        <text x="100" y="105" font-size="24" text-anchor="middle">{symbols[2]}</text>
        
        <rect x="125" y="75" width="50" height="50" fill="white" stroke="black" stroke-width="2"/>
        <text x="150" y="105" font-size="24" text-anchor="middle">{symbols[3]}</text>
        
        <rect x="75" y="125" width="50" height="50" fill="white" stroke="black" stroke-width="2"/>
        <text x="100" y="155" font-size="24" text-anchor="middle">{symbols[4]}</text>
        
        <rect x="75" y="175" width="50" height="50" fill="white" stroke="black" stroke-width="2"/>
        <text x="100" y="205" font-size="24" text-anchor="middle">{symbols[5]}</text>
    </svg>'''
    fname = save_svg(svg)
    
    # Pairs based on standard cross layout:
    # 0 is top, 4 is bottom -> opposite
    # 1 is left, 3 is right -> opposite
    # 2 is center, 5 is far bottom -> opposite
    pairs = [(symbols[0], symbols[4]), (symbols[1], symbols[3]), (symbols[2], symbols[5])]
    target_pair = random.choice(pairs)
    
    q_txt = f"Observe the 2D cube net below:<br><img src='images/{fname}' style='max-width:100%;'><br>If folded into a 3D cube, which symbol will be on the opposite face of <b>{target_pair[0]}</b>?"
    
    ans = target_pair[1]
    dummies = [s for s in symbols if s != target_pair[0] and s != target_pair[1]]
    random.shuffle(dummies)
    
    shuffle_and_add(q_txt, ans, dummies[0], dummies[1], dummies[2])

# 2. Pattern Sequence Recognition
# A dot moving along corners of a square. 4 states. Find the 5th (which is state 1 or another logical progression).
for _ in range(50):
    start_pos = random.randint(0, 3) # 0:TL, 1:TR, 2:BR, 3:BL
    direction = random.choice([1, -1]) # 1: CW, -1: CCW
    
    coords = [(20, 20), (80, 20), (80, 80), (20, 80)]
    
    seq = []
    for i in range(4):
        idx = (start_pos + (i * direction)) % 4
        cx, cy = coords[idx]
        svg_state = f'''
        <g transform="translate({i*110}, 0)">
            <rect x="10" y="10" width="80" height="80" fill="none" stroke="black" stroke-width="2"/>
            <circle cx="{cx}" cy="{cy}" r="10" fill="black"/>
        </g>
        '''
        seq.append(svg_state)
        
    # The 5th state will be the next step in the loop
    ans_idx = (start_pos + (4 * direction)) % 4
    ans_cx, cy = coords[ans_idx]
    
    svg_full = f'''<svg width="450" height="100" xmlns="http://www.w3.org/2000/svg">
        {''.join(seq)}
        <text x="400" y="55" font-size="24">?</text>
    </svg>'''
    fname = save_svg(svg_full)
    
    positions = ["Top-Left", "Top-Right", "Bottom-Right", "Bottom-Left"]
    ans = positions[ans_idx]
    opts = [p for p in positions if p != ans]
    
    q_txt = f"Analyze the sequence of boxes from left to right:<br><img src='images/{fname}' style='max-width:100%;'><br>Where will the dot be positioned in the next (5th) box?"
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 3. 2x2 Matrix Reasoning (Abstract Reasoning)
# A grid of 4 boxes where 1 is missing. Rule: Top row elements sum, or logical color flip.
for _ in range(50):
    # Rule: Shape remains same, color flips Black -> White -> Black
    shapes = ['circle', 'rect', 'polygon']
    s = random.choice(shapes)
    
    # 0 = white, 1 = black
    c1, c2, c3 = random.randint(0,1), random.randint(0,1), random.randint(0,1)
    # The missing c4 will complete the pattern such that rows have different or same inversions.
    # Let's say rule: Column 2 is inverted version of Column 1
    c2 = 1 - c1
    c4 = 1 - c3
    
    def get_shape(sh, col_val, px, py):
        fill = "black" if col_val == 1 else "white"
        if sh == 'circle':
            return f'<circle cx="{px+40}" cy="{py+40}" r="25" fill="{fill}" stroke="black" stroke-width="2"/>'
        elif sh == 'rect':
            return f'<rect x="{px+15}" y="{py+15}" width="50" height="50" fill="{fill}" stroke="black" stroke-width="2"/>'
        else: # triangle
            return f'<polygon points="{px+40},{py+10} {px+15},{py+65} {px+65},{py+65}" fill="{fill}" stroke="black" stroke-width="2"/>'

    svg = f'''<svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
        <rect x="0" y="0" width="200" height="200" fill="none" stroke="black" stroke-width="2"/>
        <line x1="100" y1="0" x2="100" y2="200" stroke="black" stroke-width="2"/>
        <line x1="0" y1="100" x2="200" y2="100" stroke="black" stroke-width="2"/>
        
        {get_shape(s, c1, 0, 0)}
        {get_shape(s, c2, 100, 0)}
        {get_shape(s, c3, 0, 100)}
        <text x="140" y="160" font-size="40" font-family="sans-serif">?</text>
    </svg>'''
    
    fname = save_svg(svg)
    
    ans_color = "Black" if c4 == 1 else "White"
    ans_shape = s.capitalize() if s != 'rect' else 'Square'
    if s == 'polygon': ans_shape = "Triangle"
    ans = f"{ans_color} {ans_shape}"
    
    wrong_color = "White" if c4 == 1 else "Black"
    d1 = f"{wrong_color} {ans_shape}"
    d2 = f"{ans_color} Circle" if ans_shape != "Circle" else f"{ans_color} Square"
    d3 = f"{wrong_color} Circle" if ans_shape != "Circle" else f"{wrong_color} Square"
    
    opts = list(set([d1, d2, d3]))
    while len(opts) < 3:
        opts.append("Missing Element")
        
    q_txt = f"Find the missing element to complete the 2x2 logical matrix:<br><img src='images/{fname}' style='max-width:100%;'><br>What should replace the question mark?"
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 4. Mental Rotation (Is it the same shape or mirrored?)
for _ in range(50):
    # Base L shape
    is_mirrored = random.choice([True, False])
    rot1 = random.randint(0, 3) * 90
    rot2 = rot1 + random.choice([90, 180, 270])
    
    # Render two L shapes
    def render_L(rot, mirror, px, py):
        scale = "-1, 1" if mirror else "1, 1"
        return f'''
        <g transform="translate({px}, {py}) rotate({rot}) scale({scale})">
            <polygon points="-20,-30 0,-30 0,10 30,10 30,30 -20,30" fill="orange" stroke="black" stroke-width="2"/>
        </g>
        '''
        
    svg = f'''<svg width="300" height="150" xmlns="http://www.w3.org/2000/svg">
        <line x1="150" y1="10" x2="150" y2="140" stroke="dashed" stroke-width="1" stroke-dasharray="5,5" stroke="gray"/>
        {render_L(rot1, False, 75, 75)}
        {render_L(rot2, is_mirrored, 225, 75)}
    </svg>'''
    fname = save_svg(svg)
    
    ans = "No, they are mirrored reflections." if is_mirrored else "Yes, they are the exact same shape rotated."
    d1 = "Yes, they are the exact same shape rotated." if is_mirrored else "No, they are mirrored reflections."
    d2 = "They are entirely different unrelated shapes."
    d3 = "Impossible to determine without 3D perspective."
    
    q_txt = f"Observe the two shapes. Assuming you can only rotate them in the 2D plane, are they the identical shape?<br><img src='images/{fname}' style='max-width:100%;'>"
    shuffle_and_add(q_txt, ans, d1, d2, d3)

# 5. Overlapping Transparency (Boolean XOR logic)
# Two overlapping shapes. Black + Black = White, Black + White = Black, White + White = White
for _ in range(50):
    # Let's use a 2x2 pixel grid logic but scale it up
    grid1 = [random.randint(0,1) for _ in range(4)]
    grid2 = [random.randint(0,1) for _ in range(4)]
    
    def render_grid(g, px):
        s = f'<g transform="translate({px}, 20)">'
        s += f'<rect x="0" y="0" width="30" height="30" fill="{"black" if g[0] else "white"}" stroke="gray"/>'
        s += f'<rect x="30" y="0" width="30" height="30" fill="{"black" if g[1] else "white"}" stroke="gray"/>'
        s += f'<rect x="0" y="30" width="30" height="30" fill="{"black" if g[2] else "white"}" stroke="gray"/>'
        s += f'<rect x="30" y="30" width="30" height="30" fill="{"black" if g[3] else "white"}" stroke="gray"/>'
        s += '</g>'
        return s
        
    svg = f'''<svg width="250" height="100" xmlns="http://www.w3.org/2000/svg">
        {render_grid(grid1, 20)}
        <text x="95" y="55" font-size="20">+</text>
        {render_grid(grid2, 120)}
        <text x="195" y="55" font-size="20">=</text>
    </svg>'''
    
    fname = save_svg(svg)
    
    # Calculate XOR outcome
    out = [g1 ^ g2 for g1, g2 in zip(grid1, grid2)]
    def describe(g):
        c = sum(g)
        return f"A grid with {c} black square(s)"
        
    ans = describe(out)
    
    # Avoid duplicate description choices
    opts = [ans]
    while len(opts) < 4:
        cand = describe([random.randint(0,1) for _ in range(4)])
        if cand not in opts:
            opts.append(cand)
            
    q_txt = f"If the two transparent patterns are overlaid, and overlapping black regions cancel out (Black XOR Black = White, White XOR White = White, Black XOR White = Black), what will the resulting grid look like?<br><img src='images/{fname}' style='max-width:100%;'>"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

print(f"Adding {len(questions)} distinct cognitive questions to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    f.write("Question;Option A;Option B;Option C;Option D;Answer,,,,,,,,\n")
    for q in questions:
        f.write(q + "\n")

print("Done generating cognitive visuals.")
