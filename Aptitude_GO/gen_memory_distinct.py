import os
import csv
import random
import hashlib
import string

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\memory_and_attention"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "memory_and_attention.csv")

if not os.path.exists(IMAGES_DIR):
    os.makedirs(IMAGES_DIR)

questions = []

def save_svg(svg_content):
    h = hashlib.md5(svg_content.encode('utf-8')).hexdigest()[:10]
    filename = f"mem_{h}.svg"
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

print("Generating Memory & Attention - Part 1 (Target ~250)...")

# 1. N-Back Tasks
for _ in range(80):
    n_back = random.randint(2, 4)
    length = random.randint(7, 10)
    # Generate a random sequence of letters
    seq = [random.choice(string.ascii_uppercase) for _ in range(length)]
    
    # Force an N-back match sometimes
    if random.choice([True, False]):
        match_idx = random.randint(n_back, length-1)
        seq[match_idx] = seq[match_idx - n_back]
        
    matches = 0
    for i in range(n_back, length):
        if seq[i] == seq[i-n_back]:
            matches += 1
            
    seq_str = " - ".join(seq)
    
    ans = str(matches)
    opts = [ans]
    while len(opts) < 4:
        cand = str(random.randint(0, 5))
        if cand not in opts: opts.append(cand)
        
    q_txt = f"In a {n_back}-Back task, the user must identify when the current item matches the item {n_back} steps prior. Evaluate the following sequence: <b>{seq_str}</b>. How many valid {n_back}-back matches occur?"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

# 2. Sequence Recall (Reverse/Sorted)
for _ in range(80):
    length = random.randint(5, 7)
    seq = [random.randint(10, 99) for _ in range(length)]
    seq_str = ", ".join(map(str, seq))
    
    action = random.choice(["reversed", "sorted in ascending order", "sorted in descending order"])
    
    if action == "reversed":
        correct_arr = list(reversed(seq))
    elif action == "sorted in ascending order":
        correct_arr = sorted(seq)
    else:
        correct_arr = sorted(seq, reverse=True)
        
    ans = ", ".join(map(str, correct_arr))
    opts = [ans]
    
    while len(opts) < 4:
        # Create subtle dummy variations
        dummy = correct_arr[:]
        # Swap two elements to make it "almost" right
        idx1, idx2 = random.sample(range(length), 2)
        dummy[idx1], dummy[idx2] = dummy[idx2], dummy[idx1]
        cand = ", ".join(map(str, dummy))
        if cand not in opts: opts.append(cand)
        
    q_txt = f"Memorize this sequence: <b>{seq_str}</b>. If you were to recall this sequence exactly <i>{action}</i>, which of the following is correct?"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])

# 3. Attention to Detail: String Matching
for _ in range(90):
    # Base string to focus on
    chars = ['O', '0', 'l', '1', 'I']
    base_chars = [random.choice(chars) for _ in range(6)]
    base_str = "".join(base_chars)
    
    # We create 3 identical and 1 anomaly
    strings = [base_str, base_str, base_str, base_str]
    
    # Pick anomaly index
    anomaly_idx = random.randint(0, 3)
    anomaly_chr_idx = random.randint(0, 5)
    
    # Change the character to something visually similar
    orig = base_chars[anomaly_chr_idx]
    if orig == 'O': new_c = '0'
    elif orig == '0': new_c = 'O'
    elif orig == '1': new_c = 'l'
    elif orig == 'l': new_c = 'I'
    else: new_c = '1'
    
    fake_list = list(base_str)
    fake_list[anomaly_chr_idx] = new_c
    fake_str = "".join(fake_list)
    
    # Ensure they are actually different
    if fake_str == base_str:
        fake_str = base_str + " "
        
    strings[anomaly_idx] = fake_str
    
    # Which option contains the anomaly? 
    # Actually wait. Standard multiple choice asks "Which of these is NOT identical?"
    
    ans = fake_str
    
    # If the multiple choice list just has 3 identical strings and 1 anomaly, it's obvious the anomaly is the answer.
    # To truly test attention, we ask "Which of the following matches the target EXACTLY?"
    
    ans = base_str
    d1 = fake_str
    
    # Create two more fakes
    f2_list = list(base_str)
    f2_list[random.randint(0, 5)] = random.choice(chars)
    d2 = "".join(f2_list)
    
    f3_list = list(base_str)
    f3_list[random.randint(0, 5)] = random.choice(chars)
    d3 = "".join(f3_list)
    
    # Ensure uniqueness
    opts = list(set([ans, d1, d2, d3]))
    while len(opts) < 4:
        f_list = list(base_str)
        f_list[random.randint(0, 5)] = random.choice(chars)
        cand = "".join(f_list)
        if cand not in opts: opts.append(cand)
        
    q_txt = f"Attention to detail: Find the exact match for the reference string: <b>{base_str}</b>"
    shuffle_and_add(q_txt, ans, opts[1], opts[2], opts[3])


print(f"Adding {len(questions)} distinct memory questions to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    f.write("Question;Option A;Option B;Option C;Option D;Answer,,,,,,,,\n")
    for q in questions:
        f.write(q + "\n")

print("Done generating memory distinct.")
