import os
import csv
import random
import uuid

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\logical_reasoning"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "logical_reasoning.csv")

if not os.path.exists(IMAGES_DIR):
    os.makedirs(IMAGES_DIR)

questions = []

# --- Helper to add questions ---
def add_q(text, a, b, c, d, ans):
    # Sanitize and replace semicolons in text to avoid breaking CSV
    text = text.replace(";", ",")
    questions.append(f"{text};{a};{b};{c};{d};{ans},,,,,,,,")

# ==========================================
# TEXT-BASED CATEGORIES
# ==========================================

# 1. Seating Arrangements
names = ["A", "B", "C", "D", "E", "F", "P", "Q", "R", "S", "T"]
for _ in range(30):
    k = random.sample(names, 5)
    q_txt = f"Five friends {k[0]}, {k[1]}, {k[2]}, {k[3]}, and {k[4]} are sitting in a row facing North. {k[1]} is immediately to the left of {k[2]}. {k[0]} is at one of the ends and is immediately next to {k[3]}. {k[4]} is to the right of {k[2]}. Who is sitting exactly in the middle?"
    # Order: [0], [3], [1], [2], [4] -> 0 is end, next is 3. 1 is left of 2. 4 is right of 2.
    # A D B C E -> middle is B (which is k[1])
    opts = [k[1], k[2], k[3], k[4]]
    random.shuffle(opts)
    ans_idx = opts.index(k[1])
    ans_char = chr(65 + ans_idx)
    add_q(q_txt, opts[0], opts[1], opts[2], opts[3], ans_char)

# 2. Blood Relations
for _ in range(30):
    p1 = random.choice(["A", "P", "M", "K", "R"])
    p2 = random.choice(["B", "Q", "N", "L", "S"])
    q_txt = f"Pointing to a photograph of a man, {p1} said, 'His mother's only daughter is my mother.' How is {p1} related to the man in the photograph?"
    # Man's mother's only daughter = Man's sister. Man's sister is P1's mother.
    # Therefore, the man is P1's mother's brother, i.e., maternal uncle.
    # P1 is the nephew or niece. If P1 is a boy, nephew. Assume P1 is a generic person.
    opts = ["Nephew or Niece", "Uncle", "Cousin", "Brother"]
    random.shuffle(opts)
    ans_idx = opts.index("Nephew or Niece")
    add_q(q_txt, opts[0], opts[1], opts[2], opts[3], chr(65 + ans_idx))

# 3. Direction Sense
for _ in range(30):
    v1 = random.randint(10, 50)
    v2 = random.randint(10, 50)
    q_txt = f"A person starts from their home and walks {v1} m towards North. Then they turn right and walk {v2} m. Finally, they turn right again and walk {v1} m. How far and in which direction are they from their starting point?"
    ans_val = f"{v2} m East"
    opts = [ans_val, f"{v2} m West", f"{v1+v2} m North", f"{v1} m South"]
    random.shuffle(opts)
    ans_idx = opts.index(ans_val)
    add_q(q_txt, opts[0], opts[1], opts[2], opts[3], chr(65 + ans_idx))

# 4. Puzzles
for _ in range(30):
    t = random.randint(1, 12)
    bells = [2, 4, 6, 8, 10, 12]
    q_txt = f"Six bells commence tolling together and toll at intervals of 2, 4, 6, 8, 10 and 12 seconds respectively. In {t} hours, how many times do they toll together?"
    # LCM of 2,4,6,8,10,12 is 120 seconds = 2 minutes.
    # In 't' hours = t * 60 minutes.
    # t * 60 / 2 = 30 * t.
    # Plus the one at the start = 30*t + 1.
    ans_val = str(30*t + 1)
    opts = [ans_val, str(30*t), str(60*t), str(15*t + 1)]
    random.shuffle(opts)
    add_q(q_txt, opts[0], opts[1], opts[2], opts[3], chr(65 + opts.index(ans_val)))

# 5. Syllogisms
for _ in range(20):
    t1 = random.choice(["cats", "dogs", "trees", "cars"])
    t2 = random.choice(["animals", "mammals", "plants", "vehicles"])
    t3 = random.choice(["cute", "fast", "green", "expensive"])
    q_txt = f"Statements: All {t1} are {t2}. Some {t2} are {t3}.<br>Conclusions:<br>I. Some {t1} are {t3}.<br>II. Some {t3} are {t2}."
    opts = ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows"]
    ans_val = "Only II follows"
    add_q(q_txt, opts[0], opts[1], opts[2], opts[3], "B")

# 6. Order & ranking
for _ in range(30):
    n = random.randint(30, 80)
    r = random.randint(10, n-5)
    name = random.choice(["Rohan", "Sita", "Ali", "John", "Meera"])
    q_txt = f"In a class of {n} students, {name}'s rank is {r}th from the top. What is {name}'s rank from the bottom?"
    ans_val = str(n - r + 1)
    opts = [ans_val, str(n - r), str(n - r + 2), str(n - r - 1)]
    random.shuffle(opts)
    add_q(q_txt, opts[0], opts[1], opts[2], opts[3], chr(65 + opts.index(ans_val)))

# ==========================================
# VISUAL CATEGORIES (SVGs)
# ==========================================

def save_svg(svg_content):
    filename = f"vis_{uuid.uuid4().hex[:8]}.svg"
    filepath = os.path.join(IMAGES_DIR, filename)
    with open(filepath, "w", encoding='utf-8') as f:
        f.write(svg_content)
    return filename

# 7. Mirror Images
for _ in range(20):
    word = random.choice(["LOGIC", "MAGIC", "IMAGE", "WATER", "SOLVE", "BRAIN", "THINK"])
    # We will just make a question asking what the mirror image is.
    # Since mirror image of text can't easily be typed in standard CSV without unicode hacks,
    # we'll generate an SVG with the actual mirror image.
    svg_base = f'''<svg width="300" height="150" xmlns="http://www.w3.org/2000/svg">
      <text x="10" y="50" font-family="monospace" font-size="30" fill="gray">Original: {word}</text>
      <text x="10" y="100" font-family="monospace" font-size="30" fill="black">A. <tspan transform="scale(-1, 1)" fill="black">-{word}</tspan></text>
      <text x="150" y="100" font-family="monospace" font-size="30" fill="black">B. {word[::-1]}</text>
    </svg>'''
    # Wait, SVG transform on tspan doesn't work easily text-by-text without proper grouping.
    # Let's simplify and just do geometric mirror images.
    
    # Let's draw a simple shape that points left or right.
    dir_origin = random.choice(["right", "left"])
    points = "10,20 40,20 40,10 60,30 40,50 40,40 10,40" if dir_origin == "right" else "60,20 30,20 30,10 10,30 30,50 30,40 60,40"
    
    # Mirror will be opposite.
    svg = f'''<svg width="400" height="200" xmlns="http://www.w3.org/2000/svg">
       <!-- Original -->
       <text x="10" y="20">Find the mirror image of the shape:</text>
       <polygon points="{points}" fill="#4f46e5" transform="translate(10, 30)" />
       <line x1="90" y1="30" x2="90" y2="90" stroke="black" stroke-dasharray="4" />
       
       <!-- Options -->
       <text x="10" y="130">A.</text>
       <polygon points="10,20 40,20 40,10 60,30 40,50 40,40 10,40" fill="#4f46e5" transform="translate(30, 110)" />
       
       <text x="120" y="130">B.</text>
       <polygon points="60,20 30,20 30,10 10,30 30,50 30,40 60,40" fill="#4f46e5" transform="translate(140, 110)" />
       
       <text x="230" y="130">C.</text>
       <polygon points="10,20 40,20 40,10 60,30 40,50 40,40 10,40" fill="#4f46e5" transform="translate(250, 110) rotate(180, 35, 30)" />
       
       <text x="340" y="130">D.</text>
       <polygon points="60,20 30,20 30,10 10,30 30,50 30,40 60,40" fill="#4f46e5" transform="translate(360, 110) rotate(180, 35, 30)" />
    </svg>'''
    
    fname = save_svg(svg)
    ans = "B" if dir_origin == "right" else "A"
    q_txt = f"What is the correct mirror image of the given figure (with the mirror placed on the right dotted line)?<br><img src='images/{fname}' style='max-width:100%; border: 1px solid #ccc; margin-top:10px;'>"
    add_q(q_txt, "A", "B", "C", "D", ans)

# Write to CSV
with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print(f"Generated {len(questions)} logical reasoning questions with images where applicable.")
