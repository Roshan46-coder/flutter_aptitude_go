import csv
import json
import os
import re

QUESTION_BANK = r"D:\college\5th sem first project\Aptitude_GO\question_bank"
OUTPUT = r"D:\college\5th sem first project\aptitude_go_flutter\assets\question_bank.json"

SLUG_MAP = {
    "quantitative_aptitude": "quantitative-aptitude",
    "logical_reasoning": "logical-reasoning",
    "verbal_ability": "verbal-ability",
    "computer_fundamentals": "computer-fundamentals",
    "debugging_and_code_logic": "debugging-and-code-logic",
    "memory_and_attention": "memory-and-attention",
    "cognitive_ability": "cognitive-ability",
    "programming_aptitude": "programming-logic",
    "clean_general_aptitude_dataset": "general-aptitude",
}

COMPANY_DIR_MAP = {
    "Accenture": "accenture",
    "Cognizant": "cognizant",
    "TCS": "tcs",
    "TCS - NINJA": "tcs-ninja",
    "Wipro Elite NLTH": "wipro-elite-nlth",
    "TATA ELXSI": "tata-elxsi",
}


def parse_csv(filepath):
    questions = []
    try:
        with open(filepath, "r", encoding="utf-8-sig") as f:
            reader = csv.reader(f, delimiter=";")
            next(reader, None)
            qid = 1
            for row in reader:
                if len(row) < 6:
                    continue
                q_text = row[0].strip()
                opts = [row[1].strip(), row[2].strip(), row[3].strip(), row[4].strip()]
                answer = row[5].strip().rstrip(",").strip().upper()
                if not answer or answer not in "ABCD":
                    continue
                answer_idx = ord(answer) - ord("A")
                option_list = [
                    {"id": i + 1, "text": opt}
                    for i, opt in enumerate(opts)
                ]
                questions.append({
                    "id": qid,
                    "text": q_text,
                    "is_coding": False,
                    "time_limit": 60,
                    "options": option_list,
                    "correct_index": answer_idx,
                })
                qid += 1
    except Exception as e:
        print(f"  Error reading {filepath}: {e}")
    return questions


def parse_company_coding_questions(company_dir, company_name):
    questions = []
    if not os.path.isdir(company_dir):
        return questions

    qid = 1
    for entry in sorted(os.listdir(company_dir)):
        entry_path = os.path.join(company_dir, entry)
        if not os.path.isdir(entry_path):
            continue
        problem_file = os.path.join(entry_path, "Problem Statement.txt")
        if not os.path.isfile(problem_file):
            continue
        try:
            with open(problem_file, "r", encoding="utf-8") as f:
                text = f.read().strip()
        except Exception as e:
            print(f"  Error reading {problem_file}: {e}")
            continue

        if not text:
            continue

        questions.append({
            "id": qid,
            "text": text,
            "is_coding": True,
            "time_limit": 600,
            "options": [],
            "correct_index": None,
        })
        qid += 1

    return questions


def parse_tata_elxsi_file(filepath):
    questions = []
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"  Error reading {filepath}: {e}")
        return questions

    lines = content.split("\n")
    qid = 1
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        q_match = re.match(r"^(?:Q|q)\s*(\d+)\)?\s*[.\-]?\s*(.*)", line)
        if not q_match:
            i += 1
            continue

        q_text = q_match.group(2).strip()
        if not q_text:
            q_text = q_match.group(0).strip()

        option_lines = []
        ans_line = None
        j = i + 1
        while j < len(lines):
            l = lines[j].strip()
            if re.match(r"^(?:Q|q)\s*\d+", l):
                break
            ans_match = re.search(r"Ans(?:wer)?\s*:\s*(.*)", l, re.IGNORECASE)
            if ans_match:
                ans_line = ans_match.group(1).strip()
                j += 1
                break
            if l and not l.startswith("Explanation") and not l.startswith("Your Answer"):
                option_lines.append(l)
            j += 1

        if not ans_line:
            i = j
            continue

        options = []
        correct_idx = None
        opt_idx_map = {"a": 0, "b": 1, "c": 2, "d": 3, "e": 4, "f": 5}
        ans_clean = ans_line.lower().strip()

        has_mcq_options = False
        for oline in option_lines:
            opt_match = re.match(r"^\s*([a-fA-F])[\.\)]\s*(.*)", oline)
            if opt_match:
                has_mcq_options = True
                opt_letter = opt_match.group(1).lower()
                opt_text = opt_match.group(2).strip()
                options.append({"id": len(options) + 1, "text": opt_text})
                if opt_letter in opt_idx_map:
                    letter_num = opt_idx_map[opt_letter]
                    if ans_clean == opt_letter or ans_clean == str(letter_num + 1):
                        correct_idx = len(options) - 1

        if re.search(r"option\s*(\d+)", ans_clean):
            opt_num_match = re.search(r"option\s*(\d+)", ans_clean)
            opt_num = int(opt_num_match.group(1))
            if 1 <= opt_num <= len(options):
                correct_idx = opt_num - 1
        elif re.match(r"^\d+$", ans_clean):
            num = int(ans_clean)
            if 1 <= num <= len(options):
                correct_idx = num - 1

        if not has_mcq_options:
            options = [{"id": 1, "text": ans_line}]
            correct_idx = 0

        if correct_idx is not None and correct_idx < len(options):
            questions.append({
                "id": qid,
                "text": q_text,
                "is_coding": False,
                "time_limit": 60,
                "options": options,
                "correct_index": correct_idx,
            })
            qid += 1

        i = j

    return questions


def parse_tata_elxsi(company_dir):
    questions = []
    file_map = {
        "Analytical.txt": "analytical",
        "Verbal.txt": "verbal",
        "Technical.txt": "technical",
    }
    for filename in file_map:
        filepath = os.path.join(company_dir, filename)
        if os.path.isfile(filepath):
            qs = parse_tata_elxsi_file(filepath)
            questions.extend(qs)
    return questions


def main():
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)

    all_slugs = {}

    for dirname, slug in SLUG_MAP.items():
        dirpath = os.path.join(QUESTION_BANK, dirname)
        csv_files = sorted([f for f in os.listdir(dirpath) if f.endswith(".csv")]) if os.path.isdir(dirpath) else []
        questions = []
        for cf in csv_files:
            fp = os.path.join(dirpath, cf)
            print(f"Reading {dirname}/{cf}...")
            questions.extend(parse_csv(fp))

        if questions:
            all_slugs[slug] = questions
            print(f"  -> {len(questions)} questions")

    company_dir = os.path.join(QUESTION_BANK, "company_level_question")
    if os.path.isdir(company_dir):
        for comp_name, slug in COMPANY_DIR_MAP.items():
            comp_path = os.path.join(company_dir, comp_name)
            if not os.path.isdir(comp_path):
                continue

            if comp_name == "TATA ELXSI":
                questions = parse_tata_elxsi(comp_path)
            else:
                questions = parse_company_coding_questions(comp_path, comp_name)

            if questions:
                all_slugs[slug] = questions
                print(f"  -> {slug}: {len(questions)} questions (company)")

    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(all_slugs, f, ensure_ascii=False, indent=1)

    print(f"\nDone! {sum(len(v) for v in all_slugs.values())} total questions to {OUTPUT}")


if __name__ == "__main__":
    main()
