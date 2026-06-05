import os
import random
import uuid

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\logical_reasoning"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "logical_reasoning.csv")

questions = []

def add_q(text, a, b, c, d, ans):
    text = text.replace(";", ",")
    questions.append(f"{text};{a};{b};{c};{d};{ans},,,,,,,,")

def save_svg(svg_content):
    filename = f"vis_{uuid.uuid4().hex[:8]}.svg"
    filepath = os.path.join(IMAGES_DIR, filename)
    with open(filepath, "w", encoding='utf-8') as f:
        f.write(svg_content)
    return filename

# 8. Series completion (figures)
for _ in range(20):
    svg = f'''<svg width="500" height="200" xmlns="http://www.w3.org/2000/svg">
       <text x="10" y="20">Which figure completes the series?</text>
       
       <!-- Series -->
       <rect x="10" y="40" width="60" height="60" fill="none" stroke="black" />
       <circle cx="40" cy="70" r="10" fill="black" />
       
       <rect x="90" y="40" width="60" height="60" fill="none" stroke="black" />
       <circle cx="120" cy="70" r="15" fill="black" />
       
       <rect x="170" y="40" width="60" height="60" fill="none" stroke="black" />
       <circle cx="200" cy="70" r="20" fill="black" />
       
       <rect x="250" y="40" width="60" height="60" fill="none" stroke="black" stroke-dasharray="4" />
       <text x="275" y="75">?</text>
       
       <!-- Options -->
       <text x="10" y="140">A.</text>
       <rect x="30" y="120" width="40" height="40" fill="none" stroke="black" />
       <circle cx="50" cy="140" r="25" fill="black" />
       
       <text x="100" y="140">B.</text>
       <rect x="120" y="120" width="40" height="40" fill="none" stroke="black" />
       <circle cx="140" cy="140" r="5" fill="black" />
       
       <text x="190" y="140">C.</text>
       <rect x="210" y="120" width="40" height="40" fill="none" stroke="black" />
       <rect x="220" y="130" width="20" height="20" fill="black" />
       
       <text x="280" y="140">D.</text>
       <rect x="300" y="120" width="40" height="40" fill="none" stroke="black" />
       <circle cx="320" cy="140" r="15" fill="white" stroke="black" />
    </svg>'''
    fname = save_svg(svg)
    q_txt = f"Find the figure that logically completes the series.<br><img src='images/{fname}' style='max-width:100%; border: 1px solid #ccc; margin-top:10px;'>"
    add_q(q_txt, "A", "B", "C", "D", "A")

# 9. Pattern recognition
for _ in range(20):
    svg = f'''<svg width="400" height="250" xmlns="http://www.w3.org/2000/svg">
       <text x="10" y="20">Find the missing tile in the pattern.</text>
       
       <!-- 2x2 Grid -->
       <rect x="50" y="40" width="50" height="50" fill="black" stroke="black" />
       <rect x="100" y="40" width="50" height="50" fill="none" stroke="black" />
       <rect x="50" y="90" width="50" height="50" fill="none" stroke="black" />
       <rect x="100" y="90" width="50" height="50" fill="none" stroke="black" stroke-dasharray="2" />
       <text x="120" y="120">?</text>
       
       <!-- Options -->
       <rect x="10" y="170" width="40" height="40" fill="black" />
       <text x="25" y="230">A</text>
       
       <rect x="80" y="170" width="40" height="40" fill="gray" />
       <text x="95" y="230">B</text>
       
       <rect x="150" y="170" width="40" height="40" fill="white" stroke="black" />
       <line x1="150" y1="170" x2="190" y2="210" stroke="black" />
       <text x="165" y="230">C</text>
       
       <rect x="220" y="170" width="40" height="40" fill="white" stroke="black" />
       <text x="235" y="230">D</text>
    </svg>'''
    fname = save_svg(svg)
    q_txt = f"Which tile completes the 2x2 grid?<br><img src='images/{fname}' style='max-width:100%; border: 1px solid #ccc; margin-top:10px;'>"
    add_q(q_txt, "A", "B", "C", "D", "D")

# 10. Embedded figures
for _ in range(20):
    svg = f'''<svg width="400" height="200" xmlns="http://www.w3.org/2000/svg">
       <text x="10" y="20">Which complex figure hides the target shape?</text>
       
       <!-- Target -->
       <text x="10" y="50">Target:</text>
       <polyline points="20,70 50,70 50,100" fill="none" stroke="black" stroke-width="4" />
       
       <!-- Options -->
       <text x="120" y="50">A</text>
       <rect x="110" y="60" width="40" height="40" fill="none" stroke="black" />
       <line x1="110" y1="60" x2="150" y2="100" stroke="black" />
       
       <text x="180" y="50">B</text>
       <rect x="170" y="60" width="40" height="40" fill="none" stroke="black" />
       <polyline points="170,80 190,80 190,100" fill="none" stroke="black" stroke-width="4" />
       
       <text x="240" y="50">C</text>
       <circle cx="250" cy="80" r="20" fill="none" stroke="black" />
       
       <text x="300" y="50">D</text>
       <polygon points="310,100 330,60 350,100" fill="none" stroke="black" />
    </svg>'''
    fname = save_svg(svg)
    q_txt = f"Find the option that contains the simple target shape embedded inside it.<br><img src='images/{fname}' style='max-width:100%; border: 1px solid #ccc; margin-top:10px;'>"
    add_q(q_txt, "A", "B", "C", "D", "B")

# 11. Water Images
for _ in range(20):
    word = random.choice(["ROAD", "BIRD", "FISH", "DOCK", "HIKE", "BOOK"])
    svg = f'''<svg width="400" height="200" xmlns="http://www.w3.org/2000/svg">
       <text x="10" y="20">Find the water image (upside down) of: {word}</text>
       <text x="30" y="60" font-family="monospace" font-size="40" fill="black">{word}</text>
       <line x1="10" y1="70" x2="150" y2="70" stroke="blue" stroke-dasharray="4" stroke-width="2" />
       
       <text x="10" y="110">A.</text>
       <g transform="translate(30, 100) scale(1, -1)">
         <text x="0" y="0" font-family="monospace" font-size="30" fill="black">{word}</text>
       </g>
       
       <text x="140" y="110">B. {word[::-1]}</text>
       <text x="240" y="110">C. {word}</text>
    </svg>'''
    fname = save_svg(svg)
    q_txt = f"What is the correct water image of the given item?<br><img src='images/{fname}' style='max-width:100%; border: 1px solid #ccc; margin-top:10px;'>"
    add_q(q_txt, "A", "B", "C", "D", "A")

# Write to CSV
with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print(f"Generated {len(questions)} additional logical reasoning visual questions.")
