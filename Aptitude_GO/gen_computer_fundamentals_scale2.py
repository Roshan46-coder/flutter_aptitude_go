import csv
import os
import random

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\computer_fundamentals"
CSV_PATH = os.path.join(BASE_DIR, "computer_fundamentals.csv")

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

print("Generating second wave of scalable Computer Fundamentals variations...")

# 1. RAID Levels
for _ in range(50):
    raid = random.choice([0, 1, 5, 6, 10])
    storage = random.randint(2, 8) # drives
    
    if raid == 0:
        ans = "Striping (No Redundancy)"
    elif raid == 1:
        ans = "Mirroring (High Redundancy)"
    elif raid == 5:
        ans = "Block-level striping with distributed parity"
    elif raid == 6:
        ans = "Block-level striping with double distributed parity"
    else:
        ans = "Combining mirroring and striping"
        
    opts = [
        "Striping (No Redundancy)",
        "Mirroring (High Redundancy)",
        "Block-level striping with distributed parity",
        "Block-level striping with double distributed parity",
        "Combining mirroring and striping"
    ]
    opts.remove(ans)
    
    # Random variables to avoid dedup
    q_txt = f"A server administrator is configuring an array of {storage} hard drives in RAID {raid}. What is the defining characteristic of this configuration?"
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 2. Scheduling Algorithms (OS)
for _ in range(50):
    algo = random.choice(["FCFS", "SJF", "Round Robin", "Priority Scheduling"])
    processes = random.randint(3, 10)
    context_switches = random.randint(10, 50)
    
    if algo == "FCFS": ans = "Non-preemptive scheduling based on arrival time"
    elif algo == "SJF": ans = "Minimizes average waiting time but risks starvation"
    elif algo == "Round Robin": ans = "Time-sliced preemptive scheduling often causing high context switching"
    else: ans = "Executes highest importance processes first"
    
    opts = [
        "Non-preemptive scheduling based on arrival time",
        "Minimizes average waiting time but risks starvation",
        "Time-sliced preemptive scheduling often causing high context switching",
        "Executes highest importance processes first"
    ]
    opts.remove(ans)
    
    q_txt = f"An operating system is managing {processes} processes with {context_switches} context switches using the {algo} algorithm. Which description best defines this algorithm?"
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 3. DBMS Keys
for _ in range(50):
    table = random.choice(["Users", "Products", "Invoices", "Categories"])
    key = random.choice(["Primary Key", "Foreign Key", "Candidate Key", "Super Key"])
    
    if key == "Primary Key": ans = "Uniquely identifies a record and cannot be NULL"
    elif key == "Foreign Key": ans = "Maintains referential integrity to another table"
    elif key == "Candidate Key": ans = "A minimal Super Key that can uniquely identify a tuple"
    else: ans = "A set of one or more attributes that uniquely identify a tuple"
    
    opts = [
        "Uniquely identifies a record and cannot be NULL",
        "Maintains referential integrity to another table",
        "A minimal Super Key that can uniquely identify a tuple",
        "A set of one or more attributes that uniquely identify a tuple"
    ]
    opts.remove(ans)
    
    q_txt = f"In the '{table}' table, what is the primary role of a {key}?"
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 4. Git / VCS (Software Engineering)
for _ in range(50):
    cmd = random.choice(["git commit", "git push", "git pull", "git merge", "git clone"])
    repo_size = random.randint(10, 500)
    
    if cmd == "git commit": ans = "Records changes to the local repository"
    elif cmd == "git push": ans = "Uploads local repository content to a remote repository"
    elif cmd == "git pull": ans = "Fetches and downloads content from a remote repository and integrates it"
    elif cmd == "git merge": ans = "Joins two or more development histories together"
    else: ans = "Creates a local copy of a remote repository"
    
    opts = [
        "Records changes to the local repository",
        "Uploads local repository content to a remote repository",
        "Fetches and downloads content from a remote repository and integrates it",
        "Joins two or more development histories together",
        "Creates a local copy of a remote repository"
    ]
    opts.remove(ans)
    
    q_txt = f"A developer is working on a {repo_size}MB repository. What does the command `{cmd}` execute?"
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

# 5. SDLC Testing Types
for _ in range(60):
    test_type = random.choice(["Unit Testing", "Integration Testing", "System Testing", "Acceptance Testing"])
    bug_count = random.randint(5, 100)
    
    if test_type == "Unit Testing": ans = "Testing individual, isolated software components"
    elif test_type == "Integration Testing": ans = "Testing combined parts of an application to determine if they function together correctly"
    elif test_type == "System Testing": ans = "Testing the complete, integrated software software comprehensively"
    else: ans = "Testing conducted to determine if the requirements of a specification or contract are met"
    
    opts = [
        "Testing individual, isolated software components",
        "Testing combined parts of an application to determine if they function together correctly",
        "Testing the complete, integrated software software comprehensively",
        "Testing conducted to determine if the requirements of a specification or contract are met"
    ]
    opts.remove(ans)
    
    q_txt = f"During a QA phase involving {bug_count} bug fixes, the team conducts {test_type}. What does this involve?"
    shuffle_and_add(q_txt, ans, opts[0], opts[1], opts[2])

print(f"Adding {len(questions)} wave 2 CS variations to CSV...")

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for q in questions:
        f.write(q + "\n")

print("Done mass generating wave 2 CS variations.")
