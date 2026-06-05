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

# 12. Paper folding and cutting
for _ in range(20):
    svg = f'''<svg width="400" height="200" xmlns="http://www.w3.org/2000/svg">
       <text x="10" y="20">A piece of paper is folded and punched as shown.</text>
       <text x="10" y="40">How will it appear when unfolded?</text>
       
       <!-- Folding steps -->
       <rect x="10" y="60" width="40" height="40" fill="none" stroke="black" />
       <line x1="30" y1="60" x2="30" y2="100" stroke="black" stroke-dasharray="2" />
       <text x="55" y="85">→</text>
       
       <rect x="70" y="60" width="20" height="40" fill="none" stroke="black" />
       <line x1="70" y1="80" x2="90" y2="80" stroke="black" stroke-dasharray="2" />
       <text x="95" y="85">→</text>
       
       <rect x="110" y="60" width="20" height="20" fill="none" stroke="black" />
       <circle cx="120" cy="70" r="3" fill="black" />
       
       <!-- Options -->
       <text x="10" y="130">A.</text>
       <rect x="30" y="120" width="40" height="40" fill="none" stroke="black" />
       <circle cx="40" cy="130" r="3" fill="black" />
       <circle cx="60" cy="130" r="3" fill="black" />
       <circle cx="40" cy="150" r="3" fill="black" />
       <circle cx="60" cy="150" r="3" fill="black" />
       
       <text x="90" y="130">B.</text>
       <rect x="110" y="120" width="40" height="40" fill="none" stroke="black" />
       <circle cx="130" cy="140" r="6" fill="black" />
       
       <text x="170" y="130">C.</text>
       <rect x="190" y="120" width="40" height="40" fill="none" stroke="black" />
       <circle cx="200" cy="140" r="3" fill="black" />
       <circle cx="220" cy="140" r="3" fill="black" />
       
       <text x="250" y="130">D.</text>
       <rect x="270" y="120" width="40" height="40" fill="none" stroke="black" />
       <circle cx="290" cy="130" r="3" fill="black" />
       <circle cx="290" cy="150" r="3" fill="black" />
    </svg>'''
    fname = save_svg(svg)
    q_txt = f"Identify the correct unfolded pattern.<br><img src='images/{fname}' style='max-width:100%; border: 1px solid #ccc; margin-top:10px;'>"
    add_q(q_txt, "A", "B", "C", "D", "A")

# Write to CSV
with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print(f"Generated {len(questions)} additional logical reasoning visual questions.")
