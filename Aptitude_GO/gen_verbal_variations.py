import csv
import os
import random

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\verbal_ability"
CSV_PATH = os.path.join(BASE_DIR, "verbal_ability.csv")

questions = []

def add_q(text, a, b, c, d, ans):
    text = text.replace(";", ",")
    questions.append(f"{text};{a};{b};{c};{d};{ans},,,,,,,,")

def shuffle_and_add(text, correct, dummy1, dummy2, dummy3):
    opts = [correct, dummy1, dummy2, dummy3]
    random.shuffle(opts)
    ans_idx = opts.index(correct)
    ans_char = chr(65 + ans_idx)
    add_q(text, opts[0], opts[1], opts[2], opts[3], ans_char)

print("Generating algorithmic variations for Verbal Ability...")

# 1. Grammar Variations: Subject-Verb Agreement
subjects = [
    ("The flock of birds", "was", "were", "is", "are"),
    ("A bouquet of flowers", "was", "were", "is", "are"),
    ("The jury", "was", "were", "is", "are"),
    ("Neither the manager nor the employees", "were", "was", "is", "has"),
    ("Either the students or the teacher", "is", "are", "were", "have")
]
actions = [
    "seen flying over the lake.",
    "delivered to the hospital.",
    "undecided about the verdict.",
    "informed about the sudden policy change.",
    "responsible for the presentation."
]

for _ in range(30):
    subj_tuple = random.choice(subjects)
    subj = subj_tuple[0]
    action = random.choice(actions)
    q_txt = f"Fill in the blank with the correct verb: {subj} ______ {action}"
    
    # Simple logic for this generated set:
    if "Neither" in subj:
        correct = subj_tuple[1] # "were" (agrees with employees)
        d1, d2, d3 = subj_tuple[2], subj_tuple[3], subj_tuple[4]
    elif "Either" in subj:
        correct = subj_tuple[1] # "is" (agrees with teacher)
        d1, d2, d3 = subj_tuple[2], subj_tuple[3], subj_tuple[4]
    else: 
        correct = subj_tuple[1] # "was" (collective noun singular)
        d1, d2, d3 = subj_tuple[2], subj_tuple[3], subj_tuple[4]
        
    shuffle_and_add(q_txt, correct, d1, d2, d3)


# 2. Vocabulary Logic: Analogies
# We can dynamically pair synonymous / antonymous pairs
pairs = [
    ("HAPPY", "JOYFUL", "SAD", "SORROWFUL"),
    ("BRAVE", "COURAGEOUS", "COWARDLY", "FEARFUL"),
    ("FAST", "QUICK", "SLOW", "SLUGGISH"),
    ("WEALTHY", "RICH", "POOR", "DESTITUTE"),
    ("BRIGHT", "LUMINOUS", "DARK", "DIM")
]

for _ in range(40):
    p1 = random.choice(pairs)
    p2 = random.choice(pairs)
    while p1 == p2:
        p2 = random.choice(pairs)
        
    mode = random.choice(["synonym", "antonym"])
    if mode == "synonym":
        q_txt = f"Analogy: {p1[0]} : {p1[1]} :: {p2[0]} : ?"
        correct = p2[1]
        dummies = [p2[2], p2[3], p1[2], p1[3]]
    else:
        q_txt = f"Analogy: {p1[0]} : {p1[2]} :: {p2[0]} : ?"
        correct = p2[2]
        dummies = [p2[1], p2[3], p1[1]]
        
    d1, d2, d3 = random.sample(list(set(dummies)), 3)
    shuffle_and_add(q_txt, correct, d1, d2, d3)


# 3. Sentence Jumbles (Permutations)
sentences = [
    ("The scientist", "conducted an experiment", "in the laboratory", "to test the hypothesis."),
    ("The young boy", "quickly ran across the street", "to catch the bus", "before it departed."),
    ("The diligent student", "studied late into the night", "for the final exams", "to secure top grades."),
    ("The experienced surgeon", "performed a complex operation", "at the city hospital", "saving the patient's life.")
]

for _ in range(30):
    components = random.choice(sentences)
    # Target order is 0, 1, 2, 3
    # Let's label them P, Q, R, S randomly
    labels = ["P", "Q", "R", "S"]
    random.shuffle(labels)
    
    # Map component index to its new label
    mapping = {labels[i]: components[i] for i in range(4)}
    
    # The correct sequence of labels is the one that points back to 0, 1, 2, 3
    # To find correct sequence, we just find which label has components[0], components[1], etc.
    correct_seq = ""
    for i in range(4):
        correct_seq += labels[i]
        
    # Wait, the string to display
    display_str = f"Arrange correctly: P: {mapping['P']}  Q: {mapping['Q']}  R: {mapping['R']}  S: {mapping['S']}"
    
    # The correct answer is the string of labels corresponding to components[0..3]
    # e.g., if P=comp[2], Q=comp[0], R=comp[3], S=comp[1]
    # Then order 0, 1, 2, 3 -> Q, S, P, R
    ans_labels = []
    for i in range(4):
        for lbl in ["P", "Q", "R", "S"]:
            if mapping[lbl] == components[i]:
                ans_labels.append(lbl)
    correct_ans = "".join(ans_labels)
    
    # Generate 3 dummy sequences
    perms = ["PQRS", "PRQS", "RQSP", "SQPR", "QSRP", "RSQP", "SRQP", "SPQR", "QPRS", "PSQR", "QRPS"]
    random.shuffle(perms)
    dummies = []
    for p in perms:
        if p != correct_ans and len(dummies) < 3:
            dummies.append(p)
            
    shuffle_and_add(display_str, correct_ans, dummies[0], dummies[1], dummies[2])

# 4. Idioms (Fill in the missing word)
idioms = [
    ("A blessing in", "disguise", ["hiding", "cover", "secret"]),
    ("Bite the", "bullet", ["apple", "dust", "metal"]),
    ("Beat around the", "bush", ["tree", "house", "fence"]),
    ("Cut corners", "corners", ["edges", "lines", "shapes"]),
    ("Under the", "weather", ["cloud", "rain", "storm"]),
    ("Piece of", "cake", ["pie", "bread", "candy"]),
    ("Break a", "leg", ["arm", "stick", "record"])
]

for _ in range(25):
    idiom = random.choice(idioms)
    q_txt = f"Complete the idiom: '{idiom[0]} ______'"
    shuffle_and_add(q_txt, idiom[1], idiom[2][0], idiom[2][1], idiom[2][2])

print(f"Adding {len(questions)} variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done generating verbal variations.")
